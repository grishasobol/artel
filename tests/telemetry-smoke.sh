#!/usr/bin/env bash
# telemetry-smoke.sh · behavioural check of run telemetry in bin/artel: what `artel run` reads from a harness log
# and writes to agents/state/runs.jsonl. Spends no quota and needs only python3: saved logs from
# tests/fixtures/runs/ stand in for the harnesses, and a stub command stands in for an agent's work. Where PyYAML
# is missing, tests/lib-no-pyyaml/ supplies a stand-in (the test config is JSON, which is YAML).
# Run from anywhere: bash tests/telemetry-smoke.sh ; prints one line per check, exits non-zero on the first failure.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
FX="$HERE/tests/fixtures/runs"
python3 -c "import yaml" 2>/dev/null || export PYTHONPATH="$HERE/tests/lib-no-pyyaml${PYTHONPATH:+:$PYTHONPATH}"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
AD="$T/proj/agents"
export ARTEL_AD="$AD"
A="$HERE/bin/artel"
mkdir -p "$AD/planning" "$AD/state"
for a in cx worker idle silent broken hung; do
  mkdir -p "$AD/team/$a"
  : > "$AD/team/$a/SUMMARY.md"
done
printf -- '- [ ] 01-02 · worker · build the index\n- [ ] 03-02 · worker · migrate the schema\n' > "$AD/team/cx/PLAN.md"
printf -- '- [ ] 01-02 · worker · build the index\n' > "$AD/planning/ROADMAP.md"

# The stub harness: prints a saved log, then behaves as the agent of the given scenario.
cat > "$T/stub.sh" <<'SH'
#!/usr/bin/env bash
set -eu
case "$1" in
  blocked) cat "$FX/codex.log"; artel summary add --status blocked "03-02 waits for the schema owner" >/dev/null ;;
  advance) cat "$FX/codex-resume.log"
           sed -i.bak 's/- \[ \] 01-02/- [x] 01-02/' "$ARTEL_AD/team/cx/PLAN.md" && rm -f "$ARTEL_AD/team/cx/PLAN.md.bak"
           artel summary add --status done "Index built." >/dev/null ;;
  worked)  cat "$FX/agy.log"; artel summary add --status partial "Half of the import is done." >/dev/null ;;
  nowork)  cat "$FX/claude.log"; artel summary add --status done "No work for this role." >/dev/null ;;
  silent)  echo "nothing a parser knows" ;;
  broken)  cat "$FX/opencode.log"; exit 3 ;;
  hung)    sleep 60 ;;
esac
SH
export FX

cat > "$AD/config.yaml" <<JSON
{"artel": {"project": "mock", "git": {"autocommit": false}},
 "agents": {
  "cl":     {"harness": "claude", "model": "haiku", "effort": "low"},
  "ag":     {"harness": "agy", "model": "gemini-3.8-flash-low"},
  "oc":     {"harness": "opencode", "model": "opencode/glm-5.3-flash-free"},
  "cxdry":  {"harness": "codex", "model": "gpt-5.6-luna", "effort": "low"},
  "cx":     {"harness": "codex", "model": "gpt-5.6-luna", "effort": "low", "session": "continue",
             "tasks": {"first": {"env": {"MODE": "blocked"}}, "second": {"env": {"MODE": "advance"}}},
             "cmd": "bash $T/stub.sh \$MODE"},
  "worker": {"harness": "agy", "model": "gemini-3.8-flash-low", "cmd": "bash $T/stub.sh worked"},
  "idle":   {"harness": "claude", "model": "haiku", "cmd": "bash $T/stub.sh nowork"},
  "silent": {"harness": "codex", "cmd": "bash $T/stub.sh silent"},
  "broken": {"harness": "opencode", "model": "opencode/glm-5.3-flash-free", "cmd": "bash $T/stub.sh broken"},
  "hung":   {"harness": "claude", "model": "haiku", "window": "1s", "hard_limit": "2s", "cmd": "bash $T/stub.sh hung"}
 }}
