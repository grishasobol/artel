# artel · work plan

This file is kept the way artel keeps a plan (module `artel/plan`): phases with success criteria, steps with
ids `PP-SS`, statuses `[ ]` not started · `[~]` in progress (who, since) · `[x]` done (evidence) · `[!]`
blocked (reason) · `[-]` cancelled (reason). A step is `[x]` only with evidence another person can check:
a commit, a command and its output, a path. Finished phases are folded into `<details>`.

## Overview
Make artel a public project: readable in English by any developer, free of the author's private data,
with a documented update path for running installations, and verified on a clean Linux host.

## Phases
- [~] 1 · Publication readiness (since 2026-10-25)
- [ ] 2 · Update process without extra tokens (`artel update`, `artel brief`)
- [ ] 3 · Live verification of what was only mocked
- [~] 4 · Public repository hygiene (license, history and rename done; smoke test and contribution notes open)

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

## Deferred and cancelled
| item | reason |
|---|---|
| Mechanical prompt composition by artel (`artel prompts compose`) | rejected: the super agent distils identities by hand; artel provides the library and the catalog only |
