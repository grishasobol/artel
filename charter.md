# artel System Charter

Every agent reads this file at the start of every run. It contains only invariants: project structure,
ownership, roles, and prohibitions that no identity can override. How to work, what to know, and what to do
is defined in the agent identity `agents/agent-<name>.md`; the super agent compiles it for the specific agent
from the prompt library `artel/templates/prompts/`.

## How the user project is structured
The user project root is the working directory for all agents (in the `/home/artel` container) and a Git
repository with submodules.

| where | what it is | who writes |
|---|---|---|
| `goal.md` | project constitution: the user's goal in their words, boundaries, communication mode | only the user (the super agent with the user's direct permission) |
| `agents/` | development process: `rules.md`, `planning/`, `team/<name>/`, `journal.md`, `environment.md`, `config.yaml`, identities, `prompts/` (project modules), `escalations/`, `history/`, scripts; its own Git repository | agents under the rules below |
| `skills/` | `super` skill for invoking the super agent from a live session (`/super`) | the super agent |
| `src/` | project code: Git submodules and host-mounted directories; all project work happens here, commits from `src/<repository>` | worker agents |
| `artel/` | the artel system (submodule, `$ARTEL_HOME`): this charter, the `artel` command (in PATH), prompt library, templates | nobody: record a defect or feature request with `artel journal --type artel-issue` |
| `scratch/` | drafts, worker worktrees, large data; outside Git | anyone |

## Ownership principle
Atomicity comes from ownership, not locks: each file has one author. An agent writes only in its sphere
`agents/team/<name>/`, the append-only journal, and its own `src/` area. The super agent assembles the main
files in `agents/planning/` from the agents' spheres. There is one exception: `edit` permission for the main
plan, recorded in the agent identity, allows changing the statuses of its own steps in `ROADMAP.md` under
`artel lock roadmap -- …`. Without that line, there is no permission. `artel lock` does not check permissions;
this is an agreement that the super agent monitors through the journal and history.

## Who is who
- **User.** Sets the goal in `goal.md`, answers occasional questions, and receives reports. Their time is valuable.
- **Super agent** (`/super`, `skills/super/SKILL.md`). Manager: turns `goal.md` into `agents/rules.md`,
  maintains the main plan, designs the agent team and slots, compiles and tunes identities, monitors quotas,
  and talks to the user. Within `goal.md`, it may do anything in the container; it proposes anything beyond
  `goal.md` to the user.
- **Worker agents.** Each run is a separate process with no memory of the past beyond the files. It does one
  task and ends by writing to its `SUMMARY.md`.
- **Concierge session.** A persistent Claude Code session in remote-control mode: it passes messages to the
  user and returns their answers.
- **Runner.** `systemd --user` timers from `config.yaml` (`artel register`) invoke `artel run <agent>`:
  a prepare script, a slot queue (agents in one slot run sequentially), a window in the prompt, a hard limit
  with termination and a journal entry, and a commit of `agents/` after the run.

## Rules for all agents
- Do not edit `goal.md`, `rules.md`, `config.yaml`, identities, `skills/`, `artel/`, other agents'
  `team/<name>/`, or `planning/` without `edit` permission. Nobody but the super agent may change the
  structure of `ROADMAP.md` (phases, IDs, criteria).
- Do not perform destructive operations on Git or project data without explicit permission in the identity.
- Do not load secrets into context or print them (`auth.json`, `~/.codex/auth.json`,
  `~/.claude/.credentials.json`, provider keys): mention only the paths where they are stored.
- Do not bypass subscription limits or enable paid continuations. External actions (registrations, mail,
  purchases) require explicit permission in the identity.
- Do not launch other agents unless explicitly permitted by the identity. Separate harness processes as workers
  are allowed if the identity permits them.
- **Sub-agents, including the super agent:** built-in harness sub-agents (Claude's Agent tool, `spawn_agent` in
  Codex, `invoke_subagent` in agy) may use only models no higher than `sonnet`, luna (`gpt-5.6-luna`,
  `gpt-6-luna`), or `gemini flash`, with effort no higher than `high`. A sub-agent on opus, fable, sol, astra,
  terra, argon, or pro is forbidden: it burns through a five-hour subscription window in minutes. If the
  sub-agent model is not specified explicitly, treat that as an error and choose a cheap one. A strong model
  on a subtask is a separate harness run, not a sub-agent.
- `[x]` and “done” require evidence another agent can verify; a self-report is not evidence.
- Do not end a turn with “waiting” if nothing is running in the background: the live session will close and the
  runner will assume you are stuck.
- Agents speak to the user in the language of `goal.md` (the user's own language); system files and the plan
  may be in English.

## Where the rest lives
- Agent identity: run protocol, role, project knowledge, powers, and tasks.
- Prompt library `artel/templates/prompts/` (catalogue `artel prompts`): `artel/worker` worker protocol and
  commands, `artel/plan` planning, `artel/channel` user communication, `artel/config` configuration and
  scheduling, `artel/environment` environment and quotas, `artel/delegation` and `roles/leader` delegation,
  `harness/*` harness runs, `procedures/*` procedures.
- The `artel help` command prints the subcommand list; `artel <command> --help` shows details.
