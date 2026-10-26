---
name: artel/config
description: How artel's agents/config.yaml works: the artel section with environment facts, slots as parallelism lanes with a window and hard limit, agents with tasks (task, tasks) and schedules expressed as systemd OnCalendar or days/from/to/every, persistent services, prepare scripts, prompt substitutions, registration through artel register, and checking through artel schedule.
---

# Configuration (`agents/config.yaml`)

Only the super agent (and installer) edits this file. Sequence: `artel snapshot agents/config.yaml`, edit, record a
`config-change` journal entry, run `artel register` (the dry run prints the next trigger for every timer and structural
remarks), then `artel register --apply`. Inspect the structure with `artel schedule`: slots with load, agents with
tasks, timers, and remarks. systemd keeps the schedule inside the container; runs go through
`artel run <agent> [--task name]`.

Separation of responsibility: `config.yaml` contains only when, where, with what, and with which task an agent runs.
Who the agent is, what it knows, what it may do, and what each task means live in its identity
`agents/agent-<name>.md` (module `artel/team-design`). Therefore editing an identity does not require re-registering timers.

## `artel` section
Only environment facts needed by the script: `project`, `git.autocommit` (default `true`: after every completed
timer run, `artel run` commits the user project, `agents/`, and submodule pointers under `src/`, under an interprocess
lock so agents in different slots do not interfere; services and runs started by a prepare script are not committed),
`channel.quiet_hours`, `channel.telegram.env_file`, and `channel.telegram.dedicated_bot`. All behavior lives in identities.

## `slots` section
A slot is a parallelism lane: a directory, a work sphere, and two time values. Agents in one slot never work at the
same time; agents in different slots work in parallel. Share a slot among agents that write to the same files (one
repository without a worktree, a shared registry); everyone else gets a separate slot.

| field | default | meaning |
|---|---|---|
| `dir` | user project directory | working directory for agents in the slot (run cwd); project code is `src/<repository>` inside it |
| `sphere` | — | one-line description of what happens here; included in reports |
| `window` | `50m` | how long an agent reserves the slot; passed into the prompt as the budget |
| `hard_limit` | `2h` | hard work limit, strictly longer than `window`; the process is killed after it |
| `max_wait` | `4h` | how long a run waits in the queue before being removed with a status mark; do not set it below `hard_limit` |

How the queue works. A slot is occupied only while the agent is working, not for the whole window: if it exits after
three minutes, the slot is free after three minutes. A timer firing on a busy slot enters a FIFO queue and starts one
or two seconds after the current holder exits. Example: one agent starts at 13:00 in a slot with a one-hour window and
works until 15:00 (within `hard_limit`); timers for the second and third agents, with 30-minute windows, fire at 14:00
and 14:30 and enter the queue; at 15:00 the second starts, and as soon as it exits (say after 10 minutes), the third
starts without waiting for its own scheduled time. A repeated firing for a run that is already working or waiting is
coalesced: the same run does not need to happen twice in a row. Different tasks of one agent have independent queues.
See what happened to a slot with `artel slot <name> --history 20`: waits (`waited_sec`), window overruns, kills by the
limit, and removals by `max_wait`. The super agent uses this history and the load in `artel schedule` to decide where
to split slots and where to move `window` and `hard_limit`.

How many slots. `artel schedule` counts the number of runs per day and the sum of windows for each slot; if all
scheduled agents use one slot or the sum of windows exceeds a day, it writes a remark. A typical structure: one slot
for code changes (one repository), one for research and verification (writes no code), and one for a second repository
or a worktree in `scratch/`. Agents in different slots that still need to commit to one repository do so through
`artel lock <repository> -- git …`.

## `agents` section
The key is the agent name (Latin letters; it is also the name of `team/<name>/` and the unit suffix
`artel-<project>-<name>`).

