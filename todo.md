# artel · work plan

This file is kept the way artel keeps a plan (module `artel/plan`): phases with success criteria, steps with
ids `PP-SS`, statuses `[ ]` not started · `[~]` in progress (who, since) · `[x]` done (evidence) · `[!]`
blocked (reason) · `[-]` cancelled (reason). A step is `[x]` only with evidence another person can check:
a commit, a command and its output, a path. Finished phases are folded into `<details>`.

## Overview
Make artel a public project: readable in English by any developer, free of the author's private data,
with a documented update path for running installations, and verified on a clean Linux host. Then make the
process cheaper and self-improving: phases 5-9 implement the findings of the three-model consilium of
2026-10-27 (below), to be taken one at a time and tried on the running installations. Phase 10 implements
the recommendations of `docs/research/07-prompt-portability-across-models-and-harnesses.md`: one neutral
text per module and skill, a short curated layer of model notes, and measured per-model tuning.

## Consilium findings (2026-10-27)
Audit of the approach by Claude, Codex and Gemini against four wanted properties: flexibility across task
classes, per-project tuning, a process that gets more efficient over time within the budget, and token
economy. Evidence came from this repository (file:line) and from three live installations on the old
layout (20, 20 and 3 days of operation). Problems, ranked:
1. Reading tax grows with the project. Every run reads identity, charter, rules, STATE, its part of ROADMAP,
   its PLAN/STATE and the journal; super reads goal and ROADMAP in full and runs four commands (25% of its
   budget, super SKILL.md "Collection"). Files grow without a cap: a ROADMAP of 1.4 MB / 10,700 lines and
   a team SUMMARY of 427 KB were observed; one worker run cost 21M cache-read tokens for 99K output. The
   tax is context size × number of turns: each tool call resends the whole context.
2. Calendar polling without a gate. Runs start only from `OnCalendar`; `prepare` with exit 3 exists but is
   optional and absent from the template config, so the model starts to write "no work" itself. Where a
   super agent added prepare scripts by hand they cut 38 model calls in three days; without them "blocked /
   already done" runs cost 190K-385K input tokens each and one agent logged the same "blocked" every 2 h.
3. No first-class pipeline "script → cheap worker → check → expensive supervisor". Delegation exists only
   as prose: the expensive model launches workers from inside its own session and waits for them (one
   analyzer run held an opus session open over 5 codex + 2 agy workers; a developer on opus xhigh did
   everything itself, ~$70/day at list price).
4. Harness, model and effort are fixed per agent, not per task (`TASK_OVERRIDES`); a different model means
   a duplicate agent.
5. The system is blind to cost: `artel run` parses only the session id from the log; usage fields of all
   four harnesses are documented but never read; quota is a point snapshot (one project hand-rolled a
   quota history). No "cost per closed step", "idle run share" or "rework cycle" metric exists.
6. Self-improvement changes settings, never the architecture: 187 history snapshots across three projects,
   dozens of identity, plan and schedule edits, zero topology changes, zero agents removed. The super agent
   has no metrics (5), no primitive to express another topology (3, 4) and no experiment protocol.
7. Code-centric layout without profiles: `init` and the charter assume a git root with `src/` submodules;
   `team init` stamps four planning files per agent on top of the same four in `planning/`, and super
   spends 15% of each iteration moving statuses between them.
Kept as is: container isolation, `systemd --user` and file ownership spheres; four separate subscriptions
and the ban on expensive sub-agents; goal.md owned by the user and `artel/` immutable from inside;
single-file `bin/artel` on the standard library; `prepare` exit 3 and the failure-streak pause;
snapshot/history and the "2-3 reversible changes per iteration" rule.

## Phases
- [~] 1 · Publication readiness (since 2026-10-25)
- [~] 2 · Releases and the update process (since 2026-11-13; `artel update`, installation at the latest release
  the super skill and release v0.1.0 done; a run in a container and `artel brief` open)
- [ ] 3 · Live verification of what was only mocked
- [~] 4 · Public repository hygiene (license, history and rename done; smoke test and contribution notes open)
- [ ] 5 · Brief and bounded state: `artel brief` as the default prepare for every agent
- [~] 6 · Run telemetry and `artel stats` (since 2026-11-13; run records done for claude, codex and agy)
- [ ] 7 · Task-level pipeline: model per task, `verify`, `on_success`, `on_fail`
- [ ] 8 · Reactive runs: chains, `watch_paths`, persistent timers
- [ ] 9 · Evolution loop of the super agent: experiments, crystallisation, project profiles
- [ ] 10 · Model-aware prompts: portability lint, `models/` notes, measured per-model tuning
- [ ] 11 · Third-party skill libraries: pinned submodules in `skills-lib/`, index, per-skill activation
- [ ] 12 · Safeguards and procedures ported from gstack: write guard, unattended decisions, stop rules,
  secret check on commit, plan review, health check
- [~] 13 · Consilium run by a driver script: operator outside the discussion, one session per participant
  (since 2026-11-13; skill, driver and mock test done, checks on a Linux installation open)
- [ ] 14 · Run guards and on-demand context ported from OpenHands: repetition guard, token budget and spend
  by model, path-scoped modules, failover harness, recipe for external events

### Phase 1 · Publication readiness
Goal: every file in the repository is in English, consistent with the others, free of personal data and of
references to removed features; nothing unused remains.
Depends on: nothing.
Success criteria:
- A search for Cyrillic letters over tracked files prints nothing.
- A search for the author's private host and project names over tracked files prints nothing.
- `python3 -m py_compile bin/artel` and `bash -n install/*.sh install/inside/*.sh` pass.
- `artel init`, `artel prompts`, `artel skills --apply`, `artel run <agent> --dry-run`, `artel schedule` and
  `artel team init` work on a mock project on a Linux host with the translated CLI.
- Every file referenced from README.md, docs and templates exists; no file is referenced by nothing.
Steps:
- [x] 01-01 · lead · Inventory: files, sizes, Russian line counts, personal data, unused files.
      Done when: the list of files to translate, remove and rewrite exists. (evidence: this plan)
- [x] 01-02 · lead · Remove obsolete files: the old concept note (folded into README), `docs/todo.md` (replaced by
      this file). (evidence: commit b7ffe9b)
- [x] 01-03 · worker · Translate `bin/artel`: help, comments, messages, generated texts; data literals compared
      in code renamed consistently. Done when: `py_compile` passes, no Cyrillic, `artel help` runs on Linux.
- [x] 01-04 · worker · Translate the prompt library `templates/prompts/artel/*`. Done when: no Cyrillic, section
      names match those referenced from other modules and from `agent-prompt.md`.
- [x] 01-05 · worker · Translate `templates/prompts/{roles,harness,procedures}/*`. Done when: no Cyrillic.
- [x] 01-06 · worker · Translate `charter.md`, the `super` skill, `agent-prompt.md`, `rules.md`, `templates/agents`,
      `templates/home`, `templates/sphere`; add the charter rule "talk to the user in the language of goal.md".
      Done when: no Cyrillic, `{{...}}` placeholders intact.
- [x] 01-07 · worker · Translate `docs/install.md`, `docs/channel.md`, the `artel-create` skill; drop the
      `/opt/artel` appendix; the Russian placeholder in auth examples → `REPLACE_ME`. Done when: no Cyrillic.
- [x] 01-08 · worker · Translate `docs/harness-auth-guide.md`. Done when: no Cyrillic, placeholders renamed.
- [x] 01-09 · worker · Translate `install/*.sh`, `install/inside/*`, `templates/auth.json`; placeholder renamed in
      scripts and template together. Done when: `bash -n` passes, `apply-auth.sh --check` still detects the
      placeholder.
