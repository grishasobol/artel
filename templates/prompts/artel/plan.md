---
name: artel/plan
description: How planning works in artel after the GSD pattern: the super agent's main planning/ files (ROADMAP, STATE, SUMMARY, VERIFICATION), agents' team/<name>/ spheres, rights over the main plan, the format of phases and steps, evidence, deviations, and consolidating feedback.
---

# Planning: two levels, one owner

The design is based on GSD (get-shit-done): a roadmap with phases and success criteria, STATE as memory between
sessions, SUMMARY with deviations from the plan, VERIFICATION working backward from the goal, and plans as
historical artifacts. artel differs in that files exist at two levels and each file has one author.

| level | files | author | readers |
|---|---|---|---|
| project | `planning/ROADMAP.md`, `STATE.md`, `SUMMARY.md`, `VERIFICATION.md` | super agent | everyone |
| agent | `team/<name>/PLAN.md`, `STATE.md`, `SUMMARY.md`, `VERIFICATION.md` | this agent | super agent, reviewers |

On each iteration, the super agent collects results (SUMMARY), feedback (STATE), and checks (VERIFICATION) from the
agent spheres and consolidates them into the main files. Agents therefore need no locks: they never write to the same
file. The exception is `edit` permission in the agent prompt (see below).

## ROADMAP.md (main plan)
- **Overview**: one paragraph describing the path to the goal from `goal.md`.
- **Phases**: a checkbox list. Numbering is continuous; whole numbers are planned work, decimals (2.1, 2.2) are
  urgent insertions marked INSERTED. Completed phases can be collapsed into `<details>`.
- **Phase details**: Goal · Depends on · Success criteria (2–5 observable statements that can be checked externally,
  phrased as "X works / exists / produces Y") · Steps.
- **Step**: `- [status] PP-SS · role · what to do. Done when: … Depends on: PP-SS`. ID `01-02` = phase 1,
  step 2; never reuse it. One step has one executor role; a step should take 1–3 agent runs, otherwise split it.
- **Statuses**: `[ ]` not started · `[~]` in progress `(who, since)` · `[x]` done `(evidence: …)` · `[!]` blocked
  `(reason)` · `[-]` cancelled `(reason)`.
- **Progress**: phase table. **Deferred and cancelled**: table with reasons.
The near horizon (1–2 phases) is broken down into steps; the distant horizon has only phase names and goals.

## Agent PLAN.md
The agent takes its roadmap steps and breaks them down into one-run tasks: `01-02.a`, `01-02.b`, each with a
"done when" criterion. Statuses and evidence are the same. The agent edits this file freely, without locks.
Completed tasks are not rewritten: new reality means new tasks.

## STATE.md (both levels)
A short current memory, not history. At the project level: direction, position, agent team, active decisions,
blockers, quotas, things to check, and continuity. At the agent level: position and "next run should do", blockers,
proposals to the super agent, decisions in the sphere, and questions for the user. The agent's proposals section is
its channel of influence on the main plan: the super agent reads it each iteration and marks each line "accepted" or
"rejected, because …".

## SUMMARY.md (both levels)
At the agent level: append-only run entries (`artel summary add`) with status, work done with evidence, deviations
from the plan and why, problems, and time spent. At the project level: a phase summary assembled by the super agent:
work done, decisions and deviations, and readiness for the next phase.

## VERIFICATION.md (both levels)
Verification works backward from the goal: take the success criteria for a phase (or task) and look for evidence for
each one: the file exists and has content, the connection between parts really works, and the test passes. The
executor's self-report is not evidence. Status: `passed` · `gaps_found` · `human_needed`; when there are gaps, list
critical and non-critical ones and propose corrective steps. The reviewing agent writes to its file; the super agent
consolidates it into the main file and creates corrective steps in ROADMAP.

## Rights over the main plan
The right is recorded in the agent identity, in the "Powers and boundaries" section, as "Rights over the main plan:
read" or "… edit". This is the only source of truth; configuration does not duplicate it.
- `read` (the default for a new agent): the agent reads `planning/` and writes only in its sphere; it proposes
  changes through its `STATE.md`.
- `edit`: the agent may change statuses of its steps and add substeps in ROADMAP under
  `artel lock roadmap -- <command>`. No one except the super agent changes the structure (phases, IDs, criteria,
  and horizon).
The super agent grants `edit` to agents whose steps are often completed between its iterations and whose SUMMARY
entries reliably include evidence.

## Deviations from the plan
Minor deviations (a path bug, a different tool): make them and record them in the SUMMARY entry. Do not make changes
that alter steps, criteria, or another agent's area: propose them in `STATE.md` and finish the task within the plan.
For urgent matters, use `artel escalate`.

## Evidence rule
Use `[x]` only with a trace another agent can verify: a commit hash, test command and result, registry entry, or URL.
Write the done criterion so that it can be checked mechanically wherever possible.

## Common mistakes
- `[x]` "by feel": fix it with a done criterion and evidence.
- Step "do everything else": split it into 30–60 minute tasks.
- A proposal to change the roadmap written in SUMMARY rather than STATE: the super agent will not find it.
- Editing the main file without `edit` permission or without `lock roadmap`: another person's lines get overwritten.
- Rewriting a completed step retroactively: the history of decisions is lost.
