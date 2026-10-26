> Report prepared by Codex CLI (gpt-5.6-luna, high reasoning, live web search) on 2026-10-05. Text reproduced verbatim, without edits.

# Report: scheduled/always-on runtimes relative to artel

The review used official documentation, changelogs, and GitHub as of October 5, 2026. GitHub stars and licenses do not apply to closed products; where an exact status or limit could not be confirmed, it is marked “not checked.”

## Part A. Vendor-native runtimes

### Anthropic

**Claude Code routines** are the closest vendor-native option. This is a research preview for Pro, Max, Team, and Enterprise: a saved prompt, repositories, environment, and connectors are launched on a schedule, through the HTTP API, or by GitHub events in the cloud or a self-hosted environment. The minimum interval is one hour; the scheduled-run limit is 100 per hour per account. Runs consume ordinary subscription usage; when the limit is exhausted, they stop unless metered credits are enabled. [Official routines documentation](https://code.claude.com/docs/en/routines)

Routines provide **partial F4**: each run is a new Claude Code session with access to the repository and logs, but there is no shared long-lived plan with formal change rules. **Partial F1** — Claude can create a plan but does not create an artel-like managed structure. **Partial F3**: agent teams can assign roles, models, and tasks, but the team feature is experimental, limited to one session, and not created in `claude -p`/Agent SDK. **No F5–F6**: there is no manager that changes prompts and the team itself or redistributes subscription quota across harnesses. **Partial F7** through GitHub/MCP connectors; **partial F8**, since routines are mostly cloud-based.

Native **agent teams** have a shared task list, mailbox, and direct communication between teammates, but team config is deleted after the session ends, and `/resume` does not restore in-process teammates. This is not a permanent team for work over months. [Official agent-team limitations](https://code.claude.com/docs/en/agent-teams)

`claude -p`, resume/continue, Agent SDK, subagents, hooks, and `CLAUDE.md` already solve headless execution, context continuation, and basic memory. `CLAUDE.md` contains project instructions, not a dynamic plan manager. The exact current official `/loop` contract was not found — **not checked**.

**Claude Cowork scheduled tasks** are available on all paid Pro, Max, Team, and Enterprise plans. Tasks run hourly/daily/weekly/on weekdays or manually, and can use connectors, skills, plugins, and a selected model. From October 6, 2026, new Pro/Max Cowork tasks must run in the cloud; local folders are not a permanent cloud environment. [Official Cowork documentation](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)

Conclusion: **partial F1/F4/F7**, none of the others. This is a convenient replacement for simple cron for Claude, but not a replacement for the developer's scheduler.

**Claude Managed Agents / Agents SDK** provide an Anthropic-hosted runtime for long-running API agents, subagents, state, tools, and schedules; Anthropic explicitly describes managed agents for autonomous work and nightly schedules. [Platform Agents](https://platform.claude.com/docs/en/agents), [Managed Agents example](https://www.anthropic.com/news/finance-agents). Exact current plan requirements, rate limits, and the relationship to Claude Max/Pro were **not checked**; this is more an API/cloud platform with separate economics than a flat-subscription harness. **Partial F1/F3/F4/F5**, **no F6/F8**.

### OpenAI

**Codex Automations / ChatGPT Scheduled Tasks** launch recurring tasks on web/desktop/mobile, using skills, plugins, files, and connected apps. Time-based schedules and event triggers for Gmail, Slack, and GitHub are supported. The CLI and IDE have no schedule-management interface; web or desktop is required. [Official Scheduled Tasks documentation](https://learn.chatgpt.com/docs/automations)

**Codex Cloud** provides separate cloud environments, persistent project setup, background coding tasks, follow-ups, tests, artifacts, and PRs. A task can continue while the computer is off, but this is not a self-hosted runtime. [Codex Cloud](https://developers.openai.com/codex/cloud/)

**Workspace agents** in ChatGPT Business, Enterprise, and Edu work with files, tools, memory, schedules, and Slack. They are significantly closer to F3/F4/F7, but roles and lifecycle are defined by the platform rather than freely designed by the agent. [Workspace agents](https://openai.com/index/introducing-workspace-agents-in-chatgpt/)

OpenAI conclusion: **partial F1/F3/F4/F7**, **no F2/F5/F6**, **no F8**. Limits and exact availability depend on the ChatGPT plan and workspace settings; the complete current matrix for all plans was **not checked**.

**Agents API**, announced on September 10, 2026, provides managed cloud agents on the Codex harness, sessions, environments, webhooks, multi-agent orchestration, sandboxing, and observability. This is the best API primitive for implementing a meta-layer, but not a ready-made artel: the scheduler, quota manager, and manager-agent still have to be written by the developer. [Official Agents API announcement](https://openai.com/index/introducing-the-agents-api/)

### Google

**Jules** has built-in Scheduled Tasks for daily/weekly maintenance work. Each task runs in a VM, plans the work, and can open a PR. An existing task cannot be edited; it must be deleted and recreated. An API exists, but is currently alpha; API quotas were **not checked**. [Jules Scheduled Tasks](https://jules.google/docs/scheduled-tasks/), [Jules API](https://developers.google.com/jules/api)

Mapping: **partial F1/F4**, mostly none of the rest. Jules is well suited to periodic maintenance of a GitHub repository, but not to a long self-managing project.

**Gemini CLI** is a headless CLI with `-p`, resume, checkpointing, `GEMINI.md`, MCP, and GitHub Actions. For a personal Google account, 60 requests/min and 1000 requests/day are claimed; the license is Apache-2.0, releases are weekly, and nightlies are daily. [Gemini CLI repository](https://github.com/google-gemini/gemini-cli), [headless automation](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/tutorials/automation.md)

The CLI has no scheduler of its own: cron/GitHub Actions provides the schedule. Therefore **partial F4**, **no F1/F2/F3/F5/F6/F7**, **partial F8**.

For Google Antigravity, public documentation as of this date leads only to Getting Started; the official headless `agy` contract and native scheduler could not be confirmed — **not checked**. Antigravity itself does not look like a replacement for the developer's scheduler.

### Cursor

**Cursor Automations** launch Cloud Agents on schedules or GitHub, GitLab, Slack, webhook, and Linear events. PR creation/review, MCP, Slack, persistent memories for a specific automation, computer use, and multi-repository environments are available. Cloud Agents run in isolated VMs, support long-running mode, and produce artifacts. Billing is based on cloud-agent usage; exact requirements for specific plans were **not checked**. [Automations](https://cursor.com/docs/cloud-agent/automations), [Cloud Agents](https://cursor.com/docs/cloud-agent)

**Cursor Projects** are the closest vendor-native coordinator: the coordinator plans, delegates tasks to several agents, retains context for months, and performs recurring work. But the feature is rolling out, is unavailable on Enterprise, and requires cloud execution. [Projects](https://cursor.com/docs/agent/projects)

Mapping: **partial or yes for F1/F3/F4/F5 with Projects**, **yes F7**, **no F2/F6**, **no F8**. Cursor does not discover your Claude/Codex/Gemini subscriptions or distribute quotas among them.

### GitHub

**Copilot coding agent** runs in the background through GitHub Actions, makes commits, and opens draft PRs. **Agent HQ** adds mission control for several agents, plan mode, custom `AGENTS.md`, identity, and governance, but is primarily a GitHub-centric control plane. [Copilot coding agent](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/), [Agent HQ](https://github.blog/news-insights/company-news/welcome-home-agents/)

**GitHub Agentic Workflows (`gh-aw`)** are an open-source GitHub CLI extension: Markdown with YAML frontmatter is compiled into GitHub Actions; Copilot, Claude Code, Codex, Gemini CLI, and Pi are supported, along with sandboxing, safe outputs, MCP, and git-backed memory. The project is changing actively, is MIT-licensed, and is in public preview; exact stars and the latest commit as of October 5 were **not checked**. [gh-aw repository](https://github.com/github/gh-aw), [official documentation](https://docs.github.com/en/actions/tutorials/develop-agentic-workflows-in-github-actions)

Mapping: **partial F1/F3/F4**, **partial F7**, **no F2/F5/F6**, **no F8**. This is a good event-driven orchestration layer for GitHub, but not a self-hosted, domain-agnostic runtime.

## Part B. Open-source always-on agents

### OpenClaw

[OpenClaw](https://github.com/openclaw/openclaw) is the broadest self-hosted option: Gateway, heartbeat, cron, `HEARTBEAT.md`, multi-agent routing, isolated subagents, Telegram/Discord/Slack/WhatsApp/Signal/Teams, interchangeable model providers, skills/plugins, and failover. According to the GitHub API on October 5: about **391k stars**, MIT, `pushed_at` October 5, 2026; the project is clearly actively maintained. The README claims an independent OpenClaw Foundation, with OpenAI as donor rather than owner.

Mapping: **partial or yes for F2/F3/F4/F7/F8**, **partial F1/F5**, **partial F6** through model failover, but not through meaningful accounting of Claude Max/ChatGPT/Google subscription windows. There is no formal meta-manager that rewrites the team and optimizes spending.

The risk is significant: the agent combines messaging, memory, self-authored skills, scheduling, and shell access under one identity boundary. A 2026 study demonstrates persistent prompt-injection “sleeper channels,” where malicious input persists as memory/skill/cron and triggers later. [arXiv study](https://arxiv.org/abs/2605.13471). Sandboxing and pairing are mandatory: by default, tools may run on the host.

### Hermes Agent

[Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research is the closest open-source artel analogue in breadth. As of October 5: about **251k stars**, MIT, `pushed_at` October 5, 2026; actively supported. It has natural-language cron, result delivery to Telegram/Discord/Slack/WhatsApp/Signal, memory/dreaming, self-created and self-improving skills, isolated subagents, delegation, model fallback, RPC scripts, and terminal backends from local/Docker/SSH to Modal and Daytona. [Cron documentation](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron/)

Mapping: **partial or yes for F1/F3/F4/F5/F7/F8**; **partial F2** through provider/config inspection; **partial F6** only at the provider-fallback level, without a reliable subscription-budget planner. Hermes is closest to artel, but its learning loop improves skills and memory rather than fully managing a project plan and a fleet of independent harnesses.

### Ralph Loop and derivatives

Ralph is a methodology, not a full platform: a bash loop launches a fresh `claude -p`, reads `PROMPT.md`, updates `IMPLEMENTATION_PLAN.md`, runs tests, and repeats. Persistent state is ordinary files and git. [Geoffrey Huntley's repository](https://github.com/ghuntley/how-to-ralph-wiggum)

Mapping: **yes F4**, **partial F1**, mostly none of the rest; this is only a coding-oriented loop. The official Anthropic Ralph plugin and derivatives such as [lockstride/ralph-wiggum-plugin](https://github.com/lockstride/ralph-wiggum-plugin) and [stavarengo/ralph-wiggum-loop](https://github.com/stavarengo/ralph-wiggum-loop) exist, but stars, latest commit, and current support for individual forks were **not checked**.

### Small schedulers/daemons

Found were `biosphere-labs/claude-code-scheduler`, `dortort/claude-code-scheduler`, and repositories and forks named `runCLAUDErun`, `cc-cron`, `claude-cron`, `sleepless-agent`, `claude-code-daemon`, and `24/7 Claude Code`. They mostly wrap `cron`, launchd/systemd, or bash and launch headless CLIs. [Scheduler example](https://github.com/biosphere-labs/claude-code-scheduler), [dortort scheduler](https://github.com/dortort/claude-code-scheduler). MIT and about 3 stars are confirmed for dortort; exact stars/license/latest commit for most of the rest were **not checked**. None implements F1–F6; none replaces a developer's already-working scheduler.

### Letta

[Letta](https://github.com/letta-ai/letta) is a stateful-agent platform, Apache-2.0, with about **25k stars**, actively maintained; the main repository lists `pushed_at` September 10, 2026. Its MemFS is git-backed memory, while Dreaming/`/sleeptime` launches background subagents that consolidate knowledge and update memory. It has schedules, subagents, channels, and self-hosting. [Memory & dreaming](https://docs.letta.com/configuration/memory)

Mapping: **partial F1/F3/F4/F5/F8**, **no F2/F6**, **partial F7**. Letta is stronger than artel in durable memory but weaker in scheduler/meta-management and multi-harness quota allocation.

## Conclusion

Commodity features available out of the box now include headless execution, schedules and webhooks, cloud/background execution, a basic plan, subagents, checkpoints, memory files, PR/issue automation, Telegram/Slack connectors, and transcript/log review.

What has not become commodity: **F2** — inventory of harnesses, models, subscriptions, and quotas; **F3** — arbitrary team design; **F5** — a periodic manager that changes prompts, the plan, and infrastructure; **F6** — distributing work among flat subscriptions; and combining these features in a self-hosted, domain-agnostic system.

The three closest options are:

1. **Hermes Agent** — best overall foundation: self-hosting, cron, memory, skills, messaging, and delegation. It lacks a strict project manager and quota planner.
2. **OpenClaw** — broadest integrations and channels. It lacks a formal planning model, a safe meta-manager, and subscription-aware scheduling; its security boundary is more complex.
3. **Cursor Projects/Automations** or **Claude Code routines** — strongest managed coordinator/schedule features, but cloud/vendor-locked and unable to manage several independent harnesses.

Recommendation: **keep the custom scheduler and build the artel meta-layer on top of it**. It already wins on self-hosting, support for Claude/Codex/agy/opencode, systemd, Telegram, time windows, concurrency, transcripts, and token-usage accounting. Vendor runtimes should be used as separate worker backends, and OpenClaw/Hermes as optional memory/channel layers. Full replacement would make scheduling more convenient but destroy artel's key advantage: unified management of multiple subscriptions and the ability to control F1–F6 directly.