- [x] 01-10 · worker · Translate `docs/research/*.md`. Done when: no Cyrillic.
- [x] 01-11 · lead · Rewrite `README.md` in English with the concept from the old concept note; create this `todo.md`.
      (evidence: commit b7ffe9b)
- [x] 01-12 · lead · Review every worker's diff as a stranger: terminology, dropped sentences, broken
      placeholders, logic changes in `bin/artel`; fix the defects the workers reported. Done when: the success
      criteria 1–3 and 5 hold. (evidence: AST of bin/artel identical modulo string literals except one restored
      `daily` literal; section names cross-checked; commits b7ffe9b and the next one)
- [x] 01-13 · lead · Mock run on a Linux host (clone, `ARTEL_AD` mock project): `init`, `prompts`, `skills`,
      `team init`, `run --dry-run`, `schedule`, `register` dry. Done when: criterion 4 holds with output saved.
      (evidence: 2026-10-25 22:31 mock on a Linux host at b7ffe9b: all commands ran in English, no Cyrillic in
      the generated project)
- [ ] 01-14 · user · Deploy the English version to the running installation and have its super agent recompile
      identities (`artel prompts status`). Depends on: publication (the author does this step themselves afterwards): the running project's agents
      then read English modules and the super agent must recompile identities. Done when: `artel prompts status` is clean there.

### Phase 2 · Releases and the update process
Goal: a running installation keeps `artel/` at the latest release of its origin by itself. Moving `artel/` needs
no model; what the project adopts from a release is decided by its super agent, change by change; and the super
agent learns whether artel changed from one command or its run prompt, not from exploratory tool calls.
Depends on: phase 1.
Success criteria:
- A container created by `install/artel-up.sh` has `artel/` at the latest release of the origin (a tag
  `vMAJOR.MINOR.PATCH`), and `artel update` there prints that release and "up to date".
- `artel update` reports the installed and the available release; `--apply` moves `artel/`, self-checks, rolls
  back on failure and records both versions in `agents/state/artel-update.json`; it changes nothing in
  `agents/` or `skills/`; `--done` closes the review with the decisions in the journal.
- The super skill makes a timer run check for a release, apply it, review the report and decide per change.
- The origin has at least one release, and a container installed from it moves to the next one in a timer run
  of its super agent, with the decisions visible in `agents/journal.md`.
- `artel brief super` prints a block of at most ~10 lines, the update line included; the super config uses it as
  `prepare` and `{{PREPARE}}`. `artel prompts diff <module>` shows the change between an identity's base commit
  and HEAD.
Steps:
- [x] 02-01 · lead · `artel update` (check by default, `--apply`, `--to <ref>`, `--done <text>`) with
      `artel.update: release | branch:<name> | off` in config.yaml and `{{ARTEL_UPDATE}}` in the config template.
      A release is a tag `vMAJOR.MINOR.PATCH` read through git, not the GitHub API. The command refuses an
      `artel/` with uncommitted changes or commits its origin lacks, skips a release that failed its self-check,
      keeps an unreviewed update inside the next review range, and works on a bare clone before `artel init`.
      (evidence: 2026-11-13, macOS, git 2.56.0, `bash tests/update-smoke.sh` prints `ok 1` to `ok 9` and
      "all 9 checks passed": installation at the latest release; origin without tags; up to date although
      origin/main is ahead; a new release reported and recorded; apply with release notes, changed module, stale
      identity and skill copy while `skills/` stays byte-identical; review repeated until `--done`; broken
      release rolled back and skipped; local changes and local commits refused; `off`, pinned `--to`,
      `branch:main`, unknown value. Decision of the user, 2026-11-13: `--apply` does not run `skills --apply`,
      adoption is the super agent's call.)
- [x] 02-06 · lead · Super skill: section "Artel releases (part of a timer run)" (the command moves `artel/`;
      the super agent adopts, adapts, declines or defers each change; where a change lands; closing the review
      and its done criterion), the "Collection" item that calls `artel update`, the rule that everything artel
      ships is a default the user may change, and "no update in a live session without a request". The same
      default rule is in `docs/install.md` part 2, `README.md` and `CLAUDE.md`; `artel/config` documents
      `artel.update`. (evidence: `grep -n "Artel releases" templates/skills/super/SKILL.md` prints lines 19,
      152 and 220; whether a real super agent follows it is step 02-04)
- [~] 02-07 · lead, since 2026-11-13 · Installation at the latest release: `install/artel-up.sh` clones the
      origin, runs `artel update --apply --to <--artel-ref, default release>` before `artel init`, passes
      `--update branch:<name>|off` for another ref, replaces an ssh origin by its https form when that is
      readable without a key and otherwise mounts the host clone; `docs/install.md` sections 1.6, 4.2 and 8.3.
      Done so far: `bash -n install/artel-up.sh`; the two commands the script runs inside are checks 1 and 2 of
      `tests/update-smoke.sh`. Open: the script itself on an Incus host (02-04).
- [x] 02-08 · lead, on the user's request · Cut the first release v0.1.0: `## v0.1.0 · 2026-11-13` in
      `CHANGELOG.md`, annotated tag, `main` and the tag pushed, GitHub release with that section as its notes.
      (evidence: 2026-11-13, `git ls-remote --tags https://github.com/grishasobol/artel.git` without credentials
      prints `refs/tags/v0.1.0` and `refs/tags/v0.1.0^{}` at commit 1ffe3b1; `gh release view v0.1.0` reports
      `isDraft: false`; on a fresh https clone `artel update --apply --to release` and `artel update` both print
      "artel v0.1.0 (1ffe3b1) · follows releases of https://github.com/grishasobol/artel.git" and "up to date")
- [ ] 02-04 · lead · On a Linux host with Incus: `artel-up.sh` puts a container at the latest release; a second
      release appears; a timer run of the super agent applies it and closes the review; a release with a broken
      command is rolled back; an installation made before releases (on a branch) moves to the release.
      Depends on: 02-08.
- [ ] 02-02 · lead · `artel brief super` and `artel prompts diff`.
- [ ] 02-03 · lead · Super skill: "Collection" step reads the brief, which carries the `artel update` line; live
      session runs `artel brief` on request. Template config.yaml: `prepare: artel brief super`, `{{PREPARE}}`
      in the prompt.
- [ ] 02-05 · lead · Optional: extend the brief with journal counts since the last mark, escalations, paused
      agents, cached quotas.

### Phase 3 · Live verification of what was only mocked
Goal: every feature claimed in README has been seen working in a container with real harnesses.
Steps:
- [ ] 03-01 · `artel ask` through Telegram with a dedicated bot (`dedicated_bot: true`) and a real reply.
- [ ] 03-02 · `artel-up.sh` after rebuilding the image with the current `provision-base.sh` (`artel.layout`
      property set by the build, container comes up).
- [ ] 03-03 · Pause after three failures in a row observed live, not only in `--dry-run`.
- [ ] 03-04 · Several tasks of one agent (`tasks:`) running on real timers in a container.
- [ ] 03-05 · Cost and quota share of `gpt-6`-family and `gemini-4-argon` models measured and written into
      `harness/*` modules.
- [ ] 03-06 · Project prompt modules `agents/prompts/*.md` created in a live project; `artel prompts status`
      compares them by content, not only by file date.
- [ ] 03-07 · The installer-driven first run (`artel run super` with no `agents/rules.md`, docs/install.md
      step 7) seen on a live container with real logins: rules, plan, roster and timers appear without a
      live session; the hand-over summary and `artel cheatsheet` shown to the user.
- [ ] 03-08 · The opencode command of `build_harness_cmd` against opencode 2.x. Found 2026-11-13 on macOS with
      opencode 2.1.4: `opencode run <prompt> --format json --auto --dir <cwd> --variant low -m <model>` exits 1
      with "Unrecognized flag: --dir" and "Unrecognized flag: --variant"; 2.x takes the variant as
      `provider/model#variant` and has no `--dir`. `install/inside/provision.sh` installs the latest opencode,
      so a new container gets 2.x. Done when: an opencode agent completes a run in a container on the installed
      version, `harness/opencode` and `artel/config` describe that form, and `tests/fixtures/runs/opencode.log`
      is a captured log (see 06-01).

### Phase 4 · Public repository hygiene
Goal: the repository can be pushed to a public remote as is.
Steps:
- [x] 04-01 · user · Choose a license and add `LICENSE`. (evidence: MIT, file `LICENSE`, 2026-10-26)
- [x] 04-02 · user · Publish with a fresh history: the old history contained private project names and
      session links. (evidence: history squashed into a single initial commit on 2026-10-26; the private
      history stays on the private remote)
- [ ] 04-03 · lead · Smoke-test script `tests/smoke.sh` that runs the mock of 01-13 on any Linux host, for
      contributors and CI.
- [ ] 04-04 · lead · Short contribution notes in README: how to run the smoke test, where the plan lives.
- [x] 04-05 · lead · Rename the project from the author's surname to `artel` (name chosen by a three-model
      consilium on 2026-10-26): command `bin/artel`, prompt group `artel/`, container user and home
      `/home/artel`, container prefix `artel-<name>`, image `artel-base`, `ARTEL_*` variables, `/artel-create`
      skill, `artel-*` units. Done when: a case-insensitive search for the old name over tracked files prints
      only the copyright line in `LICENSE`; `py_compile` and `bash -n` pass; the mock of 01-13 passes with the
      new command. (evidence: 2026-10-26, mock on a Linux host: init, prompts, team init, run --dry-run,
      schedule, skills, journal, env, register all under the new name; `useradd ... artel` in provision.sh.
      The container user is a default, not a requirement: `provision-base.sh --user`, image property
      `artel.user`, `artel-up.sh --user/--image`, `auth-transfer.sh --user`, `apply-auth.sh` on `$HOME` and
      `id -u`; checked live on a Linux host: `artel-up.sh` on an older image with a differently named user
      laid out the project in that user's home, and without `--user` it stops with a clear error)
- [x] 04-06 · lead · Installation as a default scenario. Part 1 of docs/install.md is the
      default path the user may change at any step (section 0); installation from inside a container the user
      created themselves (section 8: `provision.sh` idempotent and runnable as `sudo ARTEL_USER=$USER`,
      `artel init` writes the PATH line into `~/.profile` and `~/.bashrc` when `artel` is not found); the
      installer itself starts the super agent's first run and hands over only a working container (section 7,
      super skill phase 0 in autonomous mode); `artel cheatsheet` prints one screen without blank lines at the
      end of `artel-up.sh` and of the installation. Done when: the mock of 01-13 passes with `cheatsheet` and
      the PATH line; a fresh `images:ubuntu/24.04` container provisioned from inside with an existing user runs
      `artel init`, `artel env`, `artel register` (dry) and `artel cheatsheet` under that user. (evidence:
      2026-10-26 on a Linux host: mock passed, PATH line written once to `.profile` and `.bashrc`, cheat sheet
      15 lines, no blank lines, at most 113 characters; container `artel-insidetest` from `images:ubuntu/24.04`
      provisioned with `ARTEL_USER=ubuntu` kept uid 1000, harnesses installed, `artel init --project insidetest`
      laid out `/home/ubuntu`, `artel register` listed 5 units, `bash -ic "which artel"` found the command)

