# artel

A system for long-lived teams of LLM agents. The user describes a goal, the installer builds a container,
and from then on a super agent runs the project on its own: it writes the plan, assembles a team of agents,
runs them on a schedule, watches subscription quotas and reports back to the user. The charter every agent
reads is `charter.md`; the work plan of this repository is `todo.md`.

The name is the Russian word *артель* (pronounced ar-TEL): a self-governing crew of workers that takes a
contract on agreed terms, divides the work among themselves and answers for it through an elder. Here the elder
is the super agent, the contract is `goal.md`, and the agreed terms are your subscription limits.

## The idea
Work that takes weeks, or has no end at all, cannot be done in one chat session. artel splits it into two phases.

**Phase 0.** The installer starts the super agent's first run in the container. The super agent turns the goal
into testable rules, writes a roadmap with a detailed near horizon, studies the environment (which harnesses
and models are available, their quotas and limits) and designs a team: not sub-agents of one session, but
separate scheduled runs of a harness, each with its own identity, sphere of the plan and timer. The super
agent is a member of that team itself: it schedules its own management iteration.

**Phase 1.** Worker agents wake up by timer, take tasks from their part of the plan, do them, record evidence
and deviations, and hand off. Every few hours the super agent wakes up, reads what changed (plans, summaries,
quotas, failures, escalations, the environment) and corrects what needs correcting: identities, the team,
the schedule, the plan, the distribution of work across subscriptions. Questions only a human can answer go
to the user through a channel. The user becomes a rare but important participant.

## Terms
- **User project.** Everything that belongs to one user goal: the container `artel-<name>` and its home
  directory `/home/artel` with `goal.md`, `agents/`, `skills/`, `src/`, `artel/`, `scratch/`. One user
  project, one container.
- **Harness.** The agent program that executes a prompt: `claude` (Claude Code), `codex` (OpenAI Codex CLI),
  `agy` (Google Antigravity CLI), `opencode`. artel supports all four both as the installer's harness and as
  agents inside the container.
- **Super agent.** The `/super` skill: the manager of the agent team. Worker agents are separate harness runs
  on a schedule, not sub-agents.
- **Identity.** `agents/agent-<name>.md`: the single prompt of a worker agent, distilled by the super agent from
  the prompt library and project knowledge. The run prompt only names the task.
- **Concierge session.** A permanent Claude Code session in remote-control mode inside the container: the
  channel between the agents and the user.

## What it looks like for the user
1. Clone this repository on a Linux machine that stays on.
2. Open your harness (any of the four) in the clone and call `/artel-create`. The installer asks about the
   goal, the code, the limits and the subscriptions in quiz mode, installs Incus if needed, builds the image,
   creates the container, transfers harness credentials (without reading your keys) and writes `goal.md` in
   your own words.
3. The installer starts the super agent's first run inside: it writes `agents/rules.md` and the plan,
   assembles the team and enables the schedule. The installation ends with a working container and a
   one-screen cheat sheet of how to manage it (`artel cheatsheet`). Every step is a default the user can change,
   including installing from inside a container they created themselves (`docs/install.md`, section 8).
4. From then on the agents work by themselves. The user gets reports and questions through the concierge
   session or Telegram, and can enter the container at any time, read `agents/planning/STATE.md` or call
   `/super` by hand.

The installer's instruction: `docs/install.md` (part 1 installation, part 2 what the super agent does).

## Layout of a user project (`/home/artel` by default)
```
goal.md         the project's constitution: the goal in the user's words. Only the user changes it
AGENTS.md       introduction for any live harness session (CLAUDE.md is a symlink to it)
agents/         the development process, its own git repository: rules.md (the goal decoded by the super
                agent), planning/ (ROADMAP, STATE, SUMMARY, VERIFICATION), team/<agent>/ (agent spheres),
                journal.md, environment.md, config.yaml, identities agent-<name>.md, prompts/ (project
                modules), escalations/, history/, scripts
skills/         the super skill (/super from a live session); symlinked into the skill directories of all
                harnesses (.claude, .codex, .agents, .gemini/config, .config/opencode, .opencode)
src/            the project's code: git submodules and directories mounted from the host. All work happens here
artel/          this repository as a submodule: charter, the artel command (in PATH), templates, prompt library
scratch/        drafts, outside git
```
The root and `agents/` are git repositories without a remote: the history of every run is committed
automatically (`artel run`), container snapshots cover the rest. Nothing from `agents/` ends up in the
project's own repositories under `src/`.

