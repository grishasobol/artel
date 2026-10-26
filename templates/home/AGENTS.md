# User project {{PROJECT}} (artel system)

This is the user project root and the `artel` user's home directory in the container. The artel agent team works
here: `artel run` starts agents on schedule, and the user and super agent can open a live session for any harness
(claude, codex, agy, opencode). All four harnesses read this file: Claude sees it as `CLAUDE.md`, while codex and
opencode see it as `AGENTS.md` (symlinks are created by `artel link`).

## What is where
- `goal.md` contains the project goal in the user's words. Do not edit it without their direct permission.
- `agents/` contains the development process: `rules.md` (the super agent's interpretation of the goal),
  `planning/` (ROADMAP, STATE, SUMMARY, VERIFICATION), `team/<name>/` (each agent's sphere), `journal.md`,
  `environment.md`, `config.yaml`, agent identities `agent-<name>.md`, project prompt modules `prompts/`,
  `escalations/`, `history/`, and work-management scripts. Its own Git repository.
- `skills/` contains the `super` skill for invoking the super agent (`/super [message]`), linked into all harnesses.
- `src/` contains project code: submodules and host-mounted directories. All project work happens here; commits
  to project repositories are made only from here.
- `artel/` is the artel system (submodule): charter `artel/charter.md`, `artel` command (`artel/bin`, in PATH),
  prompt library `artel/templates/prompts/` (catalogue: `artel prompts`), and templates. Do not edit it; record
  defects and feature requests with `artel journal --type artel-issue`.
- `scratch/` contains drafts and large data; it is outside Git.

## Rules for any session here
- Before working, read `artel/charter.md` (the short charter) and `agents/rules.md`.
- Work on the project only in `src/`. Manage plans, journal, and state only in `agents/` through the `artel`
  command (`artel help`). Do not touch other agents' spheres in `agents/team/<name>/`.
- Harness sub-agents may use only cheap models (sonnet, codex luna, gemini flash) with effort no higher than high.
  A strong model on a subtask is a separate harness run (the prompt library's `harness/*` modules).
- Do not bypass subscription limits. Do not perform destructive operations on project data without permission.
- Super agent: `/super` (`skills/super/SKILL.md` skill). The first run (started by the installer) fills
  `agents/rules.md`, the plan, the agent team, and the schedule; each later run is one management iteration.
  `artel cheatsheet` prints one screen of commands for managing this project.
