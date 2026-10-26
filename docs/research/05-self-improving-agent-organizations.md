> Report prepared by Codex CLI (gpt-5.6-luna, high reasoning, live web search) on 2026-10-05. Text reproduced verbatim, without edits.

## Conclusion

As of 2026-10-05, a full analogue of `artel` is practically absent. Paperclip, OpenClaw, and Crew Studio are closest to F3; Hermes Agent, claude-reflect, gstack, DSPy/GEPA, and EvoAgentX are closest to F5. But none combines automatic team design, independent headless runs across different harnesses, periodic transcript review, prompt and schedule changes, quality control, and subscription-quota optimization across F1–F8.

The final classification is: (i) there is no ready-made open-source product; (ii) individual mechanisms exist in research prototypes, almost always with a benchmark or fitness function; (iii) a cohesive product is practically unavailable out of the box.

## 1. F3/F5 research

Repository statuses were checked on GitHub as of the current date; stars are approximate. If the latest commit date was not shown in the available interface, it is marked “not checked.”

- **ADAS / Meta Agent Search** — 2024 work, ICLR 2025; the meta-agent writes new agent systems as code and iteratively selects them by their results. Repository: about 1.6k stars, Apache-2.0, 17 commits; latest commit date not checked. This is direct evidence for F3, but the search runs on fixed tasks and requires an evaluation function: [paper](https://arxiv.org/abs/2408.08435), [code](https://github.com/ShengranHu/ADAS).

- **AFlow** — ICLR 2025; generates and optimizes workflow graphs through an MCTS-like search, changing nodes, prompts, step order, and ensembles. Published results show that automatically found workflows can outperform manual ones. The code is integrated into MetaGPT, which has about 70.7k stars, MIT, and was updated in January 2026: [AFlow](https://arxiv.org/abs/2410.10762), [MetaGPT](https://github.com/FoundationAgents/MetaGPT). This is F3/F5 for testable workflows, but not for a long-lived organization.

- **AutoAgents** — IJCAI 2024; an LLM generates specialized roles and coordinates them for a task. The repository has about 1.5k stars and MIT; the latest commit date and release availability were not checked. Experiments confirm the value of role distribution on benchmark tasks, but do not show long-term adaptation: [paper](https://arxiv.org/abs/2309.17288), [code](https://github.com/OWD-AI/AutoAgents).

- **AgentVerse** — Apache-2.0, about 5.2k stars; the framework provides ready-made task-solving and simulation systems, but roles and scenarios are mostly defined by the developer. The latest commit date and current support were not checked. This is more a multi-agent execution platform than F3/F5: [repository](https://github.com/OpenBMB/AgentVerse).

- **EvoAgentX** — open system from 2025, about 3.4k stars, MIT. It automatically builds and evolves workflows, including prompts, topology, and memory; published examples use HotPotQA, MBPP, and MATH. The project is clearly developing, but the exact latest commit date was not checked. This is the closest open-source research component to F5, but it optimizes one system on preselected tasks rather than managing a real team: [code](https://github.com/ANative-Lab/EvoAgentX), [paper](https://arxiv.org/abs/2507.03616).

- **G-Designer** — adaptively designs the communication topology of a multi-agent system using a variational graph autoencoder. This is F3 at the level of connections between agents, but not role, prompt, or schedule creation. A ready, maintained product and code status were not checked: [paper](https://arxiv.org/abs/2410.11782).

- **Gödel Agent** — a self-referential agent changes its own logic toward a high-level goal without a fixed algorithm in advance. The repository has 228 stars, MIT, and only nine commits; it is a research prototype, and the latest commit date was not checked: [paper](https://arxiv.org/abs/2410.04444), [code](https://github.com/Arvid-pku/Godel_Agent).

- **Darwin Gödel Machine** — the system maintains an archive of agent variants, generates mutations of its own code, and retains them only after empirical evaluation on a coding benchmark. The paper reports growth from 19.0% to 59.5% on a selected benchmark for one configuration, but this is not evidence of universal improvement: [paper](https://arxiv.org/abs/2505.22954). The key lesson for `artel`: an external test, version archive, and held-out evaluation are needed.

- **ShinkaEvolve** — ICLR 2026; Apache-2.0, about 1.4k stars, updated in May 2026, and given headless CLI mutators for subscription-backed harnesses. It evolves programs, prompts, and solution populations, but does not create agent organizations: [code](https://github.com/SakanaAI/ShinkaEvolve), [paper](https://arxiv.org/abs/2509.19349).

- **AI Scientist** — automates a scientific-work cycle: idea, code, experiment, paper, and review. The repository has about 14.7k stars and 98 commits, but uses a special Responsible-AI-like license rather than ordinary MIT/Apache. The system is limited to tasks expressible in code, and its own documentation warns about model dependence and reviewer bias: [code](https://github.com/SakanaAI/AI-Scientist).

- **AlphaEvolve and OpenEvolve** — Google's AlphaEvolve combines LLM program generation with an automatic evaluator and evolutionary selection; this is convincing evidence for F5 only where quality is measured objectively. AlphaEvolve is commercial and not self-hosted; [official description](https://deepmind.google/blog/alphaevolve-a-gemini-powered-coding-agent-for-designing-advanced-algorithms). OpenEvolve is Apache-2.0, with about 7.5k stars and 835 commits, but is an evolutionary coding agent, not a team manager: [repository](https://github.com/algorithmicsuperintelligence/openevolve).

- More direct work on self-organizing teams appeared in 2026. **Self-Organizing Agent Teams Learn to Reason Together** reports 66.7% versus 48.8% for the strongest single agent across five math and physics benchmarks; the gain is especially tied to whether the team can recognize correct reasoning. This strongly supports F3 when an observable quality function exists, but does not establish value for an arbitrary project: [paper](https://arxiv.org/abs/2609.22682).

- Reviews from 2025–2026 agree that models, memory, tools, workflows, topology, and multi-agent coordination can evolve, but evaluation, safety, and catastrophic context accumulation remain problems: [2025 review](https://arxiv.org/abs/2507.21046), [2026 review](https://arxiv.org/abs/2607.13104), [graph perspective](https://arxiv.org/abs/2608.18104). The name **MASS** is ambiguous; a primary work or mature project corresponding specifically to F3/F5 could not be verified — not checked.

Overall result: meta-agent teams and self-changing prompts really help when there is a benchmark, test set, executable evaluator, or reliable human feedback. For an open-ended project without ground truth, “work quality” by itself is too vague.

## 2. Practical prompt and skill optimization

**DSPy/GEPA** automatically generates instruction variants, runs them on train/validation examples, and keeps the best variant according to a given metric; GEPA additionally uses a textual explanation of the error. DSPy reports about a 75-fold cost reduction and a twofold reliability increase for one Shopify case, but this is the result of a specific metric and benchmark, not a universal law: [GEPA in DSPy](https://github.com/stanfordnlp/dspy/blob/main/docs/docs/getting-started/gepa-optimization.md). MIPRO performs similar black-box optimization. **TextGrad** spreads the idea of a “gradient” through textual feedback; the repository is MIT, with about 3.8k stars, but the latest commit date was not checked: [code](https://github.com/zou-group/textgrad).

The official **OpenAI cookbook** describes a self-evolving loop with a human or LLM judge, prompt versioning, and mandatory fallback on regression. The page is explicitly marked archived and is not a ready-made product: [cookbook](https://developers.openai.com/cookbook/examples/partners/self_evolving_agents/autonomous_agent_retraining).

Anthropic recommends `CLAUDE.md`, memory, skills, hooks, and subagents; Claude can append rules after user corrections. This is a useful F5 foundation, but the mechanism is mainly manual and local: [CLAUDE.md and memory](https://support.claude.com/en/articles/14553240-give-claude-context), [power-user guidance](https://support.claude.com/en/articles/14554000-claude-code-power-user-tips).

The closest practical projects are:

- **claude-reflect** — MIT, about 1.7k stars; hooks extract corrections from sessions, then `/reflect`, after confirmation, updates `CLAUDE.md` and skill files. This is real learning from execution traces, but not autonomous team optimization: [repository](https://github.com/BayramAnnakov/claude-reflect).

- **gstack** — MIT, about 135k stars, 424 commits; provides 23 predefined roles and `/retro`, which analyzes commits, velocity, and work patterns. It improves the process but does not invent a new team or change the schedule based on token usage: [repository](https://github.com/garrytan/gstack).

- **Compound Engineering** — MIT, about 25.4k stars; 36 skills, a “brainstorm → plan → build → review → capture” workflow, and support for Claude Code, Codex, OpenCode, and Antigravity. This is a good knowledge-accumulation layer, but the roles and cycle are designed in advance: [repository](https://github.com/EveryInc/compound-engineering-plugin).

- **Hermes Agent** — MIT, about 247.7k stars, 39,826 commits; can create and improve skills from experience, search past sessions, run cron, and run parallel subagents. This is the closest ready-made example of a self-improving agent, but not a manager of independent Claude/Codex/Gemini harnesses with subscription-quota redistribution: [repository](https://github.com/NousResearch/hermes-agent).

- **Letta** — Apache-2.0, about 25k stars, repository active; provides persistent memory, sleep-time compute, skills, and schedules. It improves an agent's state rather than building and re-optimizing an organization: [documentation](https://docs.letta.com/).

## 3. Ready-made products and closest analogues

**Paperclip** is closest to F1/F3/F4: the CEO receives a goal, forms strategy, breaks it into tasks, delegates, requests that new agents be hired, and runs on heartbeats. The repository is MIT, has about 97.5k stars, and is actively developed. However, its current roadmap still marks **Self-Organization** and **Automatic Organizational Learning** as future items; budgeting, evals, reviews, multi-model/multi-harness, and schedules are already implemented. Paperclip therefore nearly covers the `artel` shell but not F5: [core concepts](https://github.com/paperclipai/paperclip/blob/master/docs/start/core-concepts.md), [roadmap](https://github.com/paperclipai/paperclip).

**OpenClaw** is MIT, with about 391k stars and commits on 2026-10-05. It can create agent teams, subagents, and cron/automation jobs. This is strong ready-made F3 and scheduling infrastructure, but public materials do not show automatic analysis of transcripts, quality, and token consumption followed by team restructuring: [agents](https://docs.openclaw.ai/cli/agents), [cron](https://github.com/openclaw/openclaw/blob/main/docs/cli/cron.md).

**Crew Studio** can create a crew, workflow, and schedule from a business goal; **Relevance AI** lets users create subagents, multi-agent teams, and schedules. Both products focus on initial assembly and operation; no evidence was found of continuous self-optimization of prompts, composition, and budget: [Crew Studio](https://www.crewstudio.ai/features), [Relevance AI](https://relevanceai.com/docs/agent/customise-agent/schedule-messages).

Therefore, `artel` is worth building. The most rational niche is not another scheduler but an auditable meta-layer: versioned prompts and configurations, held-out evaluation, rollback, transcript sampling, F6 quotas, and a ban on the manager changing its own critical rules without independent review.

## 4. Main F5 risks

- **Prompt drift and memory growth.** A study of `CLAUDE.md` shows that instructions grow without limit: adding a rule is cheap, while removing it without losing context is difficult; the authors describe removal cost as exponential in document size. On a synthetic test, special comments reduced excess instructions by 99.3%: [study](https://arxiv.org/abs/2608.11095).

- **Manager degradation and loss of working prompts.** The current version cannot simply be overwritten. OpenAI recommends storing versions and falling back on regression; DGM uses an archive of variants and a held-out benchmark; claude-reflect requires human review before application. This points to immutable history, canary rollout, and automatic rollback: [OpenAI cookbook](https://developers.openai.com/cookbook/examples/partners/self_evolving_agents/autonomous_agent_retraining), [DGM](https://arxiv.org/abs/2505.22954).

- **Optimizing a proxy instead of the real result.** DSPy directly optimizes what the metric returns; AlphaEvolve works especially well where the evaluator is objective. For a long domain-agnostic project, token usage, number of closed tasks, or a positive LLM judge can easily become false objectives. Independent quality gates, human F7 escalation, and periodic blind/held-out checks are needed.

- **Self-modification of code and permissions.** ADAS warns that it runs model-generated code that can be destructive. If F5 is allowed to change prompts, skills, schedules, and helper scripts without a sandbox, the manager can silently expand its own permissions: [ADAS warning](https://github.com/ShengranHu/ADAS).