JSON

n=0
ok() { n=$((n + 1)); echo "ok $n · $1"; }
fail() { echo "FAIL · $1"; exit 1; }
# expect <json line> <python expression over r> <message>
expect() { printf '%s' "$1" | python3 -c "
import json, sys
r = json.loads(sys.stdin.read())
sys.exit(0 if ($2) else 1)" || fail "$3: $1"; }
replay() { "$A" run "$1" --dry-run --replay-log "$FX/$2" | tail -1; }
last() { tail -1 "$AD/state/runs.jsonl"; }

# 1 · the four harness logs are read into the same fields
R=$(replay cl claude.log)
expect "$R" "(r['input'], r['cache_read'], r['cache_write'], r['output']) == (4, 37104, 14490, 102)" "claude tokens"
expect "$R" "r['cost'] == 0.00332 and r['turns'] == 2 and r['session'].endswith('0001') and r['model'] == 'haiku'" "claude cost, turns, session"
ok "claude: input, cache read, cache write, output, cost, turns and session from the result line"
R=$(replay cxdry codex.log)
expect "$R" "(r['input'], r['cache_read'], r['output']) == (3585, 23680, 134)" "codex: cached tokens are taken out of input"
expect "$R" "r['thread'] == {'input': 3585, 'cache_read': 23680, 'cache_write': 0, 'output': 134} and r['cost'] is None" "codex thread totals"
ok "codex: cached input separated from fresh input, session totals kept in the record"
R=$(replay ag agy.log)
expect "$R" "(r['input'], r['cache_read'], r['output'], r['turns']) == (13695, 14630, 173, 1) and r['session'].endswith('0004')" "agy"
ok "agy: input already excludes cache reads"
R=$(replay oc opencode.log)
expect "$R" "(r['input'], r['cache_read'], r['cache_write'], r['output']) == (9500, 15000, 200, 55)" "opencode steps are summed"
expect "$R" "r['cost'] == 0.002 and r['turns'] == 2 and r['session'] == 'ses_0000000000000001'" "opencode cost and session"
ok "opencode (synthetic log): steps summed, reasoning counted as output"

# 2 · spend by model: a sub-agent is invisible in claude's top-level usage and present in the record
R=$(replay cl claude-subagent.log)
expect "$R" "sorted(r['models']) == ['claude-haiku-5-5', 'claude-sonnet-5-5']" "two models"
expect "$R" "r['models']['claude-sonnet-5-5'] == {'input': 2, 'cache_read': 0, 'cache_write': 18236, 'output': 3, 'cost': 0.045624}" "sub-agent model"
expect "$R" "(r['input'], r['cache_write'], r['output']) == (6, 33129, 288) and r['cost'] == 0.049116" "totals include the sub-agent"
ok "claude sub-agent: record totals cover both models, each model has its own entry"

# 3 · a real run through cmd_run: blocked outcome, step id from the SUMMARY entry
OUT=$("$A" run cx --task first)
R=$(last)
expect "$R" "r['outcome'] == 'blocked' and r['status'] == 'blocked' and r['steps'] == ['03-02'] and r['rc'] == 0" "blocked run"
expect "$R" "r['agent'] == 'cx' and r['task'] == 'first' and r['harness'] == 'codex' and r['effort'] == 'low'" "who ran"
expect "$R" "r['input'] == 3585 and r['log'].startswith('state/logs/cx/') and 'ts' in r and r['duration_sec'] >= 0" "tokens and log path"
case "$OUT" in *"blocked · tokens 3585 in + 23680 cached, 134 out"*) ;; *) fail "the run line names outcome and tokens: $OUT" ;; esac
ok "run: outcome blocked and the step come from the agent's SUMMARY entry, tokens from the log"

