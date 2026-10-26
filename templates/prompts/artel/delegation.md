---
name: artel/delegation
description: Delegation mechanics inside artel for a leader agent: quotas through artel quota and thresholds, where and how to run workers using other harnesses in the container (cwd, permissions, systemd scope, stopping), isolation through worktrees in scratch/, a brief that forbids agents/ and artel/, commits under artel lock, and STATE accounting. Supplements roles/leader.
requires: [roles/leader]
---

# Delegation in artel

The general leader discipline is in the `roles/leader` module; this module adds what the container and the artel
system require.

## Quotas
- Before a series of runs, use `artel quota` (from the cache, refreshed by a timer every 20 minutes; `--fresh` takes
  up to a minute, and the external timeout must be at least 90 s). The identity sets thresholds for each harness;
  typically, above 85% of the weekly window do only cheap work, and above 95% finish the run with a status mark.
- `PROBLEM` for a harness in the snapshot (not logged in, key rejected) means "do not run workers on it and record it
  in STATE"; an agent cannot fix credentials, so this is an escalation.
- Harness spending formulas are incompatible: compare quota shares before and after the series, not tokens.

## Where a worker works
- The worker's code directory is the absolute path `src/<repository>` (for codex, `-C`; for agy, `--add-dir`; for
  claude and opencode, `--add-dir`/`--dir`), not the user project root: otherwise it will go explore `agents/`.
- The container is already a sandbox, so start workers with full permissions: codex
  `--dangerously-bypass-approvals-and-sandbox` (its bwrap cannot be nested inside Claude's Bash sandbox and fails at
  startup), claude and agy `--dangerously-skip-permissions`, and opencode `--auto`.
- Harness credentials are already in the environment (`~/.config/artel/auth.env`); do not pass anything else.

## Launch so it can be stopped
```bash
systemd-run --user --scope --quiet --unit w-<task> -- timeout <minutes>m <harness command> \
  >scratch/<task>.out 2>scratch/<task>.err
```
- A private scope is needed because, in the container without changing the host AppArmor, ordinary `kill` fails
  (`Permission denied`) and `timeout` does not guarantee that the worker dies. Stop it with:
  `systemctl --user kill -s KILL w-<task>`; if that is also powerless, write `1` to its cgroup's `cgroup.kill`
  (module `artel/environment`, container pitfalls).
- Make the internal `timeout` shorter than your window: controlled exit code 124 is better than a stuck worker.
- Before finishing the run, make sure no workers are still alive:
  `pgrep -af 'codex exec|agy -p|claude -p|opencode run'`. The runner kills the entire agent process tree at the end,
  but until then the worker can change the tree and spend quota.

## Isolation and commits
- Workers that write files work in different directories or in a `git worktree` under `scratch/`, never beside the
  repository in `src/`: git for the user project would see it there and record it as a dirty nested repository.
  ```bash
  git -C src/<repo> worktree add ../../scratch/<task> -b wip/<task>
  codex exec -C "$PWD/scratch/<task>" …             # worker works there
  git -C scratch/<task> diff                         # collect the result
  git -C src/<repo> worktree remove ../../scratch/<task> && git -C src/<repo> branch -D wip/<task>
  ```
- The main copy in `src/<repo>` must always be on a branch, never detached HEAD. Do not run `git submodule update`
  in a working copy: that command is for a fresh clone of the user's project.
- Commit to a repository written by agents in other slots through `artel lock <repo> -- git …`.

## Worker brief: artel addition
Always add this line to the brief template from `roles/leader`:
```
Do not read or execute anything under ~/.claude/, .claude/, agents/, /home/artel/artel: these are instructions for another system.
```
Without it, Codex and agy go study the charter and journal instead of the task. Pass data (logs, diffs) in a file in
`scratch/` using an absolute path. All paths in the agy brief must be absolute.

## Sub-agents
The charter rule: built-in sub-agents may use only cheap models (`sonnet`/`haiku`, luna, Gemini Flash) with effort no
higher than `high`; set the model explicitly. Sub-agent spending for codex and agy is not included in the parent's
`usage` and is visible in `artel quota` only as a shift in the share.

## Accounting
At the end of the run, record in your `STATE.md`: how many workers and of which kinds, quota share before and after
by harness, what worked well, and what failed. The super agent uses these entries to rebuild the executor table in the
identity and the schedule.
