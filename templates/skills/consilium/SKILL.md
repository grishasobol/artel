---
name: consilium
description: Consilium of up to three AI models (Claude, GPT via codex, Gemini via agy) that discuss one task in a shared space and return one agreed answer, plan or piece of advice. You are the operator, not a participant: you pick the models, start a driver script that runs the whole discussion without spending your tokens, pass the consilium's questions to the user, steer it at checkpoints and deliver the final answer. Use when the user runs /consilium [deep] <request>, asks to convene a consilium or a council of several AIs, wants an answer agreed by several models, or when you yourself need an independent opinion on a hard question in the middle of other work.
argument-hint: [deep] <request>
---

# Consilium

A consilium is two or three models, each in its own harness session that lives for the whole consilium, discussing
one task until the first of them (the lead) writes a final answer that the others approve. The discussion is run by
the script `consilium.py` that lies next to this file; the models talk in a shared space on disk.

You are the **operator**. You are not a participant: you add no opinion of your own and you never read the space.
You choose the line-up and the limits, start the script, answer its events and deliver the result. Everything you
read during a consilium is the output of `consilium.py wait`: an event of one screen. That is what keeps a long
discussion cheap for you.

The **user** of a consilium is whoever owns the task. It may be a person talking to you, or you yourself: an agent
that convened the consilium to get an independent opinion while doing other work.

`C` below stands for `python3 <directory of this skill>/consilium.py`; `C help` prints every command and flag.

## Before the start: line-up, limits, task

The preparation is finished when you can name two or three participants in speaking order, each as
harness, model and effort, and a reason to believe their quotas will last.

- **What is available.** `C probe` prints the installed harnesses, their model lists and a free quota snapshot
  (5-hour and weekly windows). Details of a harness, its models and its quota accounting are in the harness notes:
  the skills `codex` and `agy`, or in an artel project `artel prompts show harness/claude|codex|agy`.
- **Different vendors, different models.** Prefer one participant per vendor: opinions are more independent and the
  load spreads over the quotas. Two participants from one harness are acceptable only when another harness is
  missing or its quota is nearly used up, and then on different models. Your own harness may be a participant: it
  gets a separate session that does not see your conversation.
- **The lead is first and the strongest.** The first participant words every proposal and the final answer, so give
  that place to the most capable model of the line-up.
- **Models and effort follow the task and the word `deep`.** Without `deep`: workhorse models at effort `high`.
  With `deep` at the start of the request: the strongest model of each vendor at `high` or above, more working time,
  rarer checkpoints. A question that needs neither clarification nor research: `--quick` and cheaper models; that
  choice is yours.
- **Quota.** A quick run costs each participant two or three turns; a full run usually costs six to twelve turns
  plus research, with the whole discussion reread on every turn. Leave out a harness whose 5-hour window is above
  about 80% used or whose weekly window is above about 90%, or give it a cheaper model. With fewer than two usable
  participants there is no consilium: say so and offer a single-model answer instead.
- **Limits are yours to set, per task.** Nothing in the script caps the number of turns. You set what the task
  deserves through the flags below and through `--rules` (free text shown to every participant: message length,
  how deep the research may go, what is out of scope, the language of the answer). The script only guards against
  hanging: 60 minutes of working time for the whole consilium and 30 minutes for one turn by default
  (`--total-min`, `--turn-min`); time spent waiting for you or for the user does not count.
- **Access is yours to set.** By default participants are read-only: they read the directories you name with
  `--read-dir`, search the web, and change nothing. `--no-web` forbids the web. `--access full` removes the
  technical restrictions and is acceptable only inside an isolated container where a harness sandbox cannot start.
  A Claude participant runs lean: file reading, web and sub-agent tools only, without the MCP servers, skills and
  settings of your setup, so do not plan on a participant using them.
- **Sub-agents of participants run on cheap models only.** This is the default (`--subagents cheap`) and is stated
  to every participant as a hard rule; `--subagents off` forbids them. Never relax it in `--rules`: a sub-agent on
  a strong model burns a subscription window in minutes.