### Phase 5 · Brief and bounded state
Goal: a run starts from a bounded, pre-collected delta instead of reading the whole state, and a run with no
work never reaches the model.
Depends on: phase 2 (`artel brief super` and `{{PREPARE}}` plumbing).
Success criteria:
- `artel brief <agent> [--task name]` prints at most ~150 lines: active steps of the agent, journal entries
  since its last mark, escalations, quota snapshot, the output of the last failed check (phase 7), and
  exits 3 when the agent has no `[ ]`/`[~]` steps and nothing new happened since its last run.
- `artel run` uses `artel brief` as the prepare when `config.yaml` sets none; a project `prepare` extends
  it instead of replacing it.
- `worker.md` and the super skill no longer instruct a run to read ROADMAP.md or SUMMARY.md in full.
- A run on a mock project with a 10,000-line ROADMAP starts with under 150K input tokens and makes at most
  one tool call before its first action on the task (measured with phase 6 telemetry or the harness log).
- No state file read at the start of a run exceeds 30 KB regardless of project age.
Steps:
- [ ] 05-01 · lead · `artel brief <agent>`: delta since `mark:<agent>`, active steps, escalations, quotas,
      last verify output; exit 3 rule. Done when: the output on a mock project fits in 150 lines and exit 3
      fires with no work.
- [ ] 05-02 · lead · Default prepare in `cmd_run`: brief when `prepare` is unset; project prepare receives
      the brief on stdin and may append. Done when: `--dry-run` shows the brief in `{{PREPARE}}` for an
      agent without `prepare`.
- [ ] 05-03 · worker · Rotation after `artel commit`: finished phases of ROADMAP.md folded into
      `history/roadmap-archive.md`, SUMMARY.md keeps the last 20 entries, older ones go to
      `history/summary-archive.jsonl`. Done when: files on the mock stay under 30 KB after 100 synthetic runs.
- [ ] 05-04 · worker · `agents/bin/` created by `artel init` and prepended to PATH in `cmd_run` before the
      prepare and the harness. Done when: a script put there is found by `which` inside a `--dry-run` env dump.
- [ ] 05-05 · lead · Protocol texts: `worker.md` step "Read", super SKILL.md "Collection", `agent-prompt.md`
      and `charter.md:3` rewritten around the brief; charter kept as the one full file read. Done when: no
      template tells a run to read ROADMAP or SUMMARY in full.
- [ ] 05-06 · user · Try on one running installation for a week; compare input tokens at run start before
      and after. Done when: the comparison is written here as evidence.

### Phase 6 · Run telemetry and `artel stats`
Goal: artel knows what every run cost and produced, and the super agent reads that from the brief instead
of guessing.
Depends on: nothing (phase 5 benefits from it).
Success criteria:
- `agents/state/runs.jsonl` gets one record per run: agent, task, harness, model, effort, input, cache_read,
  output tokens, cost (list), turns, duration, outcome (`advanced | noop | blocked | failed | killed`),
  step ids touched, session id.
- `agents/state/quota-history.jsonl` gets one record per quota snapshot.
- `artel stats [--since]` prints per agent and task in under a second: runs, idle share, median tokens per
  run, cost per closed step, rework cycles (the same step changed in more than two consecutive runs), and
  flags agents whose idle share or cost per step is above the project median.
