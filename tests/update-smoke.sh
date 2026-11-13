#!/usr/bin/env bash
# update-smoke.sh · behavioural check of `artel update`: a user project whose artel/ follows the releases of its
# origin. Needs only git and python3 and no network: the origin is a local repository built from this working
# tree, and releases are tags created by the test. Where PyYAML is missing, tests/lib-no-pyyaml/ supplies a
# stand-in (the test config is JSON, which is YAML).
# Run from anywhere: bash tests/update-smoke.sh ; prints one line per check, exits non-zero on the first failure.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
python3 -c "import yaml" 2>/dev/null || export PYTHONPATH="$HERE/tests/lib-no-pyyaml${PYTHONPATH:+:$PYTHONPATH}"
unset ARTEL_AD ARTEL_AGENT ARTEL_HOME || true
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
O="$T/origin"; P="$T/proj"; AD="$P/agents"

n=0
ok() { n=$((n + 1)); echo "ok $n · $1"; }
fail() { echo "FAIL · $1"; exit 1; }
has() { case "$1" in *"$2"*) ;; *) fail "$3: expected '$2' in: $1" ;; esac; }
hasnt() { case "$1" in *"$2"*) fail "$3: unexpected '$2' in: $1" ;; esac; }
G() { git -c user.name=test -c user.email=test@localhost -c protocol.file.allow=always "$@"; }
A() { (cd "$P" && python3 "$P/artel/bin/artel" "$@"); }
at() { git -C "$P/artel" rev-parse HEAD; }
tagc() { git -C "$O" rev-parse "$1^{commit}"; }
state() { python3 -c "import json,sys; d=json.load(open('$AD/state/artel-update.json')); print(eval(sys.argv[1]))" "$1"; }
# release <tag> <changelog line>: commit whatever is staged or changed in the origin and tag it as a release
release() {
  printf '%s\n' "# Changelog" "" "## $1 · 2026-01-01" "- $2" "" "$(sed 1,2d "$O/CHANGELOG.md")" > "$O/CHANGELOG.md.new"
  mv "$O/CHANGELOG.md.new" "$O/CHANGELOG.md"
  G -C "$O" add -A && G -C "$O" commit -q -m "release $1" && G -C "$O" tag -a "$1" -m "$1"
}
config() { cat > "$AD/config.yaml" <<JSON
{"artel": {"project": "mock", "update": $1, "git": {"autocommit": false}},
 "slots": {"main": {"dir": "$P", "window": "10m", "hard_limit": "20m"}},
 "agents": {"super": {"harness": "claude", "model": "haiku", "slot": "main", "schedule": {"at": "00:00"}, "prompt": "iteration"},
            "builder": {"harness": "codex", "model": "gpt-5.6-luna", "slot": "main", "schedule": {"at": "03:00"}}}}
JSON
}

# The origin: this working tree as release v0.1.0, then one unreleased commit on main.
mkdir "$O" && G init -q -b main "$O"
cp -R "$HERE/bin" "$HERE/templates" "$HERE/charter.md" "$HERE/.gitignore" "$O/"
printf '%s\n' "# Changelog" "" > "$O/CHANGELOG.md"
release v0.1.0 "First release FIRST-MARK."
echo "work after the release" > "$O/notes.md" && G -C "$O" add -A && G -C "$O" commit -q -m "unreleased work"

# 1 · installation: a fresh clone sits on main, ahead of the release; the installer puts it at the latest release
mkdir "$P" && G clone -q "$O" "$P/artel"
[ "$(at)" != "$(tagc v0.1.0)" ] || fail "the fresh clone must start ahead of the release"
OUT=$(A update --apply --to release)
[ "$(at)" = "$(tagc v0.1.0)" ] || fail "a fresh clone is put at the latest release: $OUT"
has "$OUT" "-> v0.1.0" "install line"
OUT=$(A init --project mock)
has "$(cat "$AD/config.yaml")" "update: release" "the new project follows releases"
ok "installation: a fresh clone is moved from the default branch to the latest release, the new config follows releases"

