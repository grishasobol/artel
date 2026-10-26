# artel · notes for developing this repository

This file is for a harness session working on the artel system itself (this repository), not on a user
project. Read `README.md` for what artel is and how the repository is laid out, `charter.md` for the
invariants every agent obeys, and `todo.md` for the work plan. Do not restate those here; keep this file to
what a developer needs and cannot derive from them.

## Language
- Everything in the repository is in English: code, comments, prompts, templates, docs, commit messages,
  journal and plan entries. The one allowed exception is the word *артель* in the README etymology.
- The user may talk to you in Russian; answer in their language, write files in English.
- Check before committing: `git ls-files | xargs grep -lE "[А-Яа-яЁё]"` must print only `README.md`.

## What is where (development view)
- `bin/artel` · the whole CLI in one python3 file (stdlib + PyYAML, imported lazily). One `cmd_<name>`
  function per subcommand; the parser is built at the bottom of the file; the module docstring is the text of
  `artel help` and must list every subcommand.
- `install/` · bash for the Incus host (`provision-base.sh`, `artel-up.sh`, `auth-transfer.sh`) and for the
  inside of the container (`install/inside/`, `apply-auth.sh`). Every script starts with a usage comment;
  `artel-up.sh` prints it with `sed -n 2,15p`, so keep that line range in sync when editing its header.
- `templates/` · copied or symlinked into a user project by `artel init`, `artel team init` and
  `artel skills --apply`. `templates/prompts/` is the prompt library the super agent reads in place.
- `.agents/skills/artel-create/` · the installer skill; `.claude`, `.codex` and `.opencode` hold symlinks to
  it. Edit the canonical copy only.
- `docs/install.md` · part 1 is the installer's step-by-step script, part 2 describes the super agent.
  The `artel-create` skill reads it in full, so its section numbers are referenced from the skill and from
  `README.md`.

## Conventions that are easy to break
- Placeholders in templates are `{{UPPER_CASE}}` (`{{PROJECT}}`, `{{AGENT}}`, `{{DATE}}`, `{{PREPARE}}`,
  `{{WINDOW_END}}`, `{{BUDGET_MIN}}`, `{{HARD_LIMIT_MIN}}`, the `{{TASK_*}}` family, and the identity
  sections in `templates/agent-prompt.md`). `bin/artel` substitutes them by exact name; renaming one means
  changing the substitution code, every template that uses it and `docs/install.md`.
- Prompt modules are referenced by name across files: `artel/worker`, `artel/plan`, `harness/claude`,
  `roles/leader` and so on, and `templates/agent-prompt.md` names their sections. Renaming a module, a
  section heading or a file in `templates/prompts/` requires a grep for the old name over the whole
  repository.
- Environment variables are prefixed `ARTEL_` (`ARTEL_HOME`, `ARTEL_AD`, `ARTEL_AGENT`, `ARTEL_USER`,
  `ARTEL_URL`, `ARTEL_LAYOUT`, …). The container user, home and image name are defaults, not constants:
  read them from flags, image properties or `$HOME`, never hard-code `/home/artel` in new code.
- Secrets are never read or printed, in code or in prompts: `auth.json`, `~/.codex/auth.json`,
  `~/.claude/.credentials.json`, provider keys. Mention paths only. `templates/auth.json` uses the literal
  `REPLACE_ME`, and `apply-auth.sh --check` relies on that literal.
- Nothing in this repository is project-specific: no private host names, project names, session links or
  personal data. The history was squashed once to remove them; do not reintroduce any.
- Text written for agents (prompts, skills, charter) is written in terms of results and verifiable checks,
  not step lists; evidence means a command and its output, a commit or a path.

## Checks
Run on any machine (macOS is fine) before every commit:
```
python3 -m py_compile bin/artel
bash -n install/*.sh install/inside/*.sh
bin/artel help >/dev/null
git ls-files | xargs grep -lE "[А-Яа-яЁё]"      # expect: README.md only
```
The behavioural check needs a Linux host because `artel` depends on `systemd --user`, Incus and the four
harnesses. The mock used so far (todo.md step 01-13): clone, create an empty project directory, export
`ARTEL_AD` to its `agents/`, then run `artel init`, `artel prompts`, `artel skills --apply`, `artel team init
<name>`, `artel run <agent> --dry-run`, `artel schedule`, `artel register` without `--apply`, `artel cheatsheet`,
and confirm that nothing generated contains Cyrillic. A reproducible `tests/smoke.sh` for this is open
work (todo.md step 04-03); when it exists, run it instead and cite its output.

A change to `bin/artel` that is meant to be string-only (translation, wording) is verified by comparing the
AST modulo string literals; a change in logic needs the mock run.

## Working with the plan
- `todo.md` is the plan of this repository and follows the `artel/plan` module: phases with success
  criteria, steps with ids `PP-SS`, statuses `[ ]`, `[~]`, `[x]`, `[!]`, `[-]`. Mark a step `[x]` only with
  evidence another person can check, written into the step.
- Record where executors (sub-agents, other harnesses) failed and why; that record is more valuable than the
  fix itself and feeds the executor tables in `templates/prompts/roles/leader.md`.
- Deferred and rejected ideas go into the table at the end of `todo.md` with a reason, not into comments.

## Agents and sub-agents in this repository
- The charter's sub-agent rule applies here too: built-in sub-agents only on cheap models (`sonnet`,
  `gpt-5.6-luna`, `gemini flash`) with effort at most `high`, model named explicitly. A strong model on a
  subtask is a separate harness process, not a sub-agent.
- Delegation and review follow `templates/prompts/roles/leader.md`: one directory per worker, a verifiable
  "done" criterion, the reviewer reads the diff as a stranger and runs the checks themselves.
- Do not spend subscription quota on exploratory tool calls that a grep answers.

## Git
- `main` is the only branch; history starts at the public initial commit. Do not rewrite it.
- Remote `origin` is the public GitHub repository; other remotes may be private mirrors. Do not push
  anything that violates the "nothing project-specific" rule above.
- Commit messages: one line in English stating what changed and why; evidence for plan steps goes into
  `todo.md`, not into the message.
- `__pycache__/`, `*.pyc` and `.DS_Store` are ignored; nothing else is generated in the tree.

## Target platform vs. development host
- Runtime target: Ubuntu 24.04 inside an Incus container with `systemd --user`, python3 with PyYAML, and
  the harnesses `claude`, `codex`, `agy`, `opencode` installed by `install/inside/provision.sh`.
- Development host may be macOS without PyYAML: `py_compile` and `artel help` still work because YAML is
  imported lazily; any command that reads `config.yaml` will not. Do not add top-level imports beyond the
  standard library.
