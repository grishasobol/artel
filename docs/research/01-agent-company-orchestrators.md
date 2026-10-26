> Report prepared by Codex CLI (gpt-5.6-luna, high reasoning, live web search) on 2026-10-05. Text reproduced verbatim, without edits.

## Snapshot as of October 5, 2026

### Gas Town and Beads

The canonical repository is now [gastownhall/gastown](https://github.com/gastownhall/gastown); the old `steveyegge/gastown` was moved. The project is MIT-licensed, has about 18.2k stars, and is actively developed; the latest release is `v1.2.1` from June 6, 2026 ([releases](https://github.com/gastownhall/gastown/releases)). The exact date of the latest commit was not checked.

Gas Town is started with `gt up`, `gt mayor attach`, and `gt sling`; processes usually run in tmux and invoke local CLIs. Claude Code, Codex, Gemini, GitHub Copilot, Cursor, OpenCode, Kiro, Amp, Pi, and other runtimes are supported through configurable commands.

Roles are fixed: Mayor is the global coordinator; Polecats are permanent worker identities with ephemeral sessions; Crew are long-lived worker agents; Witness monitors the Polecats' lifecycle; Deacon is the background supervisor; Refinery is the change-integration queue; Dogs are support agents; Overseer is the human.

Plan and memory are represented not by one strategic document but by the Beads task graph. [Beads](https://github.com/gastownhall/beads) is a separate MIT project built on Dolt, with about 27.6k stars and a `v1.3.1` release from September 30, 2026. An agent can create, claim, update, and close tasks, build dependencies, use formulas/molecules, and record long-term memory.

(a/F3) Roles are predefined, although their number and configuration can be extended. The meta-agent does not design a team from scratch for each project.  
(b/F5) Mayor coordinates the work, but there is no evidence of built-in periodic analysis of all transcripts with prompt, schedule, and team-structure rewrites.  
(c/F2) There is configuration for available harnesses and models, but no full automatic audit of subscriptions and limits.  
(d/F6) There is no pacing for Claude Max, ChatGPT, or Google windows. The scheduler mainly limits concurrency to avoid exhausting API rate limits.  
(e/F1/F4) Beads is a good general task artifact; agents can change it, but it is not a user strategic plan with formal modification rules.  
(f/F7) Escalation goes through Deacon, Mayor, and Overseer, mainly inside Beads.  
(g/F8) Practically coding-oriented.  
(h) Yes: local official CLIs allow flat subscriptions to be used.

Gas Town has no full aggregated cost report for the organization: [issue #24](https://github.com/gastownhall/gastown/issues/24) still requests token and cost totals by agent, task, and convoy.

[Gas City](https://github.com/gastownhall/gascity) is an orchestration-builder SDK split out of Gas Town, MIT-licensed, with about 1.3k stars. It adds declarative `city.toml`, providers, a supervisor, structured transcripts, and burn-rate estimates, but still has no meta-agent that changes the organization itself and cannot pace subscription quotas. [Wasteland](https://github.com/gastownhall/wasteland) is a Gas Town federation through task boards, reputation, and DoltHub, not a management system.

### Paperclip

[Paperclip](https://github.com/paperclipai/paperclip) is the project closest to the AI-company concept. It is an MIT project with about 97.5k stars; the latest release is `v2026.916.1` from September 21, 2026 ([releases](https://github.com/paperclipai/paperclip/releases)). The repository is actively maintained.

The organization has a goal, projects, milestones, issues, and a strict reporting tree. The CEO agent forms strategy, breaks down goals, hires agents, and distributes tasks. Heartbeats run on a schedule, task assignment, comment, approval, or manually. A human board approves hiring, CEO strategy, stopping, reassignment, and agent completion. This is described in the [SPEC](https://github.com/paperclipai/paperclip/blob/master/doc/SPEC.md) and [core concepts](https://github.com/paperclipai/paperclip/blob/master/docs/start/core-concepts.md).

Supported runtimes include `claude_local`, `codex_local`, `opencode_local`, `pi_local`, Cursor, OpenClaw Gateway, Hermes, and process/HTTP adapters; the documentation also mentions Gemini. Agents can be local CLI processes.

(a/F3) The CEO can hire agents and create an organization for the goals, but the typical model is still built around a given CEO/manager/employee hierarchy.  
(b/F5) The CEO periodically reviews tasks and metrics, but there is no native, demonstrated cycle of “read transcripts → rewrite prompts → change schedule and structure.” Self-organization and automatic organizational learning remain unfinished in the roadmap ([README](https://github.com/paperclipai/paperclip)).  
(c/F2) There are adapters and model information, but no reliable discovery of subscriptions, their windows, or remaining quotas.  
(d/F6) Budgets are set in monetary cents, provider/model/input/output tokens and `billed_cents` are tracked, and monthly limits and a hard stop exist. This is API-spend budgeting, not Claude Max or ChatGPT subscription-capacity management. [Issue #3406](https://github.com/paperclipai/paperclip/issues/3406) explicitly describes the flat-plan problem.  
(e/F1/F4) The company goal → project → milestone → issue hierarchy is a strong general artifact. Agents can change tasks, comments, and documents under access controls, but there is no plan and rule set as flexible as artel's.  
(f/F7) There are comments, Agent Chat, approvals, and an audit trail; external Telegram/Slack escalation is possible through connectors but is not the central mechanism.  
(g/F8) Domain-agnostic: marketing, research, content, outreach, and software.  
(h) Yes, for local Claude Code, Codex, and other CLIs.

### Multica

[Multica](https://github.com/multica-ai/multica) is an actively updated self-hosted coding platform: about 52k stars, 6.7k forks, more than 5.5k commits, and the latest push on October 4, 2026. Its license is not ordinary Apache/MIT: the README describes Apache 2.0 with additional conditions for hosted services, commercial embedding, and branding.

Multica creates an issue, then a run; the connected runtime claims the run, starts a local coding tool, and records the result. The runtime daemon discovers installed CLIs. Claude Code, Codex, Cursor Agent, Copilot CLI, OpenCode, OpenClaw, Hermes, Pi, Antigravity, Kiro, and many others are supported ([CLI and daemon](https://github.com/multica-ai/multica/blob/main/CLI_AND_DAEMON.md)).

A Squad consists of a leader and members: the leader wakes first and uses `@mentions` to decide whom to pass the next step to. Skills are `SKILL.md` files with scripts and reference material. They can be reused, but successful results are not automatically turned into new skills ([issue #4433](https://github.com/multica-ai/multica/issues/4433)).

(a/F3) The leader/members scheme is fixed; the meta-agent does not design an arbitrary organization.  
(b/F5) There is no demonstrated transcript-driven rewriting of the team and prompts.  
(c/F2) CLIs are discovered automatically, but subscription quotas and rate windows are not inventoried.  
(d/F6) There are queues, schedules, and concurrency limits, but no pacing for flat subscriptions.  
(e/F1/F4) Issues/runs/skills are working artifacts, but not a shared strategic plan.  
(f/F7) There are comments and human review, but no separate escalation channel.  
(g/F8) Coding-only.  
(h) Yes, this is one of Multica's strongest points.

### OpenAI Symphony

[Symphony](https://github.com/openai/symphony) is an Apache-2.0 reference implementation and draft spec, with about 27.5k stars. The repository officially calls the project an engineering preview; the exact date of the latest release or commit was not checked.

Symphony periodically polls an issue tracker, primarily Linear, creates an isolated workspace for the issue, and runs Codex through `codex app-server`. It has bounded concurrency, retries, backoff, reconciliation, and stops a run when the issue status changes. Operating rules are kept in the repository in `WORKFLOW.md` ([SPEC](https://github.com/openai/symphony/blob/main/SPEC.md)).

(a/F3) No: one Codex run per issue, with no self-organizing company.  
(b/F5) No transcript review or worker-prompt rewriting.  
(c/F2) No harness or subscription-limit discovery.  
(d/F6) There are concurrency and retry policies, but no pacing for subscription windows.  
(e/F1/F4) The issue tracker, comments, and `WORKFLOW.md` are a partial planning artifact.  
(f/F7) Human review, PRs, and issue statuses; no separate escalation channel.  
(g/F8) Coding-only.  
(h) Yes, Codex can work through local authorization, but Symphony does not manage its quota.

### Other notable projects in 2026

- [Markus](https://github.com/markus-global/markus) — Apache-2.0, about 196 stars, roughly 1.5k commits, active, but the exact date of the latest commit was not checked. This is a self-hosted AI workforce: Secretary assembles a team, managers and workers operate on heartbeats, and there are memory, approvals, reports, Telegram/Slack integrations, and domain-agnostic tasks. However, worker/manager roles are mostly fixed, and subscription-aware pacing is unconfirmed.

- [OneCompany](https://github.com/NTinkicht/OneCompany) — about one star, 1,148 commits, with no license selected before the public open-source release. Its `.onecompany` control plane is strong: goals, roles, governance, readiness, budgets, queue, supervision, and acceptance evidence. It is currently coding-only, with unattended dispatch disabled by default; meta-organizations and flat-subscription support are unconfirmed.

- [OpenFang](https://github.com/RightNow-AI/openfang) — MIT, about 18.2k stars, pre-1.0, with a claimed `v0.5.10` release. This is a Rust Agent OS with 24/7 “Hands,” Telegram/WhatsApp channels, 27 providers, cost tracking, and a rate limiter. But the README explicitly says it is not a multi-agent orchestrator: it is more a general runtime than an AI company.

- [Humble](https://github.com/yethikrishna/humble) — an early/rebranded project from former Kortix/Suna, claiming an autonomous-company OS, sandbox, cron, webhooks, channels, and an OpenCode runtime. Current status, license, and support were not checked; GitHub has about zero stars. There is no evidence for F5/F6.

## Capability matrix

| Project | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 |
|---|---|---|---|---|---|---|---|---|
| Gas Town | partial, Beads | partial | no, fixed roles | yes, tasks | partial | no | partial | partial |
| Paperclip | yes, goals/issues | partial | partial, CEO hires | yes | partial | partial, API budget | partial | yes |
| Multica | partial, issues/runs | partial, CLI discovery | no | partial | no | no | partial | no |
| Symphony | partial, issues/WORKFLOW | no | no | partial | no | partial, concurrency | partial | no |
| Markus | yes, goals/knowledge | partial | partial, Secretary | yes | partial | partial | yes | yes |
| OneCompany | yes, control plane | partial | no | yes | partial | partial | partial | no |

## Conclusion and critique

The closest overall match to artel is **Paperclip**: it is the only one that combines a CEO agent, hiring, an org chart, goals, heartbeats, approvals, budgets, an audit trail, domain-agnostic work, and local CLI adapters. But it substantially lacks F2 and F6 for flat subscriptions, a full F5 self-change cycle, a flexible user plan artifact with rules, and reliable external F7 escalation. Markus is more interesting for memory and reports, while Gas City is stronger on orchestration infrastructure, but both are further from the complete F1–F8 set.

Users and authors have already documented the risks:

- Steve Yegge describes early Gas Town as a “22-nose Clown Show” with serial worker bugs and widespread data loss, although he later declared the system stabilized: [Gas Town from Clown Show to v1.0](https://yegge.ai/essays/gas-town-from-clown-show-to-v10/).
- A Paperclip incident reportedly consumed 35,603,866 tokens and about $20 because of a retry/auth storm: [issue #9539](https://github.com/paperclipai/paperclip/issues/9539).
- A Paperclip user described shallow planning, weak collaboration, slow operation, and low quality at high token cost: [issue #3308](https://github.com/paperclipai/paperclip/issues/3308).
- An operator who abandoned Paperclip reported that agents produced work faster than a human could review it and that misalignment accumulated; subscription-limit and audit problems also arose: [Why We Killed Paperclip](https://blog.alienbraintrust.ai/ai-learning/2026-04-05-why-we-killed-paperclip/).
- Errors involving Claude weekly limits and a retry cascade have also been documented: [issue #6499](https://github.com/paperclipai/paperclip/issues/6499). This confirms the main conclusion: a meta-layer for tasks already exists, but subscription-aware resource management at the F6 level is practically absent.