# 2 · an origin without release tags leaves the clone where it is
mkdir "$T/bare" && G init -q -b main "$T/bare" && cp -R "$HERE/bin" "$T/bare/" && G -C "$T/bare" add -A && G -C "$T/bare" commit -q -m one
G clone -q "$T/bare" "$T/untagged"
H=$(git -C "$T/untagged" rev-parse HEAD)
OUT=$(cd "$T" && python3 "$T/untagged/bin/artel" update --apply --to release)
has "$OUT" "no release tags" "origin without releases"
[ "$(git -C "$T/untagged" rev-parse HEAD)" = "$H" ] || fail "a clone of an origin without releases must not move"
ok "an origin without release tags: the clone stays on its default branch"

# The project: a JSON config and one identity compiled from two library modules at v0.1.0.
config '"release"'
printf '%s\n' "---" "name: builder" "sources: [artel/worker, roles/developer]" "artel: $(git -C "$P/artel" rev-parse --short HEAD)" \
  "compiled: 2026-01-02" "---" "You build." > "$AD/agent-builder.md"
SKILL_BEFORE=$(cat "$P/skills/super/SKILL.md")

# 3 · nothing new: main being ahead of the release is not an update for a project that follows releases
OUT=$(A update)
has "$OUT" "artel v0.1.0" "installed release"
has "$OUT" "up to date" "check without a new release"
ok "check: a project on the latest release is up to date although origin/main is ahead"

# 4 · a new release is reported and changes nothing
echo "Extra worker rule." >> "$O/templates/prompts/artel/worker.md"
echo "Extra super rule." >> "$O/templates/skills/super/SKILL.md"
release v0.2.0 "Worker protocol and the super skill gained a rule SECOND-MARK."
OUT=$(A update)
has "$OUT" "update available: v0.2.0" "check with a new release"
[ "$(at)" = "$(tagc v0.1.0)" ] || fail "a check must not move artel/"
[ "$(state "d['available']['ref']")" = v0.2.0 ] || fail "the available release is recorded in state/artel-update.json"
ok "check: a new release at origin is reported and recorded, artel/ stays where it was"

# 5 · apply: artel/ moves, the report says what changed and what it touches here, the project itself is untouched
OUT=$(A update --apply)
[ "$(at)" = "$(tagc v0.2.0)" ] || fail "apply moves artel/ to the new release"
has "$OUT" "v0.1.0" "report header"; has "$OUT" "-> v0.2.0" "report header"; has "$OUT" "review pending" "report header"
has "$OUT" "SECOND-MARK" "release notes of the new release"
hasnt "$OUT" "FIRST-MARK" "release notes of the release already installed"
has "$OUT" "prompt library: artel/worker (+1 -0)" "changed module"
has "$OUT" "skill templates: templates/skills/super/SKILL.md (+1 -0)" "changed skill template"
has "$OUT" "builder: compiled at" "identity whose source changed"; has "$OUT" "changed: artel/worker" "identity whose source changed"
has "$OUT" "super/SKILL.md: untouched copy of an old template; will be updated" "skill copy that differs from the template"
[ "$(cat "$P/skills/super/SKILL.md")" = "$SKILL_BEFORE" ] || fail "apply must not touch skills/"
[ "$(state "d['review']")" = pending ] || fail "the review is pending after apply"
has "$(cat "$AD/journal.md")" "artel-update" "journal entry"
ok "apply: artel/ at v0.2.0, report with release notes, changed module, stale identity and skill copy; skills/ and agents/ untouched"

# 6 · the review stays open across runs until it is closed with the decisions taken
OUT=$(A update)
has "$OUT" "up to date" "check after apply"; has "$OUT" "review pending" "pending review is repeated"; has "$OUT" "SECOND-MARK" "pending review is repeated"
A update --done "" >/dev/null 2>&1 && fail "closing a review needs the decisions"
A update --done "adopted the worker rule; declined the super rule: this project edited that section" >/dev/null
has "$(cat "$AD/journal.md")" "declined the super rule" "the decision is in the journal"
OUT=$(A update)
hasnt "$OUT" "review pending" "closed review"
A update --done "again" >/dev/null 2>&1 && fail "there is no review to close twice"
ok "review: repeated by every check until --done records the decisions in the journal"

