---
name: artel/team-design
description: How the super agent designs an agent team and assembles identities from the prompt library: roles and slots, harness and model selection, compiling one optimized prompt per agent (sources, distillation, invariants, provenance), a short run prompt, tuning from SUMMARY, and tuning after artel updates.
requires: [artel/config]
---

# Agent teams and their identities

## An identity is a compiled prompt
`agents/agent-<name>.md` is the only text by which a worker agent operates: who it is, where it belongs, how to
work in artel, what role to play, what to know about the project, what it may and may not do, what tasks exist, and
what "done" looks like for each one. You compile it once from the prompt library and your own project knowledge,
removing everything unnecessary and making the parameters specific. The agent then runs dozens of times from this
text, so every unnecessary line is multiplied by the number of runs, while every missing line produces a bad run.

The run prompt assembled by `artel run` is short: agent name, identity file, charter, task name, and window. It is not
written or edited; all substantive content belongs in the identity. Editing an identity does not require re-registering timers.

## Prompt library
It lives in `artel/templates/prompts/`, is read directly, and is neither copied nor edited (it is updated with artel).
The catalog with descriptions is `artel prompts`; the module text is `artel prompts show <name>`.

| group | modules | purpose |
|---|---|---|
| `artel/` | `worker`, `plan`, `channel`, `config`, `environment`, `delegation`, `team-design` | artel system mechanics |
| `roles/` | `leader`, `developer` | how to act in a role, without artel-specific details |
| `harness/` | `claude`, `codex`, `agy`, `opencode` | how to run a harness headlessly: commands, flags, models, accounting, pitfalls |
| `procedures/` | `consilium` | multi-step procedures assembled from harness modules |

A module has frontmatter with `name`, `description`, and `requires` (modules without which it is unclear). Store
project knowledge that you write yourself and reuse in several identities (builds, tests, data, your security rules)
in `agents/prompts/<name>.md` with the same frontmatter: `artel prompts` shows it alongside the library.

## Compiling an identity
1. **Define the agent**: role, area (roadmap steps, folders, and files), harness and model, slot, and tasks.
2. **Choose sources.** Usually: `artel/worker` (for everyone), the role module, the harness module the agent uses
   (its tool details), `artel/delegation` and worker harness modules if the agent delegates, and project modules from
   `agents/prompts/`. Expand `requires`.
3. **Distil.** From each source, take only what this agent needs for its tasks. From `artel/worker`, an agent without
   `edit` permission does not need `lock roadmap`, and an agent without permission to ask does not need `ask`. From
   a harness module, a worker does not need session sections if it does not manage sessions. Make it specific:
   instead of "thresholds in the identity", write the thresholds; instead of "default worker", write the model and
   fallback for this project.
4. **Do not shorten invariants**: the run protocol and evidence rule (`artel/worker`), charter prohibitions
   (`artel/charter.md` is read by the agent itself, but repeat the rules about sub-agents and other agents' areas
   as they apply to its tools), and the tasks' done criteria.
5. **Record provenance** in the identity frontmatter: `sources` (module list), `artel` (the commit shown by
   `artel env`), and `compiled` (date). `artel prompts status` then reports which sources changed since that point.
6. **Check length.** Aim for 80–150 lines. More means the role should be split or that you pasted a whole module
   instead of a distillation. Under 50 usually means the project knowledge is insufficient.
7. **Dry run**: `artel run <agent> --task <name> --dry-run` shows the command and run prompt.

Structure (the skeleton is made by `artel team init <name>` from `artel/templates/agent-prompt.md`):
1. **Who you are and where**: name, project, sphere, harness, and model with tool-specific details.
2. **How to work**: a distillation of the run protocol and commands from `artel/worker`.
3. **Role**: a distillation of the role module with project parameters (who to delegate to, which models, quota thresholds).
4. **What to know about the project**: facts needed to do the task correctly: data locations, build and verification
   commands, terms, and accepted decisions. A link to a project file is better than a retelling.