- `artel brief super` includes the stats block.
Steps:
- [~] 06-01 · lead, since 2026-11-13 · Parse usage from the four harness outputs in `cmd_run` (claude
      stream-json `usage`, codex `turn.completed.usage`, agy usage line, opencode) into `runs.jsonl`; outcome
      from the SUMMARY entry and exit code. Done when: a `--dry-run` with a replayed log file writes a correct
      record for each harness (fixtures in `tests/fixtures/`). Reference: gstack
      `test/helpers/providers/claude.ts` and `gpt.ts` read the same usage fields for claude and codex; records
      are written through the 12-01 writer.
      Done for claude, codex and agy (evidence, 2026-11-13, macOS, python 3.15, no PyYAML):
      `bash tests/telemetry-smoke.sh` prints 10 `ok` lines and `all 10 checks passed`. It replays the logs of
      `tests/fixtures/runs/` through `artel run <agent> --dry-run --replay-log <file>` (the record is printed,
      not written), then starts seven real `artel run`s whose `cmd:` is a stub that prints a saved log and acts
      as the agent: outcome `blocked` with step `03-02` from the SUMMARY entry; a resumed codex session
      recorded as the difference to the previous record (493 fresh, 27 136 cached, 130 output of 54 894 input
      reported); `advanced` with step `01-02` from a mark changed in PLAN.md; `noop` for a "no work" entry and
      for a run without any trace; `failed` with its spend kept; `killed` at a 2 s hard limit. The fixtures of
      the three harnesses are logs captured with the commands `build_harness_cmd` assembles
      (`tests/fixtures/runs/README.md`). Live, same day, three agents on a mock project through `artel run`
      without a stub: claude haiku `blocked · tokens 14482 in + 37072 cached, 102 out` with step `02-05`,
      codex gpt-5.6-luna `noop · tokens 3298 in + 10240 cached, 5 out` and, resumed, `2351 in + 40192 cached,
      26 out` against session totals of 5 649 and 50 432, agy gemini-3.8-flash-low `noop · tokens 9231 in + 0
      cached, 1 out`.
      Outcome rule: `killed` on a kill, `failed` on a non-zero exit or a `failed` entry, `blocked` on a
      `blocked` entry, `advanced` when a step mark changed in ROADMAP or the agent's PLAN or the entry is
      `done`/`partial` without "no work", otherwise `noop`. The JSONL half of 12-01 exists as `jsonl_append`
      and `jsonl_read` (100 records from 10 concurrent writers and a truncated line read back as 100).
      Open: the opencode parser is written from the 1.x event shape and its fixture is synthetic, because
      opencode 2.1.4 does not start here (03-08); a run in a container with `systemd --user` and PyYAML was
      not made.
- [ ] 06-02 · worker · `quota-history.jsonl` appended by `cmd_quota` on every full snapshot. Done when: the
      quota timer produces one line per 20 minutes on the mock.
- [ ] 06-03 · lead · `artel stats` with the metrics above and the flags; block form for the brief. Done when:
      stats over a synthetic `runs.jsonl` of 300 records match hand-computed values. Includes the gstack
      `gstack-specialist-stats` rule: an agent with no findings in its last 10 runs is flagged as a candidate
      to drop, except agents on a never-flag list (security review, migrations), where an empty result is the
      normal outcome.
- [ ] 06-04 · lead · Super skill "Assessment": the question "how many runs produced little" is answered from
      stats, not from reading logs. Done when: the skill names the stats fields it reads.
- [ ] 06-05 · user · Correlate cache-read tokens with subscription percent on a running installation (claude
      and codex) and record the ratio in `harness/*.md`. Done when: the modules state tokens per percent.
Executor record (06-01, lead in the main session, no workers): four facts the plan and the harness notes had
wrong or did not know, each found by capturing a real log before writing the parser. (1) claude's top-level
`usage` leaves sub-agents out: a haiku run with one sonnet sub-agent showed haiku only in `usage` and both in
`modelUsage`, the sub-agent costing 13 times the parent ($0.0456 against $0.0035 for a sum of two numbers);
`harness/claude` said the opposite. In a process with several results `usage` is per result, `modelUsage` and
`total_cost_usd` are cumulative. (2) codex `turn.completed.usage` is cumulative over the thread, confirmed by
`total_token_usage` in the session file; an agent with `session: continue` would have been recorded with a
growing sum. (3) `codex exec resume` rejects `-C`, so `session: continue` could not work for a codex agent
since `build_harness_cmd` always added it; fixed, the resumed run then completed (rc 0). (4) opencode 2.x
rejects the flags of the opencode command (03-08). One `codex exec resume` hung at `turn.started` for 17
minutes with no output; the same command completed in seconds on the next two tries; the run was stopped with
SIGTERM and recorded as `killed` with `tokens unknown`. A claude run killed before its first result is recorded
from the responses seen (`usage_partial`), where the output count is understated: the streamed events of the
probe summed to 43 output tokens against 172 in the results.

### Phase 7 · Task-level pipeline
Goal: the pattern "script → cheap worker → check script → expensive supervisor only on failure or for
acceptance" is expressible in `config.yaml`, with the supervisor as a separate run and not a stage inside
the worker's session.
Depends on: phase 5 (the failed check reaches the next run through the brief).
Success criteria:
- A task may set `harness`, `model` and `effort` (added to `TASK_OVERRIDES`); the prepare script may select
  a model before the harness starts by printing an `ARTEL_MODEL=` line.
- A task may set `verify: <script>` run after the harness; its exit code sets the run outcome and its
  output is stored for the brief.
- A task may set `on_success: <agent>[:<task>]` and `on_fail: <agent>[:<task>]`; the named run is queued
  through the slot mechanism immediately, not at the next timer.
- A full DAG interpreter is out of scope (see Deferred).
Steps:
- [ ] 07-01 · lead · `harness`, `model`, `effort` in `TASK_OVERRIDES` and `build_harness_cmd`; `ARTEL_MODEL=`
      from prepare stdout. Done when: `--dry-run` shows different commands for two tasks of one agent.
- [ ] 07-02 · lead · `verify:` hook in `cmd_run`: run, record outcome and output, journal `verify` entry.
      Done when: a failing script on the mock produces outcome `failed` and the output appears in the next
      brief of the `on_fail` target.
- [ ] 07-03 · lead · `on_success` / `on_fail` chaining through the slot queue; loop guard (a chain may not
      re-enter the same run key within one hour). Done when: a three-link chain runs on the mock in order.
- [ ] 07-04 · worker · Template `config.yaml` example and `artel/config.md` section: a reviewer agent on a
      strong model that runs only `on_fail` of a cheap builder and once a day for acceptance. Done when: the
      example passes `artel schedule`.
- [ ] 07-05 · lead · `team-design.md` and `delegation.md`: the config pipeline becomes the first option;
      in-session delegation stays for one-off cases. Done when: both modules describe when to use which.

### Phase 8 · Reactive runs
Goal: runs start when work appears, not only on the calendar, and nothing is lost while the container is
down.
Depends on: phase 7 (chains).
Success criteria:
- `watch_paths:` on a task generates a `systemd.path` unit in `artel register`; a change under the path
  queues the run.
- Timers get `Persistent=true` so firings missed during downtime run once at boot.
- Timers remain the fallback for every task; no custom daemon, queue or webhook server is added.
Steps:
- [ ] 08-01 · lead · `watch_paths` in config schema and `cmd_register` (path unit per task, coalesced with
      the timer through the existing run-key logic). Done when: `register` dry output shows the path unit and
      a touch under the path on the mock starts a queued run.
- [ ] 08-02 · worker · `Persistent=true` in generated timers; `config.md` line on missed triggers rewritten.
      Done when: `register` output contains it and the docs no longer say missed triggers are lost.
- [ ] 08-03 · user · One running installation: replace one polling schedule with a watched spool directory
      and compare idle share from `artel stats`. Done when: the comparison is recorded here.

### Phase 9 · Evolution loop of the super agent
Goal: the super agent changes the architecture of the team, not only prompts and frequencies, and does it
as measured experiments with rollback; repeated agent work turns into scripts; non-code projects get a
lighter layout.
Depends on: phases 5-7.
Success criteria:
- `agents/state/experiments.json` holds experiments with hypothesis, config diff, budget in runs, target
  metric from `artel stats`, start and end; `artel experiment start|check|stop` manages them and `check`
  rolls the config back from `history/` when the metric is worse after the budget.
- The super skill requires one experiment proposal every N iterations and the crystallisation step:
  read the most frequent tool calls of workers from the logs (`artel stats --tools`) and move them into
  `agents/bin/` prepare or verify scripts.
