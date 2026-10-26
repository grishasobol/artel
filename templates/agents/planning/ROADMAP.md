# Roadmap · {{PROJECT}}

The project's main plan. File owner: the super agent. Agents whose prompt grants them `edit` permission on the
main plan may change their own step statuses and add substeps under `artel lock roadmap -- …`. Other agents
propose changes in their `team/<name>/STATE.md`; the super agent moves them here. Rules: the `artel/plan` prompt
library module (`artel prompts show artel/plan`).

## Overview
One paragraph: the path from the current state to the goal in `goal.md`.

## Phases
Numbering is continuous and never restarts. Whole phases (1, 2, 3) are planned work; decimal phases (2.1, 2.2)
are urgent insertions between them and are marked INSERTED.

- [ ] **Phase 1: name** — one line saying what it delivers
- [ ] **Phase 2: name** — one line

## Phase details

### Phase 1: name
**Goal**: what this phase delivers to the project
**Depends on**: nothing
**Success criteria** (what must become true, verifiable externally):
  1. …
  2. …
**Steps** (ID `phase-step`, executor role, completion criterion):
- [ ] 01-01 · role · what to do. Done when: …
- [ ] 01-02 · role · … Depends on: 01-01

### Phase 2: name
**Goal**: …
**Depends on**: Phase 1
**Success criteria**:
  1. …
**Steps**:
- [ ] 02-01 · role · …

## Long-range plan (no steps; refine as it gets closer)
- Phase 3: …
- Phase 4: …

## Progress
| Phase | Steps done | Status | Completed |
|---|---|---|---|
| 1. name | 0/2 | not started | — |
| 2. name | 0/1 | not started | — |

## Deferred and cancelled
| Step | Reason | When | By whom |
|---|---|---|---|
