---
name: harness/opencode
description: How to run OpenCode headless as a worker on third-party providers (NVIDIA Build, Vercel AI Gateway, OpenRouter, free Zen models): opencode run, selecting a provider/model and an agent from config, permissions, sessions, spend accounting, and provider checks.
---

# OpenCode (`opencode`) as a worker

Tested with `opencode` 1.19 (2026-10-25), Linux. This client uses its own keys for different providers and has no
single quota: limits and balances belong to the providers. Providers and keys: `opencode providers list`; models:
`opencode models [provider]`; spend by model for a period: `opencode stats --days 7 --models`.

## Single-turn call
```bash
opencode run "<prompt>" --format json --auto --dir /abs/path/project \
  -m nvidia/z-ai/glm-5.3 --variant high </dev/null 2>err.txt
```
- `run` is non-interactive. `--auto` auto-approves tools (the skip-permissions equivalent); without it, the worker
  stops at the first question.
- `--dir` sets the working directory (opencode also respects cwd, but explicit is better).
- Model format is `provider/model`, for example `nvidia/z-ai/glm-5.3`, `vercel/zai/glm-4.7-flash`,
  `openrouter/moonshotai/kimi-k2`, or `opencode/glm-5.3-flash-free`; current list: `opencode models <provider>`.
  Instead of a model, specify an agent from config: `--agent coder` (agents with descriptions and models are in
  `~/.config/opencode/opencode.json`).
- `--variant low|medium|high` sets reasoning depth where the model supports it.
- `--format json` prints events; find the final result and spend in the latest events with `tokens` and `cost`.

## Sessions
`-c` continues the last session (unsafe in automation); `--session <id>` selects a specific one. The ID appears in
JSON events and in `opencode session list`. Spend by session and model: `opencode stats --days 7 --models`. Data is
stored in `~/.local/share/opencode/opencode.db`.

## Providers in a typical installation
| provider | what it is | characteristics |
|---|---|---|
| `nvidia/…` | NVIDIA Build, free | no balance, requests-per-minute limit, queue can be long (tens of seconds before a response) |
| `vercel/…` | Vercel AI Gateway | prepaid dollar balance |
| `openrouter/…` | OpenRouter | dollar credits, key in the file referenced by `{file:…}` in config |
| `opencode/…-free` | free Zen models | no login, quality and availability fluctuate |

If a provider key is empty or rejected (401/403), do not launch workers on it and record this; the user supplies keys.

## When to use opencode
- Bulk inexpensive tasks where GLM or Kimi quality is sufficient: labeling, summaries, test drafts, checklist
  reviews. Claude, ChatGPT, and Google subscription spend is zero.
- As a fallback worker when subscription quotas are near their limits.
- Do not use it for high-cost-of-error tasks: strong models there are paid through Vercel or OpenRouter, so count
  money rather than quota.

## Result checks and failures
- Check the exit code and non-empty final text; the NVIDIA queue may time out, so retry later or switch providers.
- `opencode providers login` is interactive and the agent does not perform it; escalate key problems.
- The installer puts the binary in `~/.opencode/bin`; if the command is not in PATH, look there.
