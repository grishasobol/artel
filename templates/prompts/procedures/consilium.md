---
name: procedures/consilium
description: Pointer to the consilium skill: two or three models (Claude, GPT via codex, Gemini via agy), each in one session for the whole consilium, discuss a task in a shared space under a driver script; the agent that convenes it is the operator, who picks the line-up and limits, answers the script's events and delivers the answer.
requires: [harness/claude, harness/codex, harness/agy]
---

# Consilium

The procedure lives in the `consilium` skill: `skills/consilium/SKILL.md` in a user project (the template is
`artel/templates/skills/consilium/`), with the driver `consilium.py` next to it. Read the skill before convening a
consilium; this module only states what an identity must keep from it.

- **Roles.** The agent that convenes a consilium is its operator and not a participant: it adds no opinion and
  does not read the discussion. Participants are two or three harness sessions, one per model, alive for the whole
  consilium; the first in the speaking order is the lead and should be the strongest model.
- **The script runs the discussion.** `consilium.py start` launches a background driver; `consilium.py wait` returns
  one-screen events (questions for the user, checkpoint report of the lead, request for more time or research,
  deadline, final answer); `consilium.py reply` answers them. The operator spends tokens only on events.
- **Line-up.** `consilium.py probe` shows harnesses, models and quota windows. Prefer different vendors and models;
  model strength and effort follow the task and the word `deep`; `--quick` is the operator's choice for a simple
  question. Fewer than two usable participants: no consilium.
- **Limits and access are set by the operator per task** (`--rules`, `--read-dir`, `--no-web`, `--total-min`,
  `--turn-min`, `--checkpoint-every`). Participants are read-only by default; their sub-agents run on cheap models
  only, as the charter requires.
- **Questions for the user** go through the channel the agent has (`artel/channel` in a run, a quiz tool in a live
  session); an agent that convened the consilium for itself answers what it knows for certain and marks assumptions.
- **Result.** The final answer is delivered as written, opinions attributed to participants; the operator reports
  who dropped out, whether the answer was approved by everyone or closed by the operator, and the cost.
