#!/usr/bin/env bash
# consilium-smoke.sh · behavioural check of templates/skills/consilium/consilium.py with mock participants.
# Spends no quota and needs only python3: the harness `mock` replaces claude, codex and agy with a scripted
# participant. Run from anywhere: bash tests/consilium-smoke.sh ; prints one line per check, exits non-zero on
# the first failed one.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
C="python3 $HERE/templates/skills/consilium/consilium.py"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export CONSILIUM_MOCK="$T/mock.py" MOCK_STATE="$T/mock-state"
mkdir -p "$MOCK_STATE"
printf 'Choose a storage engine for the queue.\n' > "$T/task.md"

cat > "$T/mock.py" <<'PY'
import json, os, sys, time, uuid
name, session = sys.argv[1], sys.argv[2]
prompt = sys.stdin.read()
state = os.environ["MOCK_STATE"]
def count(key):                      # how many times this participant has been in this situation
    p = os.path.join(state, f"{name}.{key}")
    n = int(open(p).read()) + 1 if os.path.exists(p) else 1
    open(p, "w").write(str(n))
    return n
with open(os.path.join(state, "sessions.log"), "a") as f:
    f.write(f"{name} {session}\n")
time.sleep(float(os.environ.get("MOCK_SLEEP", "0")))
if name in os.environ.get("MOCK_FAIL", "").split(",") and "Stage 1, opening" not in prompt:
    sys.exit(7)
if "no VOTE line" in prompt:
    text = "VOTE: APPROVE"
elif "Operator checkpoint" in prompt:
    text = "Converging; one more circle. Request: none."
elif "closed the discussion" in prompt:
    text = f"FORCED FINAL by {name}"
elif "Stage 1, opening" in prompt:
    text = f"{name}: the task is to choose an engine. Question: durability or speed?"
elif "Short run" in prompt and "In parallel" in prompt:
    text = f"{name}: use the simple engine."
elif "Stage 2, research" in prompt:
    text = f"{name}: findings with sources."
elif "Settle the clarify stage" in prompt:
    text = "1. Durability or speed? a) durability b) speed\nDECISION: ASK"
elif "Say what you think of it" in prompt:
    n = count("vote")
    if name == os.environ.get("MOCK_OBJECTOR") and n == 2:
        text = "The answer ignores durability.\nVOTE: OBJECT"
    elif name == os.environ.get("MOCK_SILENT"):
        text = "Looks fine to me."
    else:
        text = "Agreed.\n**VOTE: APPROVE**"
elif "Your turn as the lead" in prompt:
    n = count("lead")
    if n == 1 and not os.environ.get("MOCK_FAST"):
        text = "Let us compare the options first."
    elif n == 2 and os.environ.get("MOCK_ASK_TIME"):
        text = "Still comparing.\nTO-OPERATOR: we need 10 more minutes for a benchmark"
    else:
        text = f"1. Use engine X (attempt {n}).\nIn short: X, see point 1.\nDECISION: FINAL"
else:
    text = f"{name}: I agree with the direction."
print(json.dumps({"text": text, "session": session if session != "new" else f"s-{name}-{uuid.uuid4().hex[:6]}"}))
PY

n=0
ok() { n=$((n + 1)); echo "ok $n · $1"; }
fail() { echo "FAIL · $1"; exit 1; }
has() { grep -q -- "$2" "$1" || fail "$3 (no '$2' in $1)"; }
reset() { rm -rf "$MOCK_STATE"; mkdir -p "$MOCK_STATE"; unset MOCK_FAIL MOCK_OBJECTOR MOCK_SILENT MOCK_FAST MOCK_ASK_TIME MOCK_SLEEP; }
M="--member gemini=mock:g-high --member claude=mock:c-opus:high --member gpt=mock:x-sol:high"

