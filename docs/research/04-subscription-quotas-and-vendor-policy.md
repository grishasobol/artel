> Report prepared by Codex CLI (gpt-5.6-luna, high reasoning, live web search) on 2026-10-05. Text reproduced verbatim, without edits.

## Conclusion

As of 2026-10-05, there is no complete, ready-made F6 for proactive planning of a week's work and redistribution of tasks among Claude Max, ChatGPT/Codex, and Google AI Pro/Ultra. Individual components exist: quota reading, warnings, waiting for reset, reactive fallback, account rotation, and budget stops. The closest option is `pi-multi-pass`, but it is tied to a specific harness and uses internal OAuth/API interfaces, creating a substantial policy risk.

The main problem is that local tokens and cost are not the same as server-side subscription quota. Vendors use hidden factors for complexity, model, context, speed, concurrency, five-hour windows, and weekly limits.

## What exists

| Project | Current status | What it does for F6 |
|---|---|---|
| [ccusage](https://github.com/ccusage/ccusage) | MIT, about 18.9k stars, 2,371 commits; exact date of the latest commit in the available snapshot was **not checked**, project active | Reads local logs from Claude, Codex, Gemini CLI, and Antigravity; builds daily/weekly reports and Claude 5-hour blocks. Analytics, not a scheduler. |
| [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) | MIT, about 8.7k stars; v4.0.0 from 2026-06-27; maintained | Forecasts usage, shows warnings, and can use official `rate_limits` from the statusline. No queue or cross-vendor redistribution. |
| [ccstatusline](https://github.com/sirmalloc/ccstatusline) | MIT; recent versions 2.2.29–2.2.30; stars and exact latest-commit date **not checked** | Formats official Claude limits in the statusline; display only. |
| [CodexBar](https://github.com/steipete/CodexBar) | MIT; v0.72.0 from 2026-10-04; stars **not checked**; actively maintained | Shows limits and reset times for several providers, including Codex and Antigravity. No queue or predictive planning. |
| [sleepless-agent](https://github.com/context-machine-lab/sleepless-agent) | MIT, about 833 stars; v0.1.0 from 2025-10-26; more recent release date **not checked** | 24/7 task queue for Claude, usage thresholds, and scheduling. Does not redistribute work among several subscriptions. |
| [agent-auto-resume](https://github.com/yuga-hashimoto/agent-auto-resume) | MIT, about 0 stars; latest commit/release date **not checked** | Waits for a server reset and resumes a session for Claude, Codex, or Antigravity. The project explicitly does not promise limit bypass or rotation. Reactive waiting. |
| [claude-code-router](https://github.com/musistudio/claude-code-router) | MIT, about 37.6k stars; exact latest-release date **not checked**, repository active | Routes and falls back across models/providers, usually after an error or 429. Does not plan a weekly quota in advance. |
| [CLIProxyAPI](https://github.com/skyline66/cliproxyapi) | MIT, about 0 stars, only 2 commits; last activity around 2026-10-03, project durability **unconfirmed** | Round-robin and multiple accounts for Claude/Gemini/OpenAI. A proxy and load balancer, not a safe subscription planner. |
| [pi-multi-pass](https://github.com/hjanuschka/pi-multi-pass) | Current activity confirmed; stars, license, and exact latest-commit date **not checked** | Closest to F6: `quota-first`, `scheduled`, `round-robin` strategies, fallback among accounts and providers. Connects to internal endpoints and OAuth, so policy risk is high. |
| [ai-quota](https://github.com/metyatech/ai-quota) | MIT, about 0 stars; latest visible activity around 2026-10-03; exact release **not checked** | Separate quota-reading layer for Claude, Gemini, Codex, and other services; does not plan work by itself. |
| [Paperclip](https://github.com/paperclipai/paperclip) | MIT, about 80–81k stars, 4,776 commits; actively developed | Has budgets, an 80% warning, a 100% stop, heartbeats, and cost tracking. Automatic quota-aware failover remains an open request: [issue #3374](https://github.com/paperclipai/paperclip/issues/3374). |
| [OpenClaw](https://github.com/openclaw/openclaw) | MIT, about 391k stars; API shows push on 2026-10-05; actively maintained | Has runtime fallback across models and providers, but does not plan Claude/Codex/Antigravity weekly quotas. |
| [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) | About 69.8k stars, push on 2026-10-05; license shown as Other/NOASSERTION | Budgeting for individual runs and fallback, but no subscription-window scheduler. |
| [Gas Town scheduler](https://github.com/gastownhall/gastown/blob/main/docs/design/scheduler.md) | Exact stars, license, and latest commit **not checked** | Limits concurrency and prevents API rate-limit exhaustion; capacity control, not subscription-quota planning. |

In short, tools fall into four classes:

1. **Observers:** `ccusage`, Claude-Code-Usage-Monitor, `ccstatusline`, CodexBar.
2. **Reset waiters:** `agent-auto-resume`, various `claude-auto-resume` tools.
3. **Reactive routers/fallbacks:** `claude-code-router`, CCS, LiteLLM, OpenClaw, CLIProxyAPI.
4. **Partially proactive:** `pi-multi-pass` and Paperclip budget limits.

Even [LiteLLM](https://github.com/BerriAI/litellm-docs/blob/main/docs/proxy/users.md) mainly manages API budgets, RPM/TPM, and per-key spending, not Claude Max or ChatGPT Pro windows.

## Available quota sources

### Claude

The best official source is the JSON that Claude Code passes to the user statusline: [statusline documentation](https://code.claude.com/docs/en/statusline). After the first response, it may contain:

- `rate_limits.five_hour.used_percentage`;
- `rate_limits.five_hour.resets_at`;
- `rate_limits.seven_day.used_percentage`;
- `rate_limits.seven_day.resets_at`.

Fields may be absent until the first response, so artel should store the observation timestamp and consider the data stale after a configured TTL. Local transcript files provide token usage, but not the actual server quota.

The `/usage` and `/status` commands are useful interactively. Community tools also call OAuth endpoints such as `/api/oauth/usage`, but this is an unsupported interface: 429 errors have been recorded even with normal access, for example in [issue anthropics/claude-code #30930](https://github.com/anthropics/claude-code/issues/30930). It should not be used as the sole F6 source.

### Codex

Official documents confirm `codex exec` for scripts and CI: [non-interactive mode](https://developers.openai.com/codex/noninteractive). The CLI provides `/status`, `/usage`, and `/statusline`: [CLI reference](https://developers.openai.com/codex/cli/reference).

Rollout files in `~/.codex/sessions/.../rollout-*.jsonl` sometimes contain a `rate_limits` object with `plan_type`, `limit_id`, `primary`, and `secondary` windows, usage percentage, and reset time. The format is visible in the [Codex source](https://github.com/openai/codex/blob/main/codex-rs/codex-api/src/rate_limits.rs). However, it is unstable: [issue #14880](https://github.com/openai/codex/issues/14880) reported `null`, and [issue #44210](https://github.com/openai/codex/issues/44210) shows discrepancies between values from different sessions.

F6 needs three reliability levels: rollout `rate_limits`, official `/usage`/statusline, and local token usage. Any missing or contradictory signal should put the scheduler into conservative mode.

### Antigravity

Antigravity's official documentation explicitly says that it supports the CLI and scheduled tasks. For Pro, the quota refreshes every five hours but has a weekly cap; Ultra has a higher limit and also a weekly window: [plans](https://antigravity.google/docs/plans/). The same page describes AI credits and automatic-purchase settings.

The `/usage`/`/quota` command shows remaining requests/tokens by model and updates the data from the backend: [usage command](https://antigravity.google/docs/cli/commands/usage/). Headless mode is supported through `agy -p` and JSON/stream-JSON: [headless CLI](https://antigravity.google/docs/cli/headless/). However, I did not find a stable documented machine-readable quota API — **not checked**.

Community projects use the internal endpoint `cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota`. This is a useful technical source, but not an official contract, and using it through a third-party OAuth harness increases the risk of blocking.

## Policies and economics

### Anthropic

The official article [Use Claude Agent SDK with your Claude plan](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan), updated 2026-06-16, says that `claude -p`, Agent SDK, and third-party app usage currently consume shared subscription limits; the previously announced separate monthly credit pool was suspended.

But this is not equivalent to permission for any cron bot. [Consumer Terms](https://www.anthropic.com/legal/consumer-terms), effective 2025-10-08, prohibit automated or non-human access through a bot/script except when explicitly permitted or when an API key is used. A separate Anthropic login page from 2026-05-19 clarifies that subscriptions are primarily intended for official applications; third-party tools should use an API key, and tools that mask identity or route other people's traffic through subscription limits are prohibited.

Practical conclusion: official Claude Code with `claude -p` is technically supported, but no blanket permission for uncontrolled cron under Pro/Max was found. For long-running production automation, Console/API or written confirmation from Anthropic is safer.

### OpenAI

OpenAI officially documents `codex exec`, including scripted/CI execution. [Codex help](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan) describes shared five-hour and weekly allowances, credits, `/status`, automatic continuation of the active turn, and options after the limit is reached.

At the same time, the [Terms of Use](https://openai.com/policies/row-terms-of-use/) prohibit automated data extraction and bypassing rate limits or protective mechanisms. Therefore, one official Codex CLI, one account, respecting reset times and avoiding backend scraping appear substantially safer than account rotation, proxies, or mass unattended runs.

### Google

Google announced that Gemini CLI would stop serving AI Pro/Ultra on 2026-06-18, transitioning to Antigravity CLI: [official announcement](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/). Antigravity itself documents the CLI and scheduled tasks, making this the clearest case of officially supported headless automation.

Risk arises when using another harness, impersonating the client, internal quota endpoints, or OAuth proxies. Reports of OpenClaw-user bans appear in a [GitHub discussion](https://github.com/google-gemini/gemini-cli/discussions/20632) and [community reports](https://www.reddit.com/r/openclaw/comments/1qyaalr/warninghelp_google_account_banned_403_tos/), but these are unconfirmed user cases, not official Google statistics.

## Risks for artel

1. **High — violation of Anthropic terms.** Do not rotate OAuth accounts, proxy traffic, extract tokens, or present a third-party runner as the official client.
2. **High — Google blocking.** Use official `agy`, not internal endpoints through OpenClaw/proxies; do not apply mass automation across multiple accounts.
3. **Medium-high — OpenAI enforcement.** Do not bypass limits, scrape the backend, share accounts, or rotate multiple accounts.
4. **Medium — unexpected costs.** Claude usage credits and Google AI credits may enable paid continuation; hard stop, alert, and overage prohibition are needed by default.
5. **Medium — unreliable planning.** A vendor may change quota, counting model, or weekly reset without a compatible API.
6. **Medium — credential leakage.** Monitors and proxies that read OAuth become critical compromise points.

## F6 decision

F6 exists **partially**, but not as a ready-made vendor-neutral product. It makes sense to build it in artel: the developer already has a scheduler, and the missing layer is a normalized `QuotaSnapshot` for each harness, usage forecasting, conservative pacing, a hard stop, and fallback only among permitted official channels.

Minimum safe implementation:

- Claude: official statusline JSON plus local transcripts.
- Codex: `/usage`/statusline plus rollout `rate_limits`, marked as incomplete.
- Antigravity: official `/usage` and CLI state; use the internal quota endpoint only as an optional experimental adapter.
- Do not plan from a single percentage: account for five-hour and weekly windows, reset timestamps, data uncertainty, and a minimum reserve.
- Do not perform account rotation or build F6 on an OAuth proxy.
- When no fresh quota is available, stop low-priority work and escalate to the human.

In other words, build not an “automatic limit bypass” but a conservative dispatcher that slows down, waits for reset, and switches only to officially permitted models or APIs.