# 4 · the next run resumes the codex session: its record holds the difference, and the changed step mark
"$A" run cx --task second >/dev/null
R=$(last)
expect "$R" "(r['input'], r['cache_read'], r['output']) == (493, 27136, 130)" "resumed codex run is the difference to the previous record"
expect "$R" "r['thread']['cache_read'] == 50816 and 'usage_scope' not in r" "session totals move forward"
expect "$R" "r['outcome'] == 'advanced' and r['steps'] == ['01-02'] and r['status'] == 'done'" "changed step mark"
ok "resumed codex session: tokens of this run only; a step mark changed in PLAN.md is recorded as touched"

# 5 · outcomes without a blocked or failed status
"$A" run worker >/dev/null; expect "$(last)" "r['outcome'] == 'advanced' and r['status'] == 'partial' and r['steps'] == []" "partial work"
"$A" run idle >/dev/null;   expect "$(last)" "r['outcome'] == 'noop' and r['status'] == 'done' and r['input'] == 4" "no work"
"$A" run silent >/dev/null; expect "$(last)" "r['outcome'] == 'noop' and r['status'] is None and r['input'] is None and r['models'] is None" "no trace"
ok "outcomes: partial is advanced, a 'no work' entry and a run without any trace are noop"

# 6 · failed and killed runs are recorded too
"$A" run broken >/dev/null 2>&1 && fail "a harness exit code must fail the run"
expect "$(last)" "r['outcome'] == 'failed' and r['rc'] == 3 and r['output'] == 55" "failed run keeps its spend"
"$A" run hung >/dev/null 2>&1 && fail "a run over its hard limit must fail"
expect "$(last)" "r['outcome'] == 'killed' and 'hard limit' in r['kill_reason'] and r['input'] is None" "killed run"
ok "a failed run keeps its spend, a run killed at the hard limit is recorded as killed"

# 7 · the JSONL writer and reader, and the live claude reader when no result arrives
python3 - "$A" "$T" <<'PY'
import importlib.machinery, importlib.util, json, subprocess, sys
ldr = importlib.machinery.SourceFileLoader("artel_cli", sys.argv[1])
artel = importlib.util.module_from_spec(importlib.util.spec_from_loader("artel_cli", ldr))
ldr.exec_module(artel)
from pathlib import Path
p = Path(sys.argv[2]) / "concurrent.jsonl"
code = ("import importlib.machinery, importlib.util, sys\n"
        "l = importlib.machinery.SourceFileLoader('a', sys.argv[1])\n"
        "m = importlib.util.module_from_spec(importlib.util.spec_from_loader('a', l)); l.exec_module(m)\n"
        "from pathlib import Path\n"
        "[m.jsonl_append(Path(sys.argv[2]), {'w': sys.argv[3], 'i': i, 'pad': 'x' * 3000}) for i in range(10)]\n")
procs = [subprocess.Popen([sys.executable, "-c", code, sys.argv[1], str(p), str(w)]) for w in range(10)]
assert all(q.wait() == 0 for q in procs)
with open(p, "a") as f:
    f.write('{"truncated": tr')
recs = artel.jsonl_read(p)
assert len(recs) == 100 and len({(r["w"], r["i"]) for r in recs}) == 100, len(recs)

class Stub:   # ClaudeLive without a process: only what summary() needs
    results, session_id = [], "s-1"
    requests = {"m1": ("claude-haiku-5-5", {"input_tokens": 2, "cache_read_input_tokens": 100, "cache_creation_input_tokens": 30, "output_tokens": 5}),
                "m2": ("claude-haiku-5-5", {"input_tokens": 2, "cache_read_input_tokens": 130, "output_tokens": 7})}
s = artel.ClaudeLive.summary(Stub())
u = artel.run_usage("claude", json.dumps(s))
assert (u["input"], u["cache_read"], u["cache_write"], u["output"], u["partial"]) == (4, 230, 30, 12, True), u
PY
ok "JSONL: 100 records from 10 concurrent writers and a truncated line read back as 100; a claude run killed before its result reports partial usage"

[ "$(wc -l < "$AD/state/runs.jsonl" | tr -d ' ')" = 7 ] || fail "one record per run: expected 7"
echo "all $n checks passed"
