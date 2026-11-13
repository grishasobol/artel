# Changelog

Release notes of artel, written for the super agent of a running project. `artel update --apply` prints the
sections between the release a project had and the one it moved to. Every line says what changed and, after
"In a running project:", what such a project may want to do about it. Nothing here is an order: a project adopts
what suits its goal and its own tuning, and records the decision with `artel update --done`.

## Unreleased

## v0.1.0 · 2026-11-13

- First tagged release: from here on `artel/` in a user project sits at a release (a tag `vMAJOR.MINOR.PATCH`) and
  `artel update` keeps it there. `artel update` reports the installed and the available release, `--apply` moves
  `artel/` with a self-check and a rollback and prints a review report, `--done "<decisions>"` closes the review;
  `artel.update` in `agents/config.yaml` selects `release` (default), `branch:<name>` or `off`.
  In a running project: an installation made before this release has `artel/` on a branch and updated it with
  `git pull`; its first `artel update --apply` moves it to the release. Its `skills/super/SKILL.md` predates the
  section "Artel releases": `artel skills --apply` refreshes an untouched copy, an edited copy needs that section
  and the changed "Collection" item merged by hand. `artel.update` may be added to `config.yaml`; without it the
  project follows releases.
- The super skill states that everything artel lays out is a default the user may change, and that a user's
  decision recorded in `goal.md` or `rules.md` outranks the skill, the prompt library and release notes.
  In a running project: move decisions the user made in conversation into `rules.md` as dated quotes, so later
  updates are judged against them.
- `artel run` appends one record per run to `agents/state/runs.jsonl`: outcome (`advanced`, `noop`, `blocked`,
  `failed`, `killed`), plan steps touched, tokens normalised across harnesses, spend per model including
  sub-agents. Module `artel/config`, section "Run records".
  In a running project: nothing to change; the file is there to answer which agents and tasks spend quota
  without advancing a step.
- Resuming a Codex session (`session: continue`) no longer fails: `codex exec resume` rejects `-C`, and the flag
  is not passed on a resumed run.
  In a running project: a Codex agent with `session: continue` that failed on every second run can be resumed
  with `artel run <agent> --force`.
- Every Claude process started by `artel run`, by the consilium driver and by the commands in `harness/claude`
  gets `--strict-mcp-config`, so account-level MCP connectors no longer add tens of thousands of tokens to each
  request.
  In a running project: identities or scripts that start `claude -p` themselves should pass the flag too; an
  agent that relies on an account connector needs it configured explicitly.
- The `consilium` skill is an operator-run discussion: a driver script (`skills/consilium/consilium.py`) runs the
  participants, and the convener pays for events instead of the whole discussion. Module `procedures/consilium`.
  In a running project: `artel skills --apply` installs the driver next to the skill; an identity that quotes the
  old consilium procedure needs recompiling.