- `artel init --profile code|research|ops|pipeline` lays out only what the profile needs (`data/` and
  `outputs/` instead of `src/` submodules where there is no code); `team init` creates only the sphere
  files the profile uses.
- `tasks.jsonl` with `artel task claim|done|block` is available for `ops` and `pipeline` profiles as an
  option; Markdown planning files remain the default.
Steps:
- [ ] 09-01 · lead · `artel experiment` and `experiments.json`; rollback through `history/`. Done when: an
      experiment on the mock rolls back a config change after N synthetic runs with a worse metric.
- [ ] 09-02 · lead · Super skill: experiment protocol, crystallisation step, "one topology hypothesis per
      week" heuristic; `team-design.md` tuning loop rewritten around stats. Done when: the skill names the
      commands and the metric for each.
- [ ] 09-03 · lead · `artel stats --tools`: counts of shell commands and file reads per agent from the run
      logs. Done when: the top 10 for the mock logs match a hand count.
- [ ] 09-04 · lead · `artel init --profile` and profile-aware `team init`; `docs/install.md` quiz asks the
      profile. Done when: a `research` profile project passes init, prompts, team init, run --dry-run and
      schedule on the mock without `src/`.
- [ ] 09-05 · worker · Optional `tasks.jsonl` registry and `artel task` for `ops`/`pipeline`; the brief
      reads it instead of the sphere files when present. Done when: a mock `ops` project runs with no
      `team/<agent>/STATE.md`.
- [ ] 09-06 · user · Run one experiment on a running installation: replace one strong-model worker with
      "script + cheap worker + verify + strong reviewer on_fail" and compare cost per closed step. Done
      when: the numbers are recorded here with the decision to keep or roll back.

### Phase 10 · Model-aware prompts
Goal: one canonical text per library module and per skill serves all four harnesses; what really differs
between models reaches an identity through a short curated note applied at compile time; per-model tuning
of identities is measured and reversible; mechanical portability failures are caught by a script.
Source: `docs/research/07-prompt-portability-across-models-and-harnesses.md` (sections 7 and 8).
Depends on: nothing for 10-01 to 10-04; phases 6 and 9 for 10-05 and 10-06.
Success criteria:
- `artel lint` exits 0 on this repository and on a generated mock project, and exits non-zero on a fixture
  for each known failure class (section 3 of the report).
- `templates/prompts/models/` holds `claude`, `gpt`, `gemini` and `open-weights`, each at most 25 lines of
  behavioural deltas, each claim with its source and a `checked:` date and model list in the frontmatter.
- An identity compiled for an agent lists its `models/<family>` module in `sources:`, and `artel prompts
  status` reports it stale after that module changes.
- The super agent writes no library modules and no worker skills; model-specific lessons reach this
  repository as `model-note` journal entries and are promoted or rejected here by a reviewed commit.
- One measured before-and-after comparison for an open-weight worker model is recorded in this file.
Steps:
- [ ] 10-01 · lead · `artel lint`: for every `SKILL.md` under `templates/skills`, `.agents/skills` and a
      project's `skills/`: exact file name, `name` equal to the directory, description at most 1,024
      characters, frontmatter keys from the Agent Skills spec plus an allowlist (`argument-hint`), body under
      500 lines, YAML that loads under PyYAML's safe loader with no BOM; instruction files (`AGENTS.md`,
      `CLAUDE.md`) under 24,000 bytes; templates free of ALL-CAPS emphasis words and "show your reasoning"
      phrases; the Cyrillic check, locale-independent, with `README.md` as the only allowed file (the grep in
      `CLAUDE.md` misfires on macOS with an empty `LANG` and matches its own pattern in `AGENTS.md` and
      `CLAUDE.md`). Done when: lint passes on the repository and the mock, fails on fixtures in
      `tests/fixtures/lint/` (apostrophe in a single-quoted description, BOM, 1,100-character description,
      lower-case `skill.md`, an unknown key), and the "Checks" section of `CLAUDE.md` runs it.
- [ ] 10-02 · lead · Prompt group `models/` with four modules of behavioural deltas, for example: Claude in
      unattended runs is told it runs unattended and when to stop and ask, never asked to echo its
      reasoning; GPT-6 models are told when to delegate; open-weight models get explicit structure, one
      worked example, a single system message and the vendor's sampling settings. A module may start with an
      inherit line naming its base family module, so a version-specific note holds only its difference, and
      the compiled block is headed as preferences subordinate to the charter and the identity (both from gstack
      `model-overlays/` and `scripts/resolvers/model-overlay.ts`). Done when: `artel prompts` lists the four
      modules, each is at most 25 lines, and every claim cites report 07 or a run.
- [ ] 10-03 · lead · Compile rule: `artel/team-design` names `models/<family>` as a source next to
      `harness/<name>`; changing an agent's model or harness counts as a prompt change and means recompiling
      from the library; the comment on "Harness and model" in `agent-prompt.md`, the group list in the super
      skill, "Where the rest lives" in the charter and the README layout name the new group. Done when: grep
      finds `models/` in each of those files, and on the mock `artel prompts status` reports an identity stale
      after its `models/` module is edited.
- [ ] 10-04 · lead · Curation path: the super skill tells the super agent to record a model-specific fix that
      held over several runs as `artel journal --type model-note` with the evidence; this file's "Working with
      the plan" notes in `CLAUDE.md` describe promoting a note into `models/*` and pruning notes a new model
      generation no longer needs. A note carries a key, a confidence from 1 to 10 and a source (`observed`,
      `user-stated`, `inferred`, `cross-model`); a newer note with the same key supersedes the older one, and
      observed or inferred notes lose weight with age (the shape of gstack `bin/gstack-learnings-log` and
      `gstack-learnings-search`). Done when: the super skill names the entry type, its fields and the
      condition, and `CLAUDE.md` describes the promotion.
- [ ] 10-05 · lead · Per-model tuning of an identity as an experiment: the "Tuning an identity" section of
      `artel/team-design` requires a hypothesis, the `artel stats` metric it should move and a run budget,
      and uses `artel experiment` for rollback. Depends on: 06-03, 09-01. Done when: the section names the
      command and the metric, and an experiment on the mock rolls an identity edit back.
- [ ] 10-06 · user · On a running installation with an opencode worker: share of runs ending `advanced`
      versus `noop` or `failed` per model, before and after applying `models/open-weights`. Depends on:
      06-01, 10-03. Done when: the numbers and the keep-or-revert decision are recorded here.

### Phase 11 · Third-party skill libraries
Goal: a project can use curated skills from vetted public libraries in all four harnesses without fetching
libraries it does not need, without floating versions and without linking whole libraries.
Source: `docs/research/08-third-party-skill-libraries.md` (sections 3 to 5).
Depends on: 10-01 for the lint checks in 11-04; nothing for the rest.
Success criteria:
- `skills-lib/` holds the 31 submodules of report 08, section 3, each pinned, with `update = none` and
  `shallow = true`; a fresh `git clone --recurse-submodules` of artel fetches none of them.
- `skills-lib/index.tsv` lists every skill of every submodule and known source at its pinned commit, and
  `grep` over it finds a skill by topic without any library fetched.
- On a mock project one vendored skill is active through a symlink and one adapted copy carries its upstream
  library, commit and path; `artel link` exposes both to all four harnesses.
- A pin bump is one commit here whose message names the library, and its new scripts, hooks and privilege
  fields are listed by a command before the commit.
