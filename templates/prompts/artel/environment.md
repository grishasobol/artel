---
name: artel/environment
description: How the artel installer and super agent discover and maintain environment knowledge in environment.md: harnesses, models, subscriptions and quotas, the scheduler, communication channels, and container pitfalls.
---

# Environment (`agents/environment.md`)

## What to collect
1. **Automatically:** `artel env` (machine, CLI and versions, codex/agy models, the user project directory and its
   git, repositories in `src/`, what is mounted from outside, signals, systemd timers and services) and `artel quota`
   (claude via `/usage` or limit headers, agy via `/quota`, codex via `codex app-server`, opencode through connected
   providers). By default it returns the `agents/state/quota.json` cache younger than 10 minutes (refreshed by the
   `artel-<project>-quota` timer every 20 minutes); `--fresh` polls again and takes up to a minute, so the external
   timeout must be at least 90 s.
   Lines marked "WARNING" in the "User project directory" section are structural defects (no git user project,
   `agents/` inside the project repository, keys not ignored): fix them before registering the schedule.
2. **From the user (as one list of questions):**
   - which subscriptions and plans (Claude Pro/Max 5x/20x, ChatGPT Plus/Pro, Google AI Pro/Ultra), what else uses
     them (interactive work, other projects, other containers);
   - how much quota may be allocated to this project and during which hours;
   - the container and its limits (memory, GPU), which repositories in `src/` are mounted from the host and what
     lives only in the container (and therefore persists only in its snapshots), the noVNC screen address, and slot
     windows;
   - communication channels: concierge session and/or Telegram, quiet hours, and what counts as urgent;
   - known environment pitfalls (for example, "agy burns through a week's quota in one day with a 30m interval").
3. **From `harness/*` modules in the prompt library:** invocation details, models, and accounting. Do not copy them in
   full; put only what applies to this installation in `environment.md` (versions, models in the catalog, pitfalls).

## How to record it
The `environment.md` template already contains sections for machine and services; harnesses and models (table);
subscriptions and limits (table with snapshots); communication channels; pitfalls; and change history. Record facts
with a date and source ("user said 2026-10-06", "artel quota 2026-10-06 08:00"). Do not record secrets (tokens,
passwords): only paths to the files where they are stored.

## When to update
- The super agent checks CLI versions (`artel env`), quota snapshots, and the model list on every iteration. If
  anything changed, update the table and add a line to the change history.
- Any new pitfall from agent entries that has occurred twice goes into the pitfalls section with a workaround.
- A vendor policy or plan change (reported by the user or visible in limit errors) means updating the subscriptions
  section and reconsidering the schedule in `config.yaml`.

## How to read quotas
- Codex: `artel quota` asks live limits from `codex app-server` (`account/rateLimits/read`, with no spend):
  `primary` is the 5-hour window, `secondary` the week, and `resets_at` the reset time. If app-server does not
  respond, it uses the latest `rate_limits` from files in `~/.codex/sessions`, marked with its age.
- Claude: `artel quota` calls `claude -p "/usage" --output-format json`. This is a slash command in print mode:
  without an agent turn or quota spend it returns the current session (5-hour window), the week across all models,
  and model-specific weekly windows (for example, "Current week (Fable)"), exactly what the Claude Desktop panel
  shows. Lines are parsed with a regular expression matching "name: N% used · resets …"; if the output format
  changes, the command shows the raw text.
  With a long-lived token (`oauth_token` from `claude setup-token`, the standard container method), `/usage` never
  returns percentages: that token lacks the `user:profile` scope and the quota server responds with 403. In that
  case `artel quota` makes a trial haiku request (`max_tokens: 1`, about 25 tokens) and reads the 5-hour and 7-day
  windows from `anthropic-ratelimit-unified-*` headers. Model-specific windows (Fable) are not visible this way.
- Antigravity: `artel quota` calls `agy -p=/quota --output-format json` (and `/credits`): the response arrives
  without an agent turn and without quota spend. There are two model groups with independent limits: "Gemini Models"
  (Flash and Pro) and "Claude and GPT models"; each has a 5-hour and a weekly window. Quota is charged in proportion
  to token cost, so Flash uses it many times more slowly than Pro.
- OpenCode: this is a BYOK client; it has no quota, and limits live with the providers. `artel quota` starts
  `opencode serve` for a few seconds on a free port, reads connected providers as opencode itself sees them (auth.json,
  config, environment variables, plugins), and stops the server. It prints only connected providers; for each, any
  free information available: balance (OpenRouter, Vercel AI Gateway, DeepSeek, Moonshot), key validity (NVIDIA Build:
  a bad key is rejected immediately, a good one queues the request), OAuth-token expiry, and Copilot premium-request
  quota. For Zen without login it prints the number of free models. Below that is seven-day model spend from
  `opencode.db` (window `--days`). For `anthropic` and `openai` OAuth, quota is shared with the Claude and Codex sections.
- Problems are printed as `PROBLEM: reason` with a repair command: harness not logged in (`claude auth login`,
  `codex login`, `agy` interactively), binary cannot start, provider key is empty or rejected (401/403), OAuth token
  expired (`opencode providers login -p <id>`). Uninstalled harnesses are omitted from the output and listed in one
  line at the end. `--only codex,opencode` limits the poll, and `--json` returns everything as a whole.
- Every snapshot becomes stale; store its date. The Codex snapshot comes from the latest session file and may be more
  than an hour old (the command marks snapshots older than 5 hours as stale); with conflicting data, be conservative.

## Container pitfalls
- If `artel env` says "signals between processes: FORBIDDEN" (also: `kill -0 1` as root returns `Permission denied`),
  the host's AppArmor is blocking signals inside the container (Ubuntu 26.04, kernel 7.0: processes are visible to
  the host as `profile//&unconfined`, and the standard Incus rule does not cover them). Then `kill`, `timeout`,
  `tmux kill-server`, and stopping systemd units do not work. Fix it on the host with
  `incus config set <container> raw.apparmor=...` (the lines are in `install/artel-up.sh`), without restarting.
  Until it is fixed, only writing `1` to the `cgroup.kill` of your own scope works: processes in a transient scope
  started through `systemd-run --user --scope` cannot be stopped with `systemctl --user kill -s KILL` either; use
  `cgroup.kill`.
- `timeout N codex exec …` does not guarantee that a worker dies; launching it in its own scope is described in
  `artel/delegation`.
- X applications started by workers outlive the run; `artel run` kills them together with the run scope.

## How to compare spend across harnesses
The formulas differ: for codex, `input_tokens` includes `cached_input_tokens`; for agy, `input_tokens` does not
include `cache_read_tokens`; and claude counts cache writes separately, at a higher cost than input. Do not compare
raw numbers; compare the quota share per run (`artel quota` before and after) or the dollar estimate.