## Structure of this repository
```
README.md, charter.md, todo.md        overview, the agents' charter, the work plan of artel itself
.agents/skills/artel-create/          the installer skill; .claude/.codex/.opencode/skills link to it
docs/install.md                       installer instruction (quiz) and a description of the super agent
docs/harness-auth-guide.md            how to log the four harnesses in automatically inside the container
docs/channel.md, docs/research/       the file protocol with the concierge session; a survey of comparable systems
bin/artel                             the CLI (python3 + PyYAML): init, link, run, register, quota, notify, ask, …
install/provision-base.sh             the artel-base image (inside: install/inside/provision.sh)
install/artel-up.sh                   the project container: mounts, GPU, noVNC, artel clone, artel init
install/auth-transfer.sh              credential transfer into the container (codex/opencode/agy from the host,
                                      Claude only by a token from auth.json; keys are never read)
install/apply-auth.sh                 login setup inside the container from auth.json
templates/home/                       the root of a user project: AGENTS.md, goal.md, README, gitignore
templates/agents/                     contents of agents/: planning/, journal, environment, config, concierge
templates/skills/                     the super skill that artel init puts into the project's skills/
templates/prompts/                    the prompt library for the super agent (artel/, roles/, harness/,
                                      procedures/), read in place
templates/sphere/, agent-prompt.md    the sphere of a new agent and the identity skeleton (artel team init)
templates/rules.md                    the agents/rules.md template the super agent fills in during phase 0
templates/auth.json                   an example credentials file for auth-transfer.sh --auth-file
```

## The `artel` command
Lives in `artel/bin` of the submodule and is in the container's PATH. `artel help` prints the list; the main
ones: `init` (project layout), `link` (skill symlinks into every harness), `prompts` (prompt library catalog,
module text, provenance status of identities), `run <agent> [--task name]` (a run through a slot with a window
and a hard limit), `schedule` (slots and their load, agents with tasks and timers in one table), `register
--apply` (systemd --user timers from `config.yaml` plus the quota cache timer), `quota` (a snapshot of the
quotas of the four harnesses: from a cache younger than 10 minutes, or a full poll with `--fresh` taking up
to a minute), `notify` and `ask` (contact with the user), `team`, `summary`, `journal`, `lock`, `snapshot`,
`commit`, `env`.

Running an agent: `artel run <agent> [--task name]` reads `agents/config.yaml`, runs the prepare script, takes
the slot, substitutes the window, the budget and the task name into the prompt, starts the harness, kills it
at the hard limit with a journal entry, and after completion commits `agents/` and the root (under an
inter-process lock). The content of the work lives in the identity `agents/agent-<name>.md`. An agent may have
several tasks with different schedules (`tasks:`), each with its own timer `artel-<project>-<agent>.<task>`.

A slot is a lane of parallelism: agents of one slot run strictly one after another, agents of different slots
run concurrently. A timer firing on a busy slot queues up (by default for up to 4 hours) and starts seconds
after the holder exits, however long it ran; a repeated firing of the same run is coalesced. When an agent
finishes before its window ends, the next one in the queue takes the slot at once. A failure of `super` or a
failure at harness login goes to the user channel immediately; a worker agent is paused after three failures
in a row until `artel run <agent> --force` (counters in `agents/state/failures.json`). Harness login variables
from `~/.config/artel/auth.env` (written by `apply-auth.sh`) are passed to children.

## Updating
Inside the container: `git -C /home/artel/artel pull`. The command, the charter and the templates update at
once; a run in progress picks the new code up at its next `artel` call. Files in `agents/` and `skills/`
created at installation belong to the project: a repeated `artel init` overwrites nothing and only adds what
is missing. `artel skills --apply` refreshes the copy of the `super` skill if nobody edited it (the previous
version goes to `agents/history/`), removes copies of skills that no longer exist in the templates, and
leaves an edited copy alone with a diff command. The prompt library `artel/templates/prompts/` is read in
place and updates with the submodule; `artel prompts status` shows which identities have changed sources.
`artel env` shows the running commit.

## Status
The core (slot and timer runs, super agent iterations, the concierge session as a service, the quota snapshot
of four harnesses, the channel through the concierge) has been used in production on one user project. The
current layout (artel and `agents/` as submodules, `skills/` with symlinks, `/artel-create` on the host,
`/super`, `auth.json`) has been exercised on a live container. Not yet verified: `ask` through Telegram with a
live bot; OpenRouter balance probes with a live key; DeepSeek, Moonshot and Copilot quota probes are written
from provider documentation. Open work and known defects: `todo.md`.

## License
MIT, see `LICENSE`.