5. **Powers and boundaries**: what is allowed, what is forbidden, the right over the main plan (`read`/`edit`), and
   the policy for quotas and user questions.
6. **Tasks**: one `### <name>` subsection per task: what to do, the done criterion (checkable by command or file),
   artifacts and commit, and what to do if there is no work. Names match the `task`/`tasks` keys in `config.yaml`.

## Designing the agent team
- Start with the smallest team: one executor and one reviewer plus you are often enough. Add a role when recurring
  work of another type or a conflict of areas becomes visible.
- A role is a plan area plus an operation type plus a set of project files. Write areas must not overlap.
- Production and acceptance are different roles or different tasks for one agent. The acceptor checks evidence and may
  return a step to `[~]` with comments in the journal.
- Search and information gathering are a separate cheap role (Gemini Flash, luna); decisions and code use a strong model.
- As an expensive-model leader, an agent on fable or sol writes little itself: it delegates subtasks and sub-agents to
  cheap workers, then checks and finishes them (modules `roles/leader`, `artel/delegation`). This combines strong
  judgment with cheap execution.
- Keep names short and Latin: agents `builder`, `reviewer`, `scout`; tasks `implement`, `review`, `research`.
- **Slots.** Agents in one slot run strictly one at a time, so one slot for the whole team makes the whole team a
  queue. Share a slot only for agents writing to the same files; reading, searching, checking, another repository,
  and worktrees in `scratch/` get their own slots. Agents in different slots that commit to one repository use
  `artel lock <repo> -- git …`. `artel schedule` shows load and warns when everyone is in one slot.
- Creation: `artel team init <name>` makes `team/<name>/` and an identity skeleton; then add the entry to
  `config.yaml` (harness, model, slot, and scheduled tasks).

## Harness and model selection (guidelines; check `environment.md`)
| work | harness / model | why |
|---|---|---|
| web search, candidate collection, summaries | agy Gemini Flash, codex luna | cheap, fast, separate quota |
| routine edits, tests, scripts | codex luna (`gpt-5.6-luna`, `gpt-6-luna`) | cheap, follows instructions well |
| complex code, architecture, debugging | codex `gpt-6.1-sol` (or `gpt-6-astra`, expensive), claude opus/fable, agy `gemini-4-argon` | solution quality |
| review, acceptance | claude sonnet/opus or codex sol, a different harness from the author | a second view from another model |
| management (you) | claude opus/fable | long context, file work |
Subscription quotas are independent: distribute work so no single window becomes the bottleneck. agy has two groups
with separate limits (Gemini; Claude and GPT-OSS); the second is a reserve pool for review when Claude's weekly window
is near its limit. Spend Claude more sparingly than the others: its window is shared with the user's interactive work.

## Tuning an identity
Triggers: a recurring problem in SUMMARY, STATE, or the journal (not a one-off); `artel prompts status` shows that
identity sources changed after an artel update; models or quotas changed.
1. `artel snapshot agents/agent-<name>.md --note "why"`.
2. Make a minimal, targeted edit, one change at a time. New recurring work is a new task in the "Tasks" section and
   a `tasks` entry, not a paragraph in the prompt. Update `artel`/`compiled` in the frontmatter.
3. Write a `prompt-change` journal entry: what changed, why, and which SUMMARY entries should be used to check the effect.
4. In your `team/super/STATE.md`, note that the next 1–2 agent runs must be checked.
5. If it got worse: restore the version from `history/` and record it.
The same applies to `skills/super/SKILL.md` and `concierge.md`, with a user notification through `notify`.

## Run parameters in `config.yaml`
Usually `prompt` is unnecessary. Set it only for parameters of a particular run (mode, item-count limit, or special
handling of `{{PREPARE}}` data) and keep it short. Several tasks with different schedules are described in `tasks`
(module `artel/config`).