# 7 · a release whose command does not start is rolled back and not retried by itself
printf '%s\n' '#!/usr/bin/env python3' 'raise SystemExit(7)' > "$O/bin/artel"
release v0.3.0 "Broken command."
A update --apply >/dev/null 2>&1 && fail "a release that fails its self-check must fail the update"
[ "$(at)" = "$(tagc v0.2.0)" ] || fail "a failed update is rolled back"
has "$(cat "$AD/journal.md")" "failed its self-check" "journal entry of the failed update"
OUT=$(A update)
has "$OUT" "blocked: v0.3.0 failed its self-check" "the failed release is not offered again"
A update --apply >/dev/null 2>&1 && fail "a failed release is not retried without --to"
G -C "$O" checkout -q v0.2.0 -- bin/artel
release v0.3.1 "Command fixed THIRD-MARK."
OUT=$(A update --apply)
[ "$(at)" = "$(tagc v0.3.1)" ] || fail "the next release is applied after a failed one"
has "$OUT" "v0.2.0" "review range starts at the reviewed release"; has "$OUT" "THIRD-MARK" "notes of the fixed release"
ok "self-check: a release with a broken command is rolled back, recorded, skipped; the next release applies"

# 8 · local changes in artel/ are never overwritten; an unreviewed update stays inside the next review
echo "More." >> "$O/charter.md"
release v0.4.0 "Charter changed FOURTH-MARK."
echo "local edit" >> "$P/artel/charter.md"
OUT=$(A update --apply 2>&1) && fail "uncommitted changes must block the update"
has "$OUT" "uncommitted changes (charter.md)" "reason for the refusal"
G -C "$P/artel" commit -q -am "local change"
LOCAL=$(at)
OUT=$(A update --apply 2>&1) && fail "local commits must block the update"
has "$OUT" "1 local commit" "reason for the refusal"
[ "$(at)" = "$LOCAL" ] || fail "a refused update must not move artel/"
G -C "$P/artel" checkout -q --detach v0.3.1
OUT=$(A update --apply)
[ "$(at)" = "$(tagc v0.4.0)" ] || fail "the update applies once the local commit is gone"
has "$OUT" "v0.2.0" "the unreviewed update is still in the range"; has "$OUT" "THIRD-MARK" "notes of both releases"; has "$OUT" "FOURTH-MARK" "notes of both releases"
has "$OUT" "charter: charter.md" "charter area"
A update --done "nothing to adopt" >/dev/null
ok "local changes and local commits in artel/ block the update with a reason; two unreviewed releases are reviewed together"

# 9 · the user's choice in config.yaml: off, a pinned version, a branch
config 'false'
OUT=$(A update)
has "$OUT" "updates are off" "artel.update: off"
A update --apply >/dev/null 2>&1 && fail "apply without a target must fail when updates are off"
A update --apply --to v0.1.0 >/dev/null
[ "$(at)" = "$(tagc v0.1.0)" ] || fail "--to pins an older release on request"
A update --done "pinned on request" >/dev/null
config '"branch:main"'
OUT=$(A update)
has "$OUT" "follows branch main" "artel.update: branch:main"; has "$OUT" "update available: origin/main" "branch head"
A update --apply >/dev/null
[ "$(at)" = "$(git -C "$O" rev-parse main)" ] || fail "a project that follows a branch is moved to its head"
config '"sometimes"'
A update >/dev/null 2>&1 && fail "an unknown artel.update value is a configuration error"
ok "config: off stops updates, --to pins a version on request, branch:<name> follows a branch, an unknown value is an error"

echo "all $n checks passed"
