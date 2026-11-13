---
name: harness/claude
description: How to run Claude Code headless as a worker or consultant: command, the mandatory --strict-mcp-config, models and effort, permissions, fixed context of a call, token and quota accounting, sessions, live sessions with background tasks, and restrictions on expensive sub-agents.
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
claude -p "<prompt>" --model sonnet --effort high --strict-mcp-config --dangerously-skip-permissions \
  --output-format json --add-dir /abs/path/project </dev/null 2>err.txt
```
- **`--strict-mcp-config` goes into every headless call, without exception.** Without it the process connects every
  MCP server of the account (claude.ai connectors such as mail, calendar and drive, and plugin servers): the worker
  can reach them, their definitions cost tokens on every request, and with a short `--tools` list they are loaded
  in full (see "Fixed context of a call"). A worker that needs an MCP server gets exactly that one:
  `--strict-mcp-config --mcp-config <file.json>`. `artel run` passes the flag for every claude agent and takes the
  files from the agent's `mcp_config` in `config.yaml`; a worker you start by hand gets the flag from you. The
  connectors attach a few seconds after the start, so a turn
  of one request does not show them. Measured 2026-11-13 on a turn with `--tools Bash` and several requests:
  without the flag the first request read 6 600 tokens and every later one 61 800 or more, with 62 connector
  tools visible to the model; with the flag 6 600 and 6 800, none visible. `claude mcp list` ignores the flag and
  proves nothing; the check is the input tokens of the second request of a turn (`--output-format stream-json`).
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

## Fixed context of a call
A headless call inherits the whole setup of the account: the default tool set, MCP connectors, plugins and the
skill list are reread on every model request of every turn. Measured on a one-word haiku turn in a setup with
four connectors, two plugins and about 150 skills (2.1.323, 2026-11-13), total input tokens (a plugin's MCP
server made the session wait for all servers; without one the connectors arrive from the second request on):

| flags | input tokens |
|---|---|
| none | 43 400 |
| `--strict-mcp-config` or `--disable-slash-commands` alone | 40 200 / 41 500 |
| `--tools Read Grep Glob WebSearch WebFetch` without `--strict-mcp-config` | 63 600 |
| `--strict-mcp-config --tools Read Grep Glob WebSearch WebFetch` | 8 300 |
| the same with `--restricted` | 7 000 |
| the same with `Agent` in `--tools` | 9 900 |

- For a consultant or reviewer that only reads, name the tools with `--tools` next to the mandatory
  `--strict-mcp-config`; list the same tools in `--allowedTools` so that web tools need no approval. With a short
  tool list the skill list is not loaded at all.
- Trap: `--tools` without `--strict-mcp-config` makes it worse than no flags at all. Without the tool-search tool
  the definitions of every MCP tool are loaded in full.
- `--restricted` ignores the user, project and local settings files (hooks and plugins with them), removes the
  command-running tools unless `--tools` names them and confines file tools to cwd and `--add-dir`; it refuses
  `--dangerously-skip-permissions`. Check `claude --help` for it: older versions do not have the flag.
- Sessions resume with the same flags; `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` in the environment still pins
  sub-agents to a cheap model.

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
  --model opus --effort xhigh --strict-mcp-config --dangerously-skip-permissions
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
