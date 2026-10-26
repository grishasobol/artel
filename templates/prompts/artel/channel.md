---
name: artel/channel
description: How artel agents communicate with the user: when it is allowed, the two request types (message and question with waiting), format, the artel notify and artel ask commands, handling rejection and no answer, and quiet hours.
---

# User channel

The user's time is the system's most expensive resource. A request is justified when the question cannot be resolved
from `goal.md`, `planning/`, `environment.md`, the journal, and common sense, and when the answer changes the work.

## Two channels
- **Claude concierge session (`claude`).** File channel `agents/channel/`: the agent puts the request in the inbox,
  the concierge reviews it, shows it to the user, and writes the answer to the outbox. The concierge may reject an
  unclear request.
- **Telegram (`telegram`).** Direct delivery to the user's chat. Questions through Telegram are possible only if a
  bot is dedicated to artel (`channel.telegram.dedicated_bot: true`).

Without `--via`, the script chooses the concierge if it is alive, otherwise Telegram; for `ask`, Telegram is possible
only with `dedicated_bot: true`, otherwise exit code 2 (configuration error). Explicitly: `--via claude|telegram`.
Telegram accepts a reply to the question or a message marked `#qXXXX`; `--any-reply` accepts any message after the
question.

## Two request types
1. **Message** — no waiting. A report, warning, or fact. Work can finish after sending it.
   ```
   artel notify --title "Daily report" - <<'TXT'
   Done: S-012, S-013 (commits a1b2c3, d4e5f6). Stuck: S-014, no access to API X.
   Spend: Claude week 41%, Codex week 19%.
   TXT
   ```
2. **Question** — wait for an answer for several minutes (`--timeout`, 5 minutes by default; the agent identity sets
   the limit).
   ```
   artel ask --title "Library choice for S-020" --timeout 5m \
     --options "A: sqlite | B: postgres" --default "I'll use A" - <<'TXT'
   Step S-020 needs storage. A is simpler and already in the project; B is needed if multi-user access is planned
   (the goal does not say that).
   TXT
   ```
   Exit codes: `0` answer on stdout · `3` concierge rejected it (reason on stdout: fix and retry once) · `124` no
   answer · `125` quiet hours (question not asked) · `2` configuration error. `--urgent` bypasses quiet hours and
   marks the request urgent. `--default` is required by the charter (the script does not require it): what you will
   do without an answer. If there is no answer, do exactly that and record it in your STATE/SUMMARY and the journal.

## Format of a good request
- Title: 3–7 words, stating the subject.
- Context: 2–3 sentences without internal jargon. Which plan step, and what is already known.
- Core: one question or one message. Two questions mean two requests, or one numbered request if inseparable.
- Answer options, if any, and your recommendation.
- What happens without an answer (for a question).
Length: short enough to read on a phone in 20 seconds. Put details in your SUMMARY entry and link to it.

## Who may do what
- Worker agents: `notify` is always allowed, but do not spam (at most one report per run, usually none). `ask` is
  allowed only if the agent identity permits it, the question blocks work right now, and the run cannot finish with a
  status mark.
- Super agent: reports according to the mode in `goal.md`, questions in batches.
- Concierge session: responsible for delivery and format; it does not ask agents questions itself.

## What not to do
- Do not ask what is already stated in `goal.md`. Do not ask permission for routine work.
- Do not ask a question and leave silently: `ask` waits itself and exits with a code.
- Do not repeat the same question more than once a day. If there is no answer, that is also an answer: act according
  to `--default` and leave the question for the super agent in your `STATE.md`.
- During quiet hours, `ask` without `--urgent` is not made (code 125), while `notify` is delivered quietly (Telegram
  without sound, to the concierge's inbox). Do not ask during quiet hours without `--urgent` unless it is urgent by
  the criteria in `goal.md`.
