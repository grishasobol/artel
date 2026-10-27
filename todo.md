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
- [ ] 2 · Update process without extra tokens (`artel update`, `artel brief`)
- [ ] 3 · Live verification of what was only mocked
- [~] 4 · Public repository hygiene (license, history and rename done; smoke test and contribution notes open)
- [ ] 5 · Brief and bounded state: `artel brief` as the default prepare for every agent
- [ ] 6 · Run telemetry and `artel stats`
- [ ] 7 · Task-level pipeline: model per task, `verify`, `on_success`, `on_fail`
- [ ] 8 · Reactive runs: chains, `watch_paths`, persistent timers
- [ ] 9 · Evolution loop of the super agent: experiments, crystallisation, project profiles
- [ ] 10 · Model-aware prompts: portability lint, `models/` notes, measured per-model tuning

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

### Phase 2 · Update process without extra tokens
Goal: the super agent learns whether artel changed, and what, from its run prompt, not from exploratory
tool calls; the mechanical part of an update needs no model at all.
Depends on: phase 1.
Success criteria:
- `artel update --check` reports the current and the available commit and the touched areas in under a second.
- `artel update --apply` fast-forwards the submodule, runs `skills --apply` and `link`, self-checks and rolls back
  on failure, records old/new commits in `agents/state/artel-update.json`.
- `artel brief super` prints a block of at most ~10 lines; the super config uses it as `prepare` and `{{PREPARE}}`.
- `artel prompts diff <module>` shows the change between an identity's base commit and HEAD.
- The super skill tells a timer run to read the brief and skip the update step when nothing changed.
Steps:
- [ ] 02-01 · lead · `artel update --check|--apply|--done` with `artel.update: auto|manual` in config.yaml.
- [ ] 02-02 · lead · `artel brief super` and `artel prompts diff`.
- [ ] 02-03 · lead · Super skill: "Collection" step reads the brief; live session runs `artel brief` on request.
      Template config.yaml: `prepare: artel brief super`, `{{PREPARE}}` in the prompt.
- [ ] 02-04 · lead · Mock on a Linux host: update available, applied, rolled back, brief with and without changes.
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
- [ ] 06-01 · lead · Parse usage from the four harness outputs in `cmd_run` (claude stream-json `usage`,
      codex `turn.completed.usage`, agy usage line, opencode) into `runs.jsonl`; outcome from the SUMMARY
      entry and exit code. Done when: a `--dry-run` with a replayed log file writes a correct record for
      each harness (fixtures in `tests/fixtures/`).
- [ ] 06-02 · worker · `quota-history.jsonl` appended by `cmd_quota` on every full snapshot. Done when: the
      quota timer produces one line per 20 minutes on the mock.
- [ ] 06-03 · lead · `artel stats` with the metrics above and the flags; block form for the brief. Done when:
      stats over a synthetic `runs.jsonl` of 300 records match hand-computed values.
- [ ] 06-04 · lead · Super skill "Assessment": the question "how many runs produced little" is answered from
      stats, not from reading logs. Done when: the skill names the stats fields it reads.
- [ ] 06-05 · user · Correlate cache-read tokens with subscription percent on a running installation (claude
      and codex) and record the ratio in `harness/*.md`. Done when: the modules state tokens per percent.

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
      worked example, a single system message and the vendor's sampling settings. Done when: `artel prompts`
      lists the four modules, each is at most 25 lines, and every claim cites report 07 or a run.
- [ ] 10-03 · lead · Compile rule: `artel/team-design` names `models/<family>` as a source next to
      `harness/<name>`; changing an agent's model or harness counts as a prompt change and means recompiling
      from the library; the comment on "Harness and model" in `agent-prompt.md`, the group list in the super
      skill, "Where the rest lives" in the charter and the README layout name the new group. Done when: grep
      finds `models/` in each of those files, and on the mock `artel prompts status` reports an identity stale
      after its `models/` module is edited.
- [ ] 10-04 · lead · Curation path: the super skill tells the super agent to record a model-specific fix that
      held over several runs as `artel journal --type model-note` with the evidence; this file's "Working with
      the plan" notes in `CLAUDE.md` describe promoting a note into `models/*` and pruning notes a new model
      generation no longer needs. Done when: the super skill names the entry type and the condition, and
      `CLAUDE.md` describes the promotion.
- [ ] 10-05 · lead · Per-model tuning of an identity as an experiment: the "Tuning an identity" section of
      `artel/team-design` requires a hypothesis, the `artel stats` metric it should move and a run budget,
      and uses `artel experiment` for rollback. Depends on: 06-03, 09-01. Done when: the section names the
      command and the metric, and an experiment on the mock rolls an identity edit back.
- [ ] 10-06 · user · On a running installation with an opencode worker: share of runs ending `advanced`
      versus `noop` or `failed` per model, before and after applying `models/open-weights`. Depends on:
      06-01, 10-03. Done when: the numbers and the keep-or-revert decision are recorded here.

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
| Context caching across runs via `session: continue` | deferred: never tried on a live project; the brief keeps fresh sessions small instead; measure in 06-05 before deciding |