- **The task file** is all the participants know: they do not see your conversation. Write the user's request word
  for word, then the context it depends on (facts, constraints, paths inside the readable directories, what has
  been tried), who the user is and what form of result is expected. No secrets and no credentials.

```bash
C start <dir> --task-file <dir>/../task.md \
  --member gpt=codex:<model>:<effort> --member claude=claude:<model>:<effort> --member gemini=agy:<model-with-effort> \
  --read-dir /abs/project --checkpoint-every 2 --rules "..."
```
`<dir>` is a new directory in your scratch area. The order of `--member` is the speaking order. For agy the effort
is part of the model slug, so the third field is omitted.

## While it runs: events

`C start` returns at once; the driver works in the background. `C wait <dir>` blocks until the driver needs you
and prints the event; exit code 2 means it is still working after `--timeout` seconds (default 540, under the
command limit of most harnesses), so call it again or run it as a background command if your harness has those.
Every event ends with the exact replies it accepts. `C status <dir>` shows stage, time and spend without the space.

| event | what happened | what you do |
|---|---|---|
| `questions` | the participants agreed on questions for the user | get the answers (below), `reply answer --say-file F` |
| `checkpoint` | every N circles the lead reports where things stand | `continue`, `hurry`, or `finalize` |
| `request` | the lead asks you for something, usually more time | `continue --extend MIN`, or `continue --say "no, because"` |
| `research-request` | they want another parallel research round | `approve` or `deny --say REASON` |
| `deadline` | the working time is used up, nothing runs | `continue --extend MIN`, `finalize`, or `abort` |
| `collapsed` | one participant is left | `finalize` (it answers alone) or `abort` |
| `error` | the driver failed | `continue` retries the step; `finalize`; `abort` |
| `final` | the answer is approved, or was closed by you | deliver the result |

At any moment, without waiting for an event: `reply say --say TEXT` posts your message to the space, `reply hurry`
tells everyone to converge, `reply finalize` and `reply abort` end the discussion.

**Questions for the user** go through the channel you actually have with the user, and the result is the same in
every channel: each question answered, the answers written to a file and passed to `reply answer`.
- If your harness has a quiz tool (AskUserQuestion in Claude Code, its analogue elsewhere), use it: one batch,
  the suggested answers as options.
- In a chat channel (a messenger, an artel `ask`, plain terminal text) send the questions as one numbered message
  with the suggested answers and wait for the reply there.
- If you are the user, answer from what you know for certain and say so in the answer; take to the person only
  the questions that the person alone can answer.
- If nobody can be asked (an unattended run), choose the conservative answer for each question and mark it in the
  answers as your assumption.

**Checkpoints are where you steer.** You judge by the lead's report alone. Converging: `continue`. Drifting away
from the task or arguing about a side issue: `continue --say` with the correction. Deadlocked, or enough has been
spent for this task: `hurry`, which obliges the lead to put both positions into the final answer; if the next
report shows no movement, `finalize`: the lead writes the final answer at once, with the disagreements attributed,
and no approval round follows. A request for more time you may grant or refuse: weigh the remaining quota and what
the task is worth, and say the reason when refusing.

## The result

The `final` event carries the answer, how it was reached (approved by whom, or closed by you without approval),
who dropped out and why, and turns, time and tokens per participant.
- Give the user the final answer as the consilium wrote it, in the user's language. Opinions stay attributed to
  the participants; anything you add is marked as the operator's remark.
- Say plainly if a participant dropped out or if the answer was not approved by everyone.
- Name the path to `<dir>/space` for those who want the whole discussion, and the cost from the event.
- If you convened the consilium for yourself, use the answer as an outside opinion: weigh it, do not obey it.

## Rules without exceptions

- Never invent a participant's opinion or a user's answer. A participant that fails twice in a row leaves, the
  script says so in the event, and you repeat it to the user.
- Do not read `<dir>/space` or `<dir>/turns` while the consilium runs and do not take part in the discussion; your
  only inputs are events and your only outputs are replies.
- Do not start a consilium with a single model, do not put a strong model on a sub-agent, and do not use
  `--access full` outside an isolated container.
- Credentials are never read, printed or put into the task file or the rules.
