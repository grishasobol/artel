> Report prepared by Codex CLI (gpt-5.6-luna, high reasoning, live web search) on 2026-10-05. Text reproduced verbatim, without edits.

# Conclusion

As of 2026-10-05, I found no full analogue of `artel`. The market already offers separate parts of the system: multi-terminal sessions, worktrees, tasks, schedulers, workflow graphs, persistent memory, notifications, and sometimes budgeting. But I found no project that simultaneously:

- discovers available CLIs, models, and subscriptions on its own;
- designs the team and its schedule on its own;
- runs independent headless sessions for weeks;
- periodically acts as a manager, checking quality and rewriting the plan, prompts, and configuration;
- distributes work across Claude Max, ChatGPT, and Gemini constraints;
- remains self-hosted and domain-agnostic.

For a developer who already has a Python/systemd scheduler, the most valuable thing is not replacing the scheduler but borrowing plan formats, artifact-change rules, and management-cycle ideas.

## Most relevant projects

- [Ruflo / claude-flow](https://github.com/ruvnet/ruflo) — active MIT project, about 73.9k stars, latest found release `v3.42.4` from 2026-09-17. It is a meta-harness for Claude Code and Codex with swarm agents, memory, autopilot, loop-workers, goals, and a cost tracker; Claude, GPT, Gemini, and local models are claimed to be supported. Roles are mainly represented by a catalog of plugins/agents rather than being freely designed by a manager. It has partial F1–F6, but no confirmed cycle in which a supervisor regularly rewrites the team and its own prompts. Support for subscription rolling-window limits is unproven.

- [Composio Agent Orchestrator](https://github.com/OrchestratorInc/agent-orchestrator) — the original repository moved from `ComposioHQ`; about 12.8k stars, Apache-2.0, stable `v0.13.3` from 2026-10-01 and a nightly build from 2026-10-05. [Documentation](https://docs.orchestrator.inc/) describes desktop/daemon project control, worktrees, a SQLite registry, worker/orchestrator/reviewer agents, persistent sessions, and recurring Automations. Claude Code, Codex, Cursor, Aider, OpenCode, Droid, Kimi, and other harnesses are supported. It is one of the closest options to F3, F5, and F7, but roles and configuration are defined by the project, there is no general evolving plan, and subscription budgeting was not found.

- [AWS CLI Agent Orchestrator](https://github.com/awslabs/cli-agent-orchestrator) — active Apache-2.0 project, about 1.4k stars, `v2.5.1` from 2026-09-11. It runs CLI agents in isolated tmux sessions and has a supervisor, Web UI, MCP, persistent memory, and saved workflows; it supports Kiro, Claude Code, Codex, Antigravity, Gemini, OpenCode, Copilot, and other CLIs. [Workflow documentation](https://github.com/awslabs/cli-agent-orchestrator/blob/main/docs/workflows.md) describes a durable journal and resumable pipelines. This is strong F2–F4 infrastructure but not an autonomous meta-manager: the plan, roles, and limits are not rebuilt from work results, and flat-subscription quotas are not considered.

- [Overstory](https://github.com/jayminwest/overstory) was conceptually very close: coordinator/lead/workers, SQLite mail, worktrees, headless runtimes, and Claude/Gemini/Codex/Aider and other harnesses. However, the repository was [archived on 2026-05-28](https://github.com/jayminwest/overstory/blob/main/README.md), is read-only, and is officially no longer supported; development moved to Warren. For a new project, it is more a source of architectural ideas than a dependency.

- [MCP Agent Mail](https://github.com/dicklesworthstone/mcp_agent_mail) — active coordination layer by Jeffrey Emanuel/Dicklesworthstone, about 2.2k stars; the exact license and latest release date were not checked. It provides identities, inbox/outbox, threads, advisory file reservations, and an audit trail. The project itself recommends using [Beads](https://github.com/steveyegge/beads) as the source of truth for statuses and dependencies, and Agent Mail for communication and decisions. [NTM](https://github.com/Dicklesworthstone/ntm) has about 452 stars, MIT with an additional condition, and release `v1.35.1` from 2026-09-14; it is a tmux control plane for Claude, Codex, and Gemini. Both projects solve live coordination, but not F1/F3/F5/F6.

- [Aperant, formerly Auto-Claude](https://github.com/praxstack/Auto-Claude) — desktop application for autonomous coding tasks: planning, implementation, QA, worktrees, and automatic change merging. AGPL-3.0; the 2.x branch is supported, Aperant 3.0 development is active, and the exact latest release date was not checked; the GitHub page shows about one star after the migration. This is a coding-only task runner with a fixed structure, without a headless scheduler or manager loop.

- [Vibe Kanban](https://github.com/BloopAI/vibe-kanban) has about 28.3k stars, Apache-2.0, and a latest found prerelease from 2026-09-19, but the README says the project is sunsetting. It is useful as a Kanban/worktree UI for Claude Code, Codex, Gemini CLI, Copilot, Cursor, OpenCode, and other CLIs, but has no long-lived manager, quota awareness, or self-editing plan.

- [Nimbalyst](https://github.com/Nimbalyst/nimbalyst) — MIT, about 1.8k stars, `v0.79.1` from 2026-09-30. It supports Claude Code, Codex, OpenCode, and Gemini, linking tasks, plans, files, worktrees, and persistent sessions. [Automations](https://nimbalyst.com/docs/session-management/automations/) launch recurring tasks from Markdown files, while [Super Loops and Agent Teams](https://nimbalyst.com/docs/developer-features/agent-teams-and-super-loops/) add fresh-context iterations and self-wakeup. `v0.79.1` introduced the alpha Crew feature: persistent teammates work shifts within token budgets and alert the human to problems. This is probably the closest ready-made product to F3/F5/F6/F7, but Crew is off by default, Automations usually work only while the application is open, and no mature self-rewriting manager was found. Crystal is its predecessor; [Nimbalyst calls itself Crystal's successor](https://www.nimbalyst.com/crystal/).

- [Emdash](https://github.com/generalaction/emdash) — active desktop orchestrator, release `v1.2.7` from 2026-09-27; exact stars and license were not checked. It runs parallel agents in worktrees, supports about 34 CLI providers, and has cron-like Automations with history and a self-healing scheduler. This is a useful wrapper around scheduling that the user has already solved, but it has no general evolving plan, quota manager, or periodic manager.

- [zeroshot](https://github.com/the-open-engine/zeroshot) — about 1.9k stars; the found release `v6.2.0` is dated 2026-06-27, but the current release date and license were not fully rechecked against primary sources. The planner forms a task and criteria, the implementer works in an isolated environment, validators check the result, and then a repair loop runs. This is strong F1/F4/F5 at the validation-loop level, but roles are fixed and schedulers and subscription budgets are absent.

- [Conductor](https://www.conductor.build/) — commercial cloud product; the changelog shows `0.90.0` from 2026-10-02. It runs Claude Code, Codex, Cursor, and OpenCode in cloud sandboxes and supports parallel workspaces and an API with a Markdown plan. It is not self-hosted and is not a long-term project manager: the plan is attached to a run rather than developed through an independent supervisor.

- [Claude Code native Agent Teams](https://code.claude.com/docs/en/agent-teams) — experimental feature: one lead, independent teammates, a shared task list, mailbox, and dependencies; tmux and in-process modes are supported. There are background subagents and `/tasks` in the [official subagents](https://code.claude.com/docs/en/sub-agents). But one team is tied to one session, nested teams are absent, team config cannot be edited in advance, resumption is limited, and the cost is higher. This is not F5/F6 or a long-term scheduler.

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — about 39.2k stars, MIT, `v5.4.0` from 2026-09-11. It provides `team-plan → team-prd → team-exec → team-verify → team-fix`, persistent execution, and cost optimization, but uses a fixed set of roles and is not a headless, subscription-aware manager. [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex) stores durable plans, logs, and state in `.omx/`, but its release date and star count were not checked. [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) is active, but its current stars/license/release were not checked.

## Matrix

| Project | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 |
|---|---|---|---|---|---|---|---|---|
| Nimbalyst | partial — plans/tasks | partial — providers | partial — Crew alpha | partial — trackers | partial — shifts/loops | partial — token budget | yes — mobile flags | partial |
| Agent Orchestrator | partial — project config | yes — harness registry | partial — worker/orchestrator | partial — sessions | partial — reviewers/automations | no — quota not found | yes — notifications | no |
| AWS CAO | partial — supervisor | yes — CLI discovery | partial — profiles | partial — journal | partial — learning | no | partial — UI/API | no |
| Ruflo | partial — goals | partial | partial — swarms | partial | partial — autopilot | partial — cost tracker | partial | partial |
| Emdash | partial — task prompts | partial | no — fixed | partial — history | no | no | partial | no |
| zeroshot | yes — planner | partial | no — fixed pipeline | partial — durable state | partial — repair loop | no | partial | no |
| OMC/OMX | yes — plan/goal | partial | partial — fixed roles | yes — durable artifacts | partial | partial — cost optimization | partial | no |
| claw-pilot | yes — DAG/task board | yes — BYO agents | partial | yes | partial — heartbeat | yes — budgets claimed | yes — Telegram | partial |

For [claw-pilot](https://github.com/swoelffel/claw-pilot), permanent sessions, a heartbeat scheduler, DAG flows, monthly/lifetime budgets, MCP, and Telegram are claimed. However, its stars, license, latest release, and actual maintainability as of this date were **not checked**.

## Plan formats worth reusing

The most mature combination is not to copy one framework but to combine several ideas:

- [GitHub Spec Kit](https://github.com/github/spec-kit) provides good review gates: Constitution → Specify → Plan → Tasks → Implement, plus a `converge` command that identifies discrepancies.
- [OpenSpec](https://github.com/Fission-AI/OpenSpec) describes plan changes best: proposal → specs/design → tasks; when reality changes, the change artifact is updated first, completed changes are archived, and a compact specification remains.
- [GSD](https://github.com/gsd-build/get-shit-done) offers a practical `.planning/` structure: `ROADMAP.md`, `PLAN.md`, `STATE.md`, `SUMMARY.md`, `REQUIREMENTS.md`, `VERIFICATION.md`. Its especially useful rule is that after execution, a plan becomes a historical artifact and is not rewritten retroactively.
- [BMAD](https://github.com/bmad-code-org/BMAD-METHOD) is useful for `sprint-status.yaml`, deterministic status merging, a ban on degrading status, and requiring retrospectives to be supported by specific sources.
- [Task Master](https://github.com/eyaltoledano/claude-task-master) is worth using as a dependency-aware task-store model, but agents should not edit its state files directly.

For `artel`, I would make an append-only log of plan changes: an agent would not edit a completed plan but would create a change proposal with the reason, evidence, affected tasks, a new cost estimate, and the manager's decision.

## Final answers

(a) Closest: Nimbalyst, Agent Orchestrator, AWS CAO, and Ruflo. claw-pilot and FideliOS are potentially even closer, but their current releases, licenses, and maintainability were **not checked**. All lack the specific combination of subscription-aware budgeting, self-rewriting teams, and a long-term domain-agnostic manager loop.

(b) Reuse Spec Kit for gates, OpenSpec for change evolution, GSD for roadmap/state/history, and BMAD for strict status and retrospective rules. This is more mature than inventing a custom format from scratch.

(c) No complete F1–F8 was found anywhere in the reviewed sample. The rarest combination is F2+F3+F5+F6: a manager that discovers CLIs and subscriptions, redistributes work across time-based quotas, rewrites prompts/config/team, and continues for months through headless harnesses. This remains the most differentiated and potentially valuable part of `artel`.