Steps:
- [ ] 11-01 · lead · Add the 31 submodules under `skills-lib/<group>/<owner>-<repo>` (groups `core`, `work`,
      `research`, `security`, `platform`) with `update = none` and `shallow = true`; README layout and the
      "What is where" list in `CLAUDE.md` name `skills-lib/`. Done when: `git submodule status` lists 31
      entries and a fresh clone with `--recurse-submodules` has empty `skills-lib/*/*` directories.
- [ ] 11-02 · worker · `artel skills index` regenerates `skills-lib/index.tsv` from the GitHub API at the
      pinned commits (submodules and the known sources of report 08, section 4): library, group, path, name,
      description cut to 200 characters, licence, scripts yes or no, `allowed-tools` or `hooks` yes or no.
      Done when: the file has one row per `SKILL.md` (2,725 for the submodules at the current pins) and
      `grep -c` per library matches the tree count.
- [ ] 11-03 · worker · `artel skills fetch <library>` initialises one submodule shallowly; `artel skills use
      <library>:<path>` links it into the project's `skills/`; `artel skills adapt` copies it and writes the
      provenance into frontmatter `metadata`; `artel skills --apply` leaves both alone. Done when: the mock
      run of `CLAUDE.md` plus these three commands shows the skill in `.claude/skills` and `.agents/skills`.
- [ ] 11-04 · lead · Review support: `artel skills review <library>` (and `--since <old-commit>` for a bump)
      lists scripts, binaries, archives, hooks, `allowed-tools` and name/directory mismatches; `artel lint`
      (10-01) runs over linked and adapted skills. Done when: the command reports the known findings of report
      08 (four name mismatches in vercel-labs/agent-skills, hooks in obra/superpowers).
- [ ] 11-05 · lead · Choice and adaptation rules: `docs/install.md` part 1 tells the installer to fetch the
      groups that match `goal.md`; the super skill tells the super agent to activate few skills, read every
      bundled file of a skill with scripts or privilege fields before linking, record each choice with its
      reason in `agents/environment.md`, and treat an adaptation as a measured delta (10-05). Done when: grep
      finds `skills-lib` and `environment.md` in both texts.
- [ ] 11-06 · user · On a Linux host: Claude Code, Codex, agy and opencode each invoke one vendored skill
      reached through `skills/` symlinks into `artel/skills-lib/`. Done when: the four outputs are recorded
      here (report 08, section 6: symlink handling in agy and opencode is undocumented).

### Phase 12 · Safeguards and procedures ported from gstack
Goal: what agents write cannot carry instructions to the next agent, a secret never reaches the history, an
agent knows which decisions it may take alone and when to stop trying, and the super agent has procedures to
review its plan and watch project health.
Source: garrytan/gstack 1.62.0.0 (commit d078622, MIT), files named in each step. Nothing is copied as is:
the tools need Bun and `~/.gstack`; each mechanism is rewritten in python3 with the standard library or as a
prompt module, and ported code keeps the MIT notice of its source.
Depends on: nothing for 12-01 to 12-04; phase 6 for the trend in 12-06.
Success criteria:
- `artel journal`, `artel summary` and `artel escalate` refuse text with instruction-like phrases and name
  the matched pattern; JSONL files written by artel stay parseable under concurrent writers.
- `artel commit` refuses to commit an added line that matches a high-tier secret pattern and reports file
  and line without the value.
- The library has `procedures/unattended-decisions`, `procedures/plan-review` and
  `procedures/health-check`; the charter names one-way doors; `artel/worker` names the stop rules.
Steps:
- [~] 12-01 · lead, since 2026-11-13 (the JSONL writer and tolerant reader exist as `jsonl_append` and
      `jsonl_read`, checked in `tests/telemetry-smoke.sh`, see 06-01; the guard on free text is open) · Write guard: one writer in `bin/artel` for agent-written text and JSONL records rejects
      free text that matches instruction-like patterns (port of `INJECTION_PATTERNS` in gstack
      `lib/jsonl-store.ts`), appends each JSONL record as one line in one write, and a tolerant reader skips a
      corrupt or truncated line. Done when: a fixture entry containing "ignore previous instructions" exits
      non-zero and names the pattern; 10 processes appending 10 records each leave 100 parseable lines; a
      truncated last line is skipped by the reader.