# 1 · full run: questions, answers, research, checkpoint, objection, second final, approval
reset; D="$T/full"; export MOCK_OBJECTOR=claude
$C start "$D" --task-file "$T/task.md" $M --checkpoint-every 1 >/dev/null
$C wait "$D" --timeout 60 > "$T/ev1"
has "$T/ev1" "event 1 · questions" "first event is the agreed questions"
has "$T/ev1" "Durability or speed" "the questions reach the operator"
ok "clarify: parallel opening, lead proposes ASK, both approve, operator gets the questions"
$C reply "$D" answer --say "durability" >/dev/null
$C wait "$D" --timeout 60 > "$T/ev2"
has "$T/ev2" "· checkpoint" "a checkpoint follows one circle of discussion"
has "$T/ev2" "Converging" "the lead's report reaches the operator"
ok "answers posted, research in parallel, one circle, lead reports at the checkpoint"
$C reply "$D" continue --say "prefer boring technology" --checkpoint-every 0 >/dev/null
$C wait "$D" --timeout 60 > "$T/ev3"
has "$T/ev3" "· final" "the run ends with the final event"
has "$T/ev3" "approved by claude, gpt" "both others approved"
has "$D/final.md" "attempt 3" "the objected final was replaced by a later one"
grep -q "DECISION" "$D/final.md" && fail "control lines leak into final.md"
ok "objection voids the first final, the next one is approved by both and written to final.md"
[ "$(sort "$MOCK_STATE/sessions.log" | grep -c ' new$')" = 3 ] || fail "each participant must start exactly one session"
ok "one session per participant for the whole consilium ($(wc -l < "$MOCK_STATE/sessions.log" | tr -d ' ') turns, 3 sessions)"
ls "$D/space" | sed -n 1,3p | grep -q "^0001-" || fail "space files are not numbered from 0001"
V=$(grep -l "Say what you think of it" "$D"/turns/*-claude.prompt.md | head -1)
has "$V" "DECISION: ASK -----" "a voter is shown the proposal it votes on"
grep -q "claude: the task is" "$V" && fail "a participant is shown its own message again"
has "$V" "gpt: the task is" "a participant is shown what the others wrote meanwhile"
P=$(grep -l "prefer boring technology" "$D"/turns/*.prompt.md | wc -l | tr -d ' ')
[ "$P" = 3 ] || fail "the operator's message must reach each participant exactly once, got $P"
ok "delta: own messages are not repeated, others' and the operator's arrive once, in order"
[ "$(grep -l "The task, as given by the operator" "$D"/turns/*.prompt.md | wc -l | tr -d ' ')" = 3 ] || fail "the brief is sent once per session"
ok "the rules and the task are sent once, in the first turn of each session"

# 2 · quick run with two participants, a reply without VOTE is repaired
reset; D="$T/quick"; export MOCK_FAST=1 MOCK_SILENT=claude
$C start "$D" --task-file "$T/task.md" --member gpt=mock:x --member claude=mock:c --quick --foreground > "$T/q"
has "$T/q" "· final" "a quick run finishes in one go"
has "$T/q" "approved by claude" "the missing vote was asked for again"
[ "$(ls "$D/space" | wc -l | tr -d ' ')" = 4 ] || fail "quick run: 2 openings, the final, 1 vote"
ok "quick run: two participants, four messages, missing VOTE line repaired by one extra call"

# 3 · a participant that keeps failing leaves, the rest finish; the operator is told
reset; D="$T/drop"; export MOCK_FAIL=gpt MOCK_FAST=1
$C start "$D" --task-file "$T/task.md" $M --foreground > "$T/d1"
has "$T/d1" "questions" "the consilium goes on without the failed participant"
has "$T/d1" 'notice: Participant "gpt" left' "the operator is told who left"
$C reply "$D" answer --say "speed" --foreground > "$T/d2"
has "$T/d2" "approved by claude" "two remaining participants reach the final"
ok "a participant failing twice is dropped, noted in the space and in the next event"

# 4 · the lead fails: the next in order becomes the lead; one left: collapsed, operator finalizes
reset; D="$T/lead"; export MOCK_FAIL=gemini,gpt
$C start "$D" --task-file "$T/task.md" $M --foreground > "$T/l1"
has "$T/l1" "· collapsed" "one participant left is reported as collapsed"
has "$T/l1" "participants: claude (lead)" "the lead role passed on"
$C reply "$D" finalize --foreground > "$T/l2"
has "$T/l2" "FORCED FINAL by claude" "the remaining participant writes the answer"
ok "lead role passes to the next participant; a collapsed consilium is finalized by the operator"

# 5 · deadline, extension, a request of the lead, hurry, forced final
reset; D="$T/time"; export MOCK_ASK_TIME=1
$C start "$D" --task-file "$T/task.md" $M --quick --total-min 1 --checkpoint-every 0 --foreground > "$T/t1"
has "$T/t1" "· deadline" "no turn starts without working time"
$C reply "$D" continue --foreground > "$T/t2" 2>&1 && fail "continue after a deadline must require --extend"
$C reply "$D" continue --extend 30 --foreground > "$T/t2"
has "$T/t2" "· request" "a TO-OPERATOR line stops the run with a request"
has "$T/t2" "10 more minutes" "the request text reaches the operator"
$C reply "$D" hurry --foreground > "$T/t3"
has "$T/t3" "· final" "after hurry the lead finishes"
has "$(grep -l "asked to hurry" "$D"/turns/*.prompt.md | head -1)" "converge now" "participants are told to hurry"
ok "deadline stops the run, --extend resumes it, the lead's request and the operator's hurry are delivered"
reset; D="$T/forced"
$C start "$D" --task-file "$T/task.md" $M --checkpoint-every 1 --foreground > /dev/null
$C reply "$D" answer --say "x" --foreground > /dev/null
$C reply "$D" finalize --foreground > "$T/f"
has "$T/f" "without an approval round" "finalize ends the discussion without votes"
ok "finalize at a checkpoint: the lead writes the final answer without an approval round"

# 6 · detached driver: say while it works, then abort kills the running turn
reset; D="$T/abort"; export MOCK_SLEEP=3
$C start "$D" --task-file "$T/task.md" $M >/dev/null
sleep 1
$C wait "$D" --timeout 1 > "$T/a0" && fail "wait must exit 2 while the consilium works" || [ $? = 2 ] || fail "wait exit code"
$C reply "$D" say --say "note from the operator" | grep -q accepted || fail "say while running is queued"
$C reply "$D" abort > "$T/a1"
has "$T/a1" "· aborted" "abort is confirmed with an event"
sleep 1
pgrep -f "$T/mock.py" >/dev/null && fail "abort left a participant process running"
$C status "$D" | grep -q "driver: not running" || fail "status after abort"
ok "detached driver: wait times out with code 2, abort kills the running turns"

echo "all $n checks passed"
