---
name: procedures/consilium
description: A three-AI council for a plan, decision, or advice: a chair agent, Gemini (agy), and Codex (codex exec) advisers called from bash, shared memory in a minutes file, phases (triage, task alignment, reconnaissance, decision, answer), and hard rules for attributing opinions and limiting adviser permissions.
requires: [harness/agy, harness/codex]
---

# Three-AI council

You are the chair: moderate, synthesize, track the budget, and make the final decision. Advisers see neither your
context nor one another: shared memory is a minutes file that each receives in full together with an instruction saying
whose turn it is.

## Advisers
- **Gemini** via `agy -p=… --add-dir <council directory> --print-timeout 10m --output-format json`. Use model
  `gemini-4-argon-high` for complex questions and `gemini-3.8-flash-high` for inexpensive runs.
- **Codex** via `codex exec --skip-git-repo-check -s read-only -C <council directory> -m gpt-6.1-sol
  -c 'model_reasoning_effort="high"' - <turn.txt>`. Add `--search` for web reconnaissance.
- Advisers only think and read: never use `--dangerously-skip-permissions` with agy, and never allow Codex to write
  (`read-only`). A malformed command looks like an empty response: save stderr and check the exit code (modules
  `harness/agy`, `harness/codex`).
- Run adviser calls for one phase in parallel, with an internal `timeout` of 10–15 minutes each.

## Protocol
The council directory is in scratch (`scratch/consilium/<slug>/`), with a `minutes.md` file containing the original
request, agreed task wording, questions and answers, reconnaissance summary, positions by round, the decision, and
dissenting opinions. Append positions after every turn: this is the council's only memory. Give the turn instruction
in a file or through stdin, framing the role: “You are a participant in a three-AI council (chair, Gemini, Codex); we
are solving a task. Answer concisely and directly. Your turn: …”.

## Modes
| | compact (default) | deep |
|---|---|---|
| discussion rounds | up to 2 | up to 3 |
| reconnaissance | only your inexpensive sub-agents | plus one by each adviser |
| calls per adviser | 2–3 | 4–5 |

## Phases
0. **Triage.** Trivial question: one parallel iteration for each adviser (understanding plus a proposal in one
   prompt), no reconnaissance, then straight to synthesis.
1. **Task alignment.** Ask both: how they understand the task and what clarifications are needed (up to three, with
   2–4 answer options for each). Merge with your own understanding. Ask the user only if your environment permits it
   and in one batch; otherwise choose the conservative option, record the assumption in the protocol, and continue.
2. **Reconnaissance** (skip if there is nothing to investigate). Use only inexpensive-model sub-agents, up to three,
   with narrow prompts (“find out X, return a distillation”). Compress results into the protocol; do not carry raw
   dumps along.
3. **Decision.** Round A in parallel: each adviser gives a proposal with rationale based on the protocol; add your own.
   Synthesize agreement and conflicts. For substantial disagreement, run Round B with a position summary. Outcome:
   consensus; without it, the chair's recommendation plus a dissenting opinion (who disagrees and why). Do not dilute
   the decision into a compromise mush.
4. **Answer.** Give the decision, rationale, who proposed what, dissenting opinions, risks, and rejected alternatives;
   end with a short distillation linking to the relevant points and the protocol path.

## Hard rules
- Never invent an adviser's opinion. Failure, timeout, or empty response: record it in the protocol, continue with the
  remaining members, and explicitly say who dropped out in the end.
- Attribute opinions honestly (“Gemini proposed…”, “Codex objected…”); do not present your own as collective.
- Do not extend the mode's round limit.