- [ ] 12-02 · lead · `procedures/unattended-decisions`: every decision an agent takes in the user's place is
      mechanical (taken silently), taste (taken and listed in the run's report) or a change to what the user
      asked for (never taken; it goes to `artel ask` or an escalation with what was asked, what is proposed,
      why, and the cost of being wrong); decisions are logged with `artel journal --type decision`. The
      charter names one-way doors (recursive delete, force push, branch deletion, data-losing migration,
      anything outside the agent's sphere) as always escalated, and the rule "delete only what you can show
      you created". Source: gstack `autoplan/SKILL.md` 915-1024, `scripts/one-way-doors.ts`,
      `lib/staging-guard.ts`. Done when: `artel prompts` lists the module, grep finds "one-way" in `charter.md`,
      and the super skill and `artel/worker` reference the module.
- [ ] 12-03 · lead · Stop rules in `artel/worker`: three refuted root-cause hypotheses end the attempt; in a
      fix loop, a risk score (reverts, fixes touching more than three files, edits to unrelated files) above
      20% or 50 fixes in one run ends it; the run ends `blocked` with the evidence and an escalation instead
      of another attempt. Source: gstack `investigate/SKILL.md` 960-975, `qa/SKILL.md` 1585-1600. Done when:
      grep finds both rules in `artel/worker.md` and the outcome name matches the phase 6 vocabulary.
- [ ] 12-04 · worker · Secret check in `cmd_commit`: high-tier patterns ported from gstack
      `lib/redact-patterns.ts` (with its MIT notice) scan the added lines of the staged diff of `agents/` and
      the root; a hit blocks that commit and writes an escalation with file and line, never the value; the
      medium tier escalates and commits. Done when: fixtures with a fake cloud key and a fake private key are
      blocked and the value appears in no output or log; a clean diff commits; `artel run` reports a blocked
      commit as a failure.
- [ ] 12-05 · lead · `procedures/plan-review` for the super agent whenever ROADMAP changes: the reviewed plan
      names what already exists, what is not in scope, the minimal version and two or three alternatives with
      a recommendation; each new path has a test line or GAP, one realistic failure and whether it would be
      silent; steps are grouped into parallel lanes by directory with conflicts flagged. Source: gstack
      `plan-eng-review`, `plan-ceo-review`. Done when: the module is listed, the super skill names it, and a
      review on the mock records the not-in-scope list, gaps and lanes in the journal.
- [ ] 12-06 · lead · `procedures/health-check` for a read-only observer agent: the project's check commands
      are recorded once in `agents/environment.md`; each category scores 0-10 with fixed weights, a missing
      tool is skipped and its weight redistributed; one JSONL line per run in the agent's sphere; a drop
      names the category, the delta and the new errors. Source: gstack `health/SKILL.md` 799-1076. Depends on:
      12-01. Done when: an observer configured from the module on the mock writes two lines and reports a
      forced drop with its category.

### Phase 13 · Consilium run by a driver script
Goal: a consilium costs its convener a few one-screen events instead of the whole discussion. The agent that
convenes it is the operator and not a participant; two or three models, each in one harness session for the
whole consilium, talk in a shared space in a fixed order under a script; the lead's final answer needs the
approval of the others; limits and access are set by the operator per task.
Source: the user's requirements of 2026-11-13 (ten points, then answers to seven questions).
Depends on: nothing.
Success criteria:
- `templates/skills/consilium/` holds `SKILL.md` for the operator and the driver `consilium.py` (python3,
  standard library only); `procedures/consilium` points to it.
- `tests/consilium-smoke.sh` passes on any machine with python3 and spends no quota.
- A consilium of claude, codex and agy sessions reaches an approved final answer with each participant in one
  session, the operator reading only events.
Steps:
- [x] 13-01 · lead · Driver `templates/skills/consilium/consilium.py`: commands `probe`, `start`, `wait`, `reply`,
      `status`, `run`; space `space/NNNN-author.md` numbered in the order messages are finished; each turn
      delivers only the messages the participant has not seen; control lines `VOTE`, `DECISION`
      (`ASK | RESEARCH | FINAL | PROCEED`), `TO-OPERATOR`; events `questions`, `checkpoint`, `request`,
      `research-request`, `deadline`, `collapsed`, `error`, `final`; hang protection of 60 minutes of working
      time and 30 minutes per turn, extendable by the operator. (evidence: `python3 -m py_compile
      templates/skills/consilium/consilium.py` passes; `python3 templates/skills/consilium/consilium.py help`)
- [x] 13-02 · lead · Mock test `tests/consilium-smoke.sh` (harness `mock`, no quota). (evidence: 2026-11-13,
      macOS, python 3.15: `bash tests/consilium-smoke.sh` prints 12 `ok` lines and `all 12 checks passed`:
      questions and answers, parallel research, checkpoint, objection and second final, one session per
      participant over 19 turns, delta without own messages, brief sent once, quick run with a repaired
      missing vote, dropped participant, lead succession and `collapsed`, deadline and `--extend`, request of
      the lead, `hurry`, `finalize`, `say` and `abort` against a detached driver)
- [x] 13-03 · lead · Live run on the cheapest models of the three harnesses (claude 2.1.323 haiku, codex-cli
      0.166.0 gpt-5.6-luna low, agy 1.5.8 gemini-3.8-flash-low), macOS, 2026-11-13. (evidence: quick run, 6
      messages, 30 s of working time, final approved by both others; full run with web research, 13 messages,
      14 calls, 103 s: lead `PROCEED`, parallel research with links, `FINAL`, one `OBJECT`, revised `FINAL`
      approved by both; session ids of all three unchanged between turns; `probe` printed models and both
      quota windows of each harness in 29 s)
- [x] 13-04 · lead · Operator skill `templates/skills/consilium/SKILL.md`; `procedures/consilium` reduced to a
      pointer; README, `templates/home/AGENTS.md`, `artel/team-design` and two strings of `bin/artel` name the
      skill. (evidence: `artel prompts`-visible frontmatter kept; the `bin/artel` change is string-only: AST
      equal modulo string literals against the previous file)
- [ ] 13-05 · lead · On a Linux installation: `artel init` and `artel skills --apply` copy `consilium.py` intact
      (no placeholder is substituted in it), `artel link` exposes `/consilium` in every harness, a consilium
      started from an `artel run` reaches `final` with `--access full` where the codex sandbox cannot nest, and
      the concierge service comes up with `--strict-mcp-config` in its command (13-08).
      Done when: the commands and the `final` event are quoted here.
- [ ] 13-06 · lead · Measure a real `deep` consilium on strong models: turns, working time and quota share per
      participant, and how often the lead closes the clarify stage with `PROCEED` against the others' wish.
      Done when: the numbers are here and the quota guidance in the skill is corrected from them.
- [x] 13-07 · lead · Cut the fixed context of a claude participant: the driver starts it with
      `--strict-mcp-config --tools <read, web, Agent>` and `--restricted` when the CLI has it. (evidence,
      2026-11-13, claude 2.1.323, haiku: a one-word turn reads 43 424 input tokens with the old flags and 6 975
      with the new ones, 9 872 with `Agent`; `/context` attributes the old figure to system tools, the skill list
      and MCP definitions; the same quick consilium cost the claude participant 84 235 input tokens before and
      15 996 after over 2 turns; the full run with web research 354 778 over 5 turns before and 143 722 over 7
      turns after; under the new flags a read inside `--add-dir` succeeds, a read outside is refused, web search
      answers, a sub-agent runs on sonnet, `--resume` recalls the previous turn, OAuth login still works;
      the table is in `harness/claude`, which now makes `--strict-mcp-config` mandatory for every headless call:
      connectors attach after the start, a several-request turn with `--tools Bash` read 6 619 tokens on the
      first request and 61 790 to 63 937 on the later ones without the flag, 6 623 and 6 843 with it. Not
      checked: token login in a container, see 13-05. Codex gains nothing
      from `--ignore-user-config --ignore-rules`: 12 895 against 13 133 tokens)
- [x] 13-08 · lead · `artel run` starts every claude agent with `--strict-mcp-config`, in the headless form and
      in the `remote_control` service form; the new agent field `mcp_config` (path or list) becomes
      `--mcp-config`, placed before another option because it takes several values; `artel/config` and
      `harness/claude` describe it. (evidence, 2026-11-13, macOS: `build_harness_cmd` imported from `bin/artel`
      prints `claude -p --input-format stream-json --output-format stream-json --verbose --strict-mcp-config
      --effort medium --dangerously-skip-permissions --model sonnet` for a plain agent, `... --strict-mcp-config
      --mcp-config agents/mcp.json --effort ...` with the field, and `claude --remote-control concierge --name
      concierge --dangerously-skip-permissions --strict-mcp-config --mcp-config a.json b.json --effort medium
      PROMPT` for the service; the headless form run live on haiku with a three-request turn: exit 0,
      `mcp_servers: []`, no `mcp__` tools, input 39 145, 39 247 and 39 349 tokens per request, result `done`.
      Not checked: the `remote_control` form was not started live, and no run was made in a container, see
      13-05)
Executor record: haiku left out the `VOTE` line once in five turns (full run of 13-03); the one-line repair
call recovered it (`VOTE: OBJECT`). No participant failed or timed out in any of the four live runs. In the
second full run (13-07) the lead's checkpoint report after two circles was accurate ("converging, one editorial
disagreement"), and `hurry` ended the consilium in the next circle with both approvals.

### Phase 14 · Run guards and on-demand context ported from OpenHands
Goal: a run that repeats itself or overspends is stopped by artel and not by the next super iteration, a run
that fails on an exhausted subscription continues on another one, and project knowledge reaches a run only
when its task touches the matching files.
Source: `docs/research/09-openhands.md` (section 4). Nothing is copied: OpenHands guards a loop of model calls
through its event log, artel guards harness runs through `runs.jsonl` and the harness stream.
Depends on: 06-01 for 14-01, 14-02, 14-04 and 14-05; 05-01 for 14-06; nothing for 14-03 and 14-07.
Success criteria:
- An agent whose runs keep ending `blocked` or `noop` on the same steps is paused with an escalation, the way
  three failed runs pause it today.
- A run whose harness stream repeats one tool call with one result, or exceeds the task's `max_tokens`, ends
  as `killed` with the reason in the journal, on each harness whose stream artel reads.
- `runs.jsonl` holds spend per model of a run, and `artel stats` flags a run in which a model above the cheap
  tier appears next to the agent's own model.
- A task with `fallback:` that fails on a rate limit or an exhausted window is rerun once on the fallback
  harness; a login failure is not.
- A project module with `paths:` appears in the brief only for a task whose steps name matching paths.
Steps:
- [ ] 14-01 · lead · Repetition guard across runs in `cmd_run`: the last N records of the same agent and task
      in `runs.jsonl` with outcome `blocked` or `noop` and the same step ids (N from `repeat_pause`, default 3)
      pause the agent through the failure-streak mechanism, with an escalation naming the steps; `--force`
      clears it. Done when: on the mock three replayed `blocked` records on one step skip the fourth run with
      a journal entry `paused`, and a record with another step id in between does not.
- [ ] 14-02 · lead · Repetition guard inside a run: while reading the harness stream, `cmd_run` counts
      consecutive tool calls equal in name and arguments with equal results, and consecutive failures of one
      call; at `loop_guard` (default 4 identical, 4 failing, off with 0) it ends the run as `killed` with the
      pattern and the call in the journal. Done when: a replayed fixture stream with four identical
      call-result pairs is killed and one with three is not, for claude and codex; the harnesses whose stream
      does not expose tool calls are named in `artel/config`.
- [ ] 14-03 · lead · Repetition notice in the consilium driver: the same voter objecting to two finals in a
      row, or a circle whose messages equal the previous circle's after whitespace folding, raises a
      `checkpoint` event at once with the pattern named in the notice; the driver ends nothing itself. Done
      when: `tests/consilium-smoke.sh` has a check where a mock voter objects twice and the operator gets the
      checkpoint before the configured circle count.
- [ ] 14-04 · lead · `max_tokens` on an agent or task: the sum of input, cache-read and output tokens from the
      usage records of the stream, compared after each record; over the limit the run ends as `killed` with
      the figure in the journal. `artel/config` states that `max_budget_usd` stays claude-only and that
      `max_tokens` works wherever 06-01 reads usage. Done when: a replayed fixture exceeding the limit is
      killed at the first record over it, for each harness with a fixture.
- [~] 14-05 · lead, since 2026-11-13 (the `models` map is in the record: `tests/telemetry-smoke.sh` check 5
      reads two models from `tests/fixtures/runs/claude-subagent.log`; the flag in `artel stats` waits for
      06-03) · Spend by model: `runs.jsonl` records a `models` map (claude: `modelUsage` of the result
      message, checked on 2.1.325; the other harnesses: the one model of the run); `artel stats` flags a run
      whose map holds a second model outside the cheap tier of `charter.md`. Done when: a fixture result with
      two models, one of them strong, is flagged and a fixture with a sonnet sub-agent is not.
- [ ] 14-06 · lead · Path-scoped project modules: a module in `agents/prompts/` may carry `paths:` globs in
      its frontmatter; `artel brief` (05-01) names such a module only when a path written in the agent's
      active steps matches, and `artel prompts status` lists identities that still inline a path-scoped
      module. `artel/plan` says a step names the paths it touches; `agent-prompt.md` tells a run to read the
      modules named in its brief. Done when: on the mock a module with `paths: src/db/**` is in the brief of
      an agent whose active step names `src/db/schema.sql` and absent for an agent without such a step.
- [ ] 14-07 · lead · Failover harness: a task or agent may set `fallback:` (harness, model, effort); when the
      run fails with a rate-limit or exhausted-window error of its harness, or the quota snapshot puts the
      harness over the project's threshold before the start, `cmd_run` runs the task once on the fallback and
      records the harness that did the work; a login failure still goes to the user and is never retried; the
      next scheduled run starts from the primary. The error patterns per harness go into `harness/*.md`. Done
      when: on the mock a stub harness exiting with the recorded rate-limit text triggers one fallback run,
      and a stub exiting with the login text triggers none.
- [ ] 14-08 · worker · `artel/config` section "Runs on external events": a `prepare` script as poller and
      filter that exits 3 when nothing matched, and a spool directory under `watch_paths` (08-01) for pushes
      delivered from outside; no webhook server in the container. Done when: grep finds the section and the
      template `config.yaml` has a commented example of each.

## Deferred and cancelled
| item | reason |
|---|---|
| Mechanical prompt composition by artel (`artel prompts compose`) | rejected: the super agent distils identities by hand; artel provides the library and the catalog only |
| Full DAG interpreter in `config.yaml` (stages, workers, escalation graph) | rejected by the consilium 2026-10-27: `verify` + `on_success` + `on_fail` with the supervisor as a separate run covers the cases without turning artel into a workflow engine |
| Own durable queue, webhook server or orchestrator daemon in the container | rejected 2026-10-27: reliability rests on `systemd --user`, `flock` and the file system; `systemd.path` and persistent timers suffice |
| Mandatory hand-written `prepare` for every task | rejected 2026-10-27: the built-in `artel brief` gates and briefs by default; a project prepare only extends it |
| `tasks.jsonl` replacing the Markdown planning files for every project | deferred 2026-10-27: Markdown stays the default; the registry is an option for `ops`/`pipeline` profiles (09-05) |
| Per-harness or per-model copies of prompt modules and skills in this repository | rejected 2026-10-27 (report 07): the copies multiply with modules, harnesses and models, age with every model release, and nothing measures whether a copy beats the neutral text plus a `models/` note |
| The super agent authoring library modules or worker skills on its own | rejected 2026-10-27 (report 07): SkillsBench measured self-written skills below no skills at all (-8 to -11.5 points); lessons come back as `model-note` entries and are curated here |
| Linking whole third-party skill libraries into a project | rejected 2026-10-27 (report 08): skill shadowing cost up to 21% at 202 skills; a project activates individual skills |
| Installing third-party skills through `npx skills`, ClawHub or other marketplaces | rejected 2026-10-27 (report 08): no commit pin, scanners bypassed in under an hour; submodules pinned here and reviewed on bump |
| Vendoring Claude plugins (hooks, commands, MCP) from skill libraries | rejected 2026-10-27 (report 08): they do nothing in Codex, agy and opencode and grant privileges in Claude Code; only skill directories are used |
| `artel update --apply` refreshing skill copies, identities or config by itself | rejected 2026-11-13 (user): a project has its own pipelines and tuning, so the command moves only `artel/` and the super agent decides per change what the project adopts |
| The GitHub Releases API as the source of releases | rejected 2026-11-13: tags read through git need no token, work for forks, private mirrors and a mounted host clone, and a GitHub release always has a tag |
| Using gstack tools or skills as is | rejected 2026-11-13: they need Bun and `~/.gstack`, and every skill carries a shared preamble of about 800 lines (update check, telemetry, sessions); phase 12 ports the mechanisms instead |
| gstack remote telemetry, gbrain memory sync, developer and taste profiles | rejected 2026-11-13: they phone home, duplicate `agents/` or serve one interactive human |
| Git merge driver that unions appended JSONL lines (gstack `bin/gstack-jsonl-merge`) | deferred 2026-11-13: `agents/` has one writer branch in one container; revisit if projects get parallel working copies |
| Caps on the number of turns, question batches or research rounds built into the consilium driver | rejected by the user 2026-11-13: the operator sets limits per task and steers at checkpoints; the driver only guards against hanging (working time, turn time) |
| The convener of a consilium as its chair and participant (the previous `procedures/consilium`) | replaced 2026-11-13 (phase 13): the chair paid for the whole discussion in its own context; the operator now reads only events |
| Rebuilding artel on OpenHands, or running harnesses through its agent server | rejected 2026-11-13 (report 09, section 3): for an ACP agent its condenser, tools, MCP and critic are switched off and permissions are auto-granted; what remains is a transport bought with a server daemon and `npx` adapters |
| ACP as the single transport to all four harnesses | deferred 2026-11-13 (report 09): one usage format instead of four parsers, but claude and codex need third-party adapters and pass-through of harness flags (`--strict-mcp-config`, tool list, effort) is unknown; revisit if the parsers of 06-01 prove costly to maintain |
| Checkpoint report of the consilium lead asked in a forked session | deferred 2026-11-13 (report 09): claude and codex can fork a session, agy cannot; the gain is a six-line report kept out of the lead's context |
| Inline risk rating of every action with a confirmation policy (OpenHands security analyzer) | rejected 2026-11-13 (report 09): artel does not own the harness tool schemas and runs are unattended; phase 12 covers it with one-way doors and the write guard |
| Context caching across runs via `session: continue` | deferred: never tried on a live project; the brief keeps fresh sessions small instead; measure in 06-05 before deciding |