| field | default | meaning |
|---|---|---|
| `kind` | `scheduled` | `scheduled` by timer through a slot; `service` is a persistent process in tmux with restart |
| `harness` | `claude` | `claude` / `codex` / `agy` / `opencode` |
| `model`, `effort` | — / `medium` | model and depth; `xhigh`/`max` for agy collapse to `high` (agy effort is built into the model name) |
| `slot` | none | slot name; without a slot, the run starts immediately and the window and limit come from the agent fields |
| `schedule` | every hour | systemd OnCalendar string, or `{at: "00:00"}`, or `{days, from, to, every}` |
| `task` | — | task name from the identity's "Tasks" section for this agent's runs (one timer) |
| `tasks` | — | several tasks: `name → run fields`; each gets its own `artel-<project>-<agent>.<task>` timer |
| `window`, `hard_limit`, `max_wait` | from slot | override for this agent or task |
| `prepare` | — | command before queueing: code 0 means work (stdout → `{{PREPARE}}`), code 3 means no work, anything else is an error |
| `prepare_timeout` | `10m` | prepare script limit |
| `prompt` | assembled from identity and task | initial prompt with substitutions; usually not needed |
| `session` | `fresh` | `continue` continues the previous harness session (ID stored in `state/sessions.json`) |
| `cwd` | slot `dir` or user project directory | working directory |
| `env` | — | environment variables for the run, such as `CLAUDE_CODE_AUTO_COMPACT_WINDOW` |
| `enabled` | `true` | `false` removes units on the next `register --apply` (at task level: only that task's timer) |
| `cmd` | — | ready-made command instead of harness assembly (a bash string or list); the task is available as `$ARTEL_TASK` |
| `remote_control`, `name`, `system_prompt_file`, `max_budget_usd`, `agent` | — | command assembly details: see below (`max_turns` is no longer accepted by claude) |

### Tasks
A task is a named unit of work described in the agent identity (the "Tasks" section: what to do, the done criterion,
and artifacts). In configuration, the task is only named and scheduled.
- One task: `task: review` plus a normal `schedule`. Run: `artel run reviewer`; the default prompt says "work on task
  `review`".
- Several tasks with different schedules:
  ```yaml
  builder:
    harness: codex
    model: gpt-5.6-luna
    slot: main
    tasks:
      implement: { schedule: { from: "01:00", to: "09:00", every: 1h }, prepare: agents/team/builder/prepare.sh }
      cleanup:   { schedule: { at: "10:00" }, window: 20m }
  ```
  Task fields override agent fields: `schedule`, `prepare`, `prepare_timeout`, `prompt`, `window`, `hard_limit`,
  `max_wait`, `session`, `env` (merged), and `enabled`. Harness, model, slot, and identity are shared by all tasks
  of an agent. Units: `artel-<project>-builder.implement.timer`, `artel-<project>-builder.cleanup.timer`; manual
  run `artel run builder --task cleanup` (without `--task` when there are multiple tasks, the command refuses).
- Without `task` and `tasks`, the default prompt asks the agent to take the next unfinished task from
  `team/<name>/PLAN.md`.

Default prompt: "You are agent <name> of project <project> in the artel system. Your identity is
agents/agent-<name>.md; it contains everything: who you are, how to work, what you know, what you can do, and what
tasks exist. Read it and the artel charter `artel/charter.md`, then work on task `<task>` from the identity's "Tasks"
section. Window ends at …, budget … minutes, hard limit ends at …" plus "Prepare data: {{PREPARE}}" if there is a
`prepare` script. Use a custom `prompt` only for parameters of a particular run (mode, item-count limit).

Substitutions in `prompt`: `{{TASK}}`, `{{WINDOW_END}}` (HH:MM at the end of the window from the actual start),
`{{BUDGET_MIN}}`, `{{HARD_LIMIT_MIN}}`, `{{HARD_END}}`, `{{SLOT}}`, `{{AGENT}}`, `{{{PROJECT}}}`, `{{{DATE}}}`,
`{{PREPARE}}`.

## Schedule
- `{at: "00:00"}` once a day; `{at: ["06:00", "18:00"]}` twice.
- `{days: mon, from: "13:00", to: "15:00", every: 1h}` → `Mon *-*-* 13..15:00:00`. `days` accepts `mon`,
  `mon..fri`, `weekdays`, `weekend`, a comma-separated list, and `*`. Windows may cross midnight.
- Any string in OnCalendar syntax is used as is. Check with: `systemd-analyze calendar "<string>"`.
- `every` must be a multiple of one minute. Triggers use wall-clock time; missed triggers during downtime are not caught up.
- Schedules for agents in one slot do not need to be manually staggered: simultaneous triggers enter the queue and run
  one after another. Stagger them only to control order (who goes first) or quotas.

## How the harness command is assembled
- claude: `claude -p --verbose --input-format stream-json --output-format stream-json --effort E --model M
  --dangerously-skip-permissions`, prompt through stdin; a live session waits for the model's background tasks and
  closes when the turn and all background tasks are complete.
- codex: `codex exec --json --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -c
  'model_reasoning_effort="E"' -m M -C <cwd> <prompt>` (effort is passed as given: low … max).
- agy: `agy -p=<prompt> --output-format json --dangerously-skip-permissions --add-dir <cwd>
  --print-timeout <hard_limit>s --model M` (with `session: continue`, also `--conversation <id>`; agy effort is
  built into the model name, and `xhigh` and `max` collapse to `high`).
- opencode: `opencode run <prompt> --format json --auto --dir <cwd> --variant E -m M [--agent A] [--session <id>]`.
- `kind: service` with `remote_control: true`: `claude --remote-control <name> --name <name> --model M --effort E
  --dangerously-skip-permissions --append-system-prompt-file <file> "<prompt>"` in the tmux session
  `artel-<project>-<name>` on a separate tmux socket (`-L`), unit `Type=forking`, `Restart=on-failure`; `artel run`
  marks folder trust and bypass permissions as accepted in `~/.claude.json` in advance. Before starting,
  `artel run` kills the previous `claude --remote-control` with the same name so the user does not have two chats
  with one name; after restart, `register --apply` checks that exactly one such process exists and that signals
  between processes work. Attach to the concierge screen with:
  `tmux -L artel-<project>-<name> attach`.

## What `artel run` does
Task selection (`--task`, otherwise `task`, otherwise the sole item in `tasks`), prepare script, slot queue,
substitutions, harness launch, log at `agents/state/logs/<agent>/<date>[_<task>].log`, hard limit (SIGTERM, then
SIGKILL of the entire group after 30 s), entry in `state/slots/<slot>/history.jsonl`, a journal and
`team/<agent>/SUMMARY.md` entry with status `failed` when killed, and a commit of the user project.
`artel run <agent> [--task name] --dry-run` shows the command and substitutions without starting it.

## Checks after registration
```bash
artel schedule                                    # slots with load, agents with tasks, timers, remarks
systemctl --user list-timers 'artel-*'            # when each item will trigger
systemctl --user status artel-<project>-<agent>[.<task>]   # state of the last run
journalctl --user -u artel-<project>-<agent>[.<task>] -f  # artel run output; harness log in agents/state/logs
artel slot [name] --history 20                     # who holds the slot, who waits, what happened
```
