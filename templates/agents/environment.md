# Environment for project {{PROJECT}}

> Collected by the installer and maintained by the super agent. Worker agents read the relevant sections
> when choosing a tool or hitting a limit. Update it whenever the environment changes (new model, different
> quota, different container), with a journal entry.

## Machine and services
- Host: 
- OS / RAM / specifics: 
- Launch: `artel-<name>` container (Incus) with systemd inside; `artel-<project>-*` timers from `artel register`; one-off launch with `systemctl --user start artel-<project>-<agent>.service`; container memory limits; display `:1` and the user's noVNC address
- User project directory: path; repositories in `src/` and their origins; what is host-mounted (and whether read-only); what exists only in the container and is preserved by its snapshots
- Claude concierge session (communication channel): how it is launched and restarted
- Other persistent services that must not be disturbed: 

## Harnesses and models
| harness | version | billing | models | notes |
|---|---|---|---|---|
| claude | | Claude subscription (5-hour and 7-day windows) | opus, sonnet, haiku, fable | |
| codex | | ChatGPT subscription (5-hour and 7-day windows) | gpt-6-luna, gpt-6.1-sol, gpt-6-astra; older: gpt-5.6-luna/terra/sol (catalogue in `~/.codex/models_cache.json`) | |
| agy | | Antigravity quota: two independent groups (Gemini; Claude and GPT-OSS), each with 5-hour and weekly windows | gemini-3.8-flash-*, gemini-4-argon-*; claude-sonnet-5-5-*, claude-opus-5-5-*, gpt-oss-120b-medium (`agy models`) | The Claude/GPT group is not linked to the Anthropic subscription: a fourth independent pool; shell in `--add-dir`, absolute paths |
| opencode | | provider quotas, not harness quotas: `artel quota` shows connected providers and their balances | provider/model, e.g. openrouter/…, nvidia/… | BYOK client; free Zen models without login; NVIDIA Build has no balance, limit is requests per minute |

## Subscriptions and limits (from the user and `artel quota` snapshots)
| subscription | plan | limit/window | current usage | snapshot date |
|---|---|---|---|---|
| Claude | | | | |
| ChatGPT | | | | |
| Google | | | | |

How to read quotas: `artel quota`. Claude uses `claude -p /usage`, agy uses `agy -p=/quota`, both without
spending quota or an agent turn; codex uses the latest session file; opencode uses connected providers (balance,
key validity, OAuth expiry) and seven-day model spending. Only installed harnesses and connected providers are
printed; problems (no login, empty or rejected key, expired token) appear as `PROBLEM: …` with a repair command.

## Communication channels with the user
- Primary: 
- Quiet hours: 
- What counts as urgent: 

## What is already known about working in this environment (pitfalls)
- 

## Change history
- {{DATE}} — created by the installer.
