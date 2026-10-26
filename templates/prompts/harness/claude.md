---
name: harness/claude
description: How to run Claude Code headless as a worker or consultant: command, models and effort, permissions, token and quota accounting, sessions, live sessions with background tasks, and restrictions on expensive sub-agents.
---

# Claude Code (`claude`) as a worker

Tested with `claude` 2.1.3xx (2.1.310, 2026-10-25), Linux. Paid through a Claude subscription (5-hour and 7-day
windows; Fable has a separate weekly window within the overall one). Quota: with a claude.ai session login,
`claude -p "/usage" --output-format json` returns window percentages without an agent turn or charge (model windows
are visible too); with token login via `claude setup-token` (standard in containers), `/usage` never returns
percentages (the token lacks `user:profile` scope and the quota server returns 403), leaving the
`anthropic-ratelimit-unified-*` headers from a probe request to haiku (`max_tokens: 1`, about 25 tokens): 5-hour and
7-day windows, without model windows.

## Single-turn call
```bash
claude -p "<prompt>" --model sonnet --effort high --dangerously-skip-permissions \
  --output-format json --add-dir /abs/path/project </dev/null 2>err.txt
```
- `-p` prints the response and exits. Do not put long or untrusted text in quotes: put it in a file in the project and
  reference its path, or pass it through stdin (`claude -p < prompt.txt`).
- Model aliases are `haiku | sonnet | opus | fable` or a full ID. Effort is `low | medium | high | xhigh | max`;
  `xhigh` and `max` are available only for opus and fable.
- Without `--dangerously-skip-permissions` in headless mode, any tool that writes or runs a command waits for approval
  that nobody will provide. In an isolated container, the flag is safe and required.
- `--output-format json` returns one JSON line: `result` (response text), `session_id`, `total_cost_usd`, `usage`
  (`input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`), `num_turns`, and
  `is_error`. Check `is_error` and the exit code.
- `--max-budget-usd N` limits the run's dollar spend, guarding against a worker loop (`--max-turns` was removed in
  2.1.3xx; in `config.yaml` the field is `max_budget_usd`).
- `--append-system-prompt-file <file>` adds a system prompt without replacing the built-in one. This is how the
  concierge is launched (`concierge.md`).
- `--add-dir` grants access to directories outside cwd; Claude respects cwd, unlike agy.

## Sessions
- Save `session_id` from the JSON; resume with `claude -p --resume <id> "..."`. `--continue` takes the newest
  session and is unsafe in automation: parallel runs race.
- Session transcript: `~/.claude/projects/<hyphenated-path>/<session_id>.jsonl`, with `message.usage` in each assistant
  turn. This is the source for session spend.
- Context auto-compaction: `CLAUDE_CODE_AUTO_COMPACT_WINDOW=<tokens>` sets the threshold at which context is compacted
  (for example, 400000 for 40% of the window). Keep inexpensive long runs at 300000–400000: for long sessions, the
  main cost is rereading the large context on every step.

## Live session: background tasks
A normal `claude -p` exits after the last turn and kills anything the model sent to the background (Claude Code itself
sends commands longer than 10 minutes to the background and waits for notification). If a worker needs long builds or
tests, run streaming mode with stdin left open:
```bash
claude -p --input-format stream-json --output-format stream-json --verbose \
  --model opus --effort xhigh --dangerously-skip-permissions
```
Pass the prompt as `{"type":"user","message":{"role":"user","content":"..."}}` on stdin; read events from
stdout, and close stdin only when the turn is complete and no background tasks remain. Use this for long-running
workers; for one-off calls, it is enough to understand why simple `-p` “cuts off” a build.
Tell the worker in its prompt: “do not end the turn with the word ‘waiting’ if nothing is running in the background.”

## Sub-agents
Built-in sub-agents (Agent tool) inherit the parent model without an explicit `model`, and a sub-agent on `opus` or
`fable` can consume a five-hour window in minutes. Keep them on `sonnet` or `haiku` with effort no higher than `high`,
and tell a worker on opus/fable explicitly: “launch sub-agents only with `model: sonnet`.” A strong model on a
subtask is a separate `claude -p` process or another harness. Sub-agent spend is included in the parent's `usage`.

## Model selection
| task | model / effort |
|---|---|
| code search, summary, checklist review | haiku or sonnet, medium |
| precise-spec edits, tests, refactoring in one file | sonnet, high |
| architecture, complex debugging, review of someone else's work | opus, high or xhigh |
| tasks requiring maximum depth when the budget allows | fable, xhigh |

Fable spends both the overall weekly quota and its own; `/usage` shows the “Current week (Fable)” line (only with
claude.ai session login; with a token, use the overall week). When it is near the limit, move demanding tasks to opus.

## Common failures
- Empty `result` with `is_error: true` and login-related text: the subscription is not authorized; interactive
  `claude auth login` is required, the agent cannot fix it, so escalate.
- The response stops during a build or test: see the background-tasks section.
- `--resume` cannot find the session: the ID is from another cwd (sessions are tied to the project directory).
