> Report prepared on 2026-10-27 by Claude Code (claude-opus-5-5) as lead. Four sonnet sub-agents searched in
> parallel (vendor libraries, community collections, domain libraries, evidence on third-party skills) and
> proposed 168 repositories. The lead re-checked every candidate through the GitHub API (stars, licence, last
> push, archived flag, number of `SKILL.md` files, scripts and hooks inside skill directories), read the licence
> files where the API reported none, and sampled eight `SKILL.md` files from each recommended repository for
> spec conformance. Numbers are as of 2026-10-27; star counts are an adoption signal only and were not audited.

# Third-party skill libraries: which to vendor into artel and how a project activates them

## Conclusion
artel should vendor 31 curated skill libraries as git submodules under `skills-lib/`, pinned to a commit and
**not fetched by default**: each submodule has `update = none` and `shallow = true`, so cloning artel (or a
project that has artel as a submodule) stays as light as today. A committed index lists every skill of every
library at its pinned commit (library, path, name, description, licence, scripts yes or no), so the installer
and the super agent choose skills by reading one file, then fetch only the libraries they need. A project
activates individual skills, never a whole library: a symlink from the project's `skills/` into
`artel/skills-lib/...` for a skill used as is, or a copy with a provenance header when the super agent adapts
it. The evidence says a large library makes agents worse through wrong skill selection, and that scanners
cannot certify a third-party skill, so the activation step is small and reviewed, and a pin moves only by an
explicit bump whose diff someone reads. Libraries outside the 31 go into a "known sources" list in the same
index file: the super agent may propose one for its project after the same review, and a library that proves
useful across projects is promoted into `skills-lib/` here.

## 1. What artel needs from a skill library
- **Portable format.** All four harnesses load Agent Skills directories (`SKILL.md` with `name` and
  `description`). Claude Code reads `.claude/skills`; Codex, opencode and agy read `.agents/skills`; opencode
  reads both. `artel link` already symlinks the project's `skills/` into every harness directory, so a skill
  placed in `skills/` reaches all four. Plugins do not port: Claude hooks, commands and MCP configurations do
  nothing in the other harnesses, and each harness has its own plugin manifest. artel vendors skill directories
  only, even when the upstream ships them inside a plugin layout (`plugins/<p>/skills/<s>/SKILL.md`).
- **Authority and maintenance.** Unattended runs cannot ask whether a skill is trustworthy. A vendor, an
  established company or a known practitioner, a push within the last three months, and a clear licence are
  the entry conditions.
- **Breadth.** artel projects are not only software: research, data analysis, operations, marketing, legal and
  finance pipelines are in scope, so the list covers knowledge work and science as well as engineering.
- **No runtime of its own.** artel is the orchestrator; a library that installs its own agent runtime, hooks or
  daemon competes with it.

## 2. Evidence that shapes the design
- **Curated skills help, self-written ones hurt.** SkillsBench: curated skills +16.6 points on average,
  self-generated ones below no skills at all. The same paper measured +18.0 points with one skill per task,
  +19.0 with two or three and +10.1 with four or more (report 07, section 5).
- **More skills, worse agents.** An ICML 2026 workshop study measured up to 21% lower pass rates going from the
  known-helpful skills to a 202-skill library; the cause is skill shadowing (the wrong skill chosen), while the
  context cost was indistinguishable from zero (checked). Claude Code lists skill descriptions within 1% of the
  context window and drops the descriptions of least-used skills on overflow; Codex caps the list at 2% and then
  omits skills with a warning (both checked). So a project must activate a small set, not whole libraries.
- **Scanners are not a gate.** Snyk reviewed 3,984 marketplace skills: 13.4% had a critical issue and 76 were
  confirmed malicious, every one of them with bundled scripts (checked). Trail of Bits bypassed ClawHub's
  scanner, Cisco's skill-scanner and all three skills.sh scanners in under an hour for three of four attacks:
  payload pushed past the scan window, payload only in a `.pyc`, instructions hidden in a `.docx`, prompt
  injection against the LLM judge (checked). A study of 238,180 skills found that marketplace scanners flag up
  to 46.8% while repository context leaves about 0.5% suspicious, and named a new vector: hijacking skills that
  live in abandoned repositories (checked). Anthropic's own guidance is to use skills from trusted sources only
  and to audit every bundled file (checked).
- **Pin, do not float.** Rug pulls and abandoned-repo takeover make a tracked branch unsafe. `npx skills`
  (vercel-labs/skills) records a content hash or a tree SHA but no commit, so it detects change without
  reproducing an install. A git submodule pins a commit, shows the diff of a bump and keeps the upstream licence
  files next to the skills.
- **Privilege fields.** `allowed-tools` pre-approves tools without a prompt and `hooks` registers session hooks
  in Claude Code; in a third-party skill both are privilege grants to review. 8 of the 31 recommended libraries
  use `allowed-tools` in the sampled files.

Sources: SkillsBench https://arxiv.org/abs/2602.12670; "More Skills, Worse Agents?" https://icml.cc/virtual/2026/77891;
Snyk ToxicSkills https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub; Trail of Bits
https://blog.trailofbits.com/2026/06/03/the-sorry-state-of-skill-distribution/; Holzbauer et al.
https://arxiv.org/abs/2603.16572; Malicious Agent Skills in the Wild https://arxiv.org/abs/2602.06547;
Anthropic skills overview https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview; Claude
Code skills https://code.claude.com/docs/en/skills; Codex skills https://learn.chatgpt.com/docs/build-skills;
opencode skills https://opencode.ai/docs/skills/; agy skills https://antigravity.google/docs/skills.

## 3. Libraries to vendor as submodules (31)
Columns: stars, licence as GitHub reports it, last push, `SKILL.md` count, script files inside skill
directories, hook files anywhere in the repository. "Sample" is the result of reading eight random `SKILL.md`
files: a name that differs from its directory, a body over 500 lines, a missing frontmatter.

### core · engineering method and skill authoring
| repository | stars | licence | push | skills | scripts | hooks | why, and what to watch |
|---|---|---|---|---|---|---|---|
| anthropics/skills | 184,170 | per skill | 2026-10-09 | 20 | 77 | 0 | Reference library of the spec owner: skill-creator, mcp-builder, webapp-testing, frontend-design, office documents. `docx`, `pdf`, `pptx`, `xlsx` are "all rights reserved" under Anthropic's terms; the rest are Apache-2.0 |
| openai/skills | 28,342 | per skill (Apache-2.0) | 2026-09-08 | 44 | 61 | 0 | Codex's curated catalog (`skills/.curated`) and system skills; one sampled body over 500 lines |
| obra/superpowers | 306,133 | MIT | 2026-10-23 | 15 | 6 | 3 | Planning, TDD, systematic debugging, review as small linked skills. Injects itself through hooks and has optional telemetry: vendor `skills/` only |
| addyosmani/agent-skills | 111,030 | MIT | 2026-10-13 | 25 | 1 | 0 | Lifecycle skills (spec, plan, build, test, review, ship, performance); ships Codex, Gemini and opencode layouts |
| mattpocock/skills | 304,680 | MIT | 2026-10-27 | 38 | 3 | 0 | Small composable engineering and productivity skills; easy to adapt |
| getsentry/skills | 1,091 | Apache-2.0 | 2026-10-26 | 30 | 9 | 0 | What one engineering team uses daily: commits, PRs, code and security review |
| EveryInc/compound-engineering-plugin | 25,735 | MIT | 2026-10-27 | 43 | 55 | 3 | Plan, build, review and "capture what this change taught", close to artel's journal loop |
| wshobson/agents | 41,870 | MIT | 2026-10-26 | 185 | 8 | 6 | Language and framework specialists in 94 plugins; native Codex, opencode and Antigravity targets |

### work · knowledge work outside software
| repository | stars | licence | push | skills | scripts | hooks | why, and what to watch |
|---|---|---|---|---|---|---|---|
| anthropics/knowledge-work-plugins | 33,382 | Apache-2.0 | 2026-10-27 | 252 | 26 | 0 | Role plugins: sales, finance, legal, support, product, data, operations |
| anthropics/financial-services | 40,850 | Apache-2.0 | 2026-09-21 | 112 | 8 | 4 | Earnings, modelling, research workflows; sample: one name mismatch, two bodies over 500 lines |
| anthropics/claude-for-legal | 9,805 | Apache-2.0 | 2026-10-23 | 151 | 0 | 10 | Contract, corporate, litigation and compliance workflows |
| coreyhaines31/marketingskills | 56,845 | MIT | 2026-10-26 | 52 | 28 | 0 | CRO, copywriting, SEO, analytics, pricing, launches |
| phuryn/pm-skills | 27,432 | MIT | 2026-10-16 | 69 | 0 | 0 | Product discovery, strategy, execution; instruction-only |

### research · science, ML and academic work
| repository | stars | licence | push | skills | scripts | hooks | why, and what to watch |
|---|---|---|---|---|---|---|---|
| K-Dense-AI/scientific-agent-skills | 54,921 | MIT | 2026-10-26 | 177 | 536 | 0 | Bioinformatics, chemistry, data analysis, scientific databases, literature. 460 MB repository: fetch shallow |
| Orchestra-Research/AI-Research-SKILLs | 14,005 | MIT | 2026-10-11 | 98 | 2 | 0 | Training, fine-tuning, evaluation, interpretability. Sample: two name mismatches, one missing frontmatter, two long bodies |
| huggingface/skills | 11,222 | Apache-2.0 | 2026-10-23 | 26 | 48 | 0 | Datasets, training jobs, evaluation on the Hugging Face stack; names Codex and Gemini CLI |
| Galaxy-Dawn/claude-scholar | 5,915 | MIT | 2026-10-19 | 45 | 41 | 1 | Literature review, ideation, experiments, paper writing; two sampled bodies over 500 lines |
| posit-dev/skills | 547 | MIT | 2026-10-15 | 30 | 1 | 0 | R and Python data science, Quarto, Shiny: the only authoritative data-science library found |

### security
| repository | stars | licence | push | skills | scripts | hooks | why, and what to watch |
|---|---|---|---|---|---|---|---|
| trailofbits/skills | 7,838 | CC-BY-SA-4.0 | 2026-10-27 | 97 | 88 | 28 | Audits, static analysis, smart contracts, fuzzing. Share-alike: an adapted copy keeps CC-BY-SA |
| trailofbits/skills-curated | 523 | CC-BY-SA-4.0 | 2026-07-14 | 31 | 24 | 1 | Third-party skills that Trail of Bits reviewed before listing: the curation model artel follows |

### platform · fetched only when the project uses the platform
| repository | stars | licence | push | skills | scripts | hooks | why, and what to watch |
|---|---|---|---|---|---|---|---|
| google/skills | 21,615 | Apache-2.0 | 2026-10-27 | 180 | 188 | 0 | Google Cloud, Ads, Firebase; targets Gemini CLI, Antigravity, Codex and Claude Code |
| aws/agent-toolkit-for-aws | 3,309 | Apache-2.0 | 2026-10-27 | 195 | 335 | 5 | AWS services |
| microsoft/azure-skills | 1,599 | MIT | 2026-10-27 | 93 | 150 | 80 | Azure scenarios; heavy hook and MCP packaging that artel ignores |
| cloudflare/skills | 3,188 | Apache-2.0 | 2026-10-19 | 19 | 5 | 0 | Workers, Durable Objects, R2; names opencode and Codex |
| vercel-labs/agent-skills | 33,098 | MIT (README only) | 2026-10-27 | 9 | 92 | 0 | React and web performance practice; no licence file, four of eight sampled names differ from their directory |
| hashicorp/agent-skills | 910 | MPL-2.0 | 2026-10-05 | 20 | 1 | 0 | Terraform, Packer, Vault |
| pulumi/agent-skills | 78 | Apache-2.0 | 2026-10-09 | 17 | 2 | 0 | Infrastructure as code; small adoption but the vendor's own |
| dotnet/skills | 5,743 | MIT | 2026-10-27 | 114 | 1 | 0 | .NET and C#: test, MSBuild, Blazor, MAUI. 486 MB repository: fetch shallow |
| expo/skills | 3,288 | MIT | 2026-10-26 | 25 | 11 | 0 | React Native through Expo and EAS |
| googleworkspace/cli | 31,941 | Apache-2.0 | 2026-10-26 | 95 | 0 | 0 | Drive, Gmail, Sheets, Calendar through the `gws` CLI: office operations |
| NVIDIA/skills | 3,759 | Apache-2.0 | 2026-10-27 | 418 | 978 | 26 | CUDA, RAPIDS, inference: projects with a GPU in the container. Three sampled name mismatches |

Spec conformance over the 248 sampled files: no description over 1,024 characters and no BOM; 10 names that
differ from their directory (in four libraries), 2 files without frontmatter, 11 bodies over 500 lines.
Harness claims ("supports Codex, Antigravity, opencode") come from READMEs and were not tested.

## 4. Known sources: in the index, not submodules
The super agent may propose any of these for its project (section 5 applies); the reason each is not a
submodule is given.

| repository | reason it is a known source only |
|---|---|
| datadog-labs/agent-skills, elastic/agent-skills, mongodb/agent-skills, neondatabase/agent-skills, prisma/skills, supabase/agent-skills, stripe/ai, getsentry/sentry-for-ai, browserbase/skills, apify/agent-skills, microsoft/playwright-cli, google/agents-cli, google-labs-code/stitch-skills, figma/mcp-server-guide | vendor libraries for one product; relevant to few projects; figma, browserbase and apify ship no licence file |
| microsoft/skills | Azure SDK grounding that overlaps microsoft/azure-skills; 79 hook files |
| openai/plugins | 536 skills, mostly third-party product plugins for Codex; no licence file |
| openai/codex-security, cloudflare/security-audit-skill, anthropics/defending-code-reference-harness | security products with a single skill or a harness of their own |
| anthropics/claude-plugins-official, anthropics/healthcare | Claude plugin marketplaces; healthcare has no licence file |
| garrytan/gstack | strong engineering-role skills, but its own runtime: Bun, a browser daemon, hooks and 384 scripts |
| Fission-AI/OpenSpec, github/spec-kit, bmad-code-org/BMAD-METHOD | spec-driven methods with their own CLIs and project layout that compete with artel's planning files; BMAD licence unclear |
| kepano/obsidian-skills, nextlevelbuilder/ui-ux-pro-max-skill | one tool each (Obsidian, a design CLI installer) |
| deanpeters/Product-Manager-Skills, RefoundAI/lenny-skills | product management alternatives to phuryn/pm-skills; deanpeters licence unclear |
| aaron-he-zhu/aaron-marketing-skills, himself65/finance-skills, JoelLewis/finance_skills | single practitioners; second sources for marketing and finance |
| ClawBio/ClawBio, nextflow-io/agent-skills | bioinformatics beyond K-Dense; ClawBio licence unclear and 152 MB |
| lawve-ai/awesome-legal-skills | 281 skills by individual lawyers, per-skill licences, unclear repository licence |
| Imbad0202/academic-research-skills | five skills, licence unclear |
| mukul975/Anthropic-Cybersecurity-Skills | 818 skills by one person with 1,096 scripts: too large to review |
| Jeffallan/claude-skills, alirezarezvani/claude-skills | broad individual collections that overlap the core libraries |

Discovery sources (read, never vendored): VoltAgent/awesome-agent-skills (curated by publisher),
hesreallyhim/awesome-claude-code, github/awesome-copilot (465 community skills of varying quality), skills.sh.
Tools worth knowing: agentskills/agentskills (the spec and the `skills-ref` validator), NVIDIA/SkillSpector and
Cisco's skill-scanner (useful signals, not a gate), vercel-labs/skills (`npx skills`, no commit pin).

Rejected: aggregators that copy other repositories' skills without curation (sickn33/agentic-awesome-skills,
ComposioHQ/awesome-claude-skills, composio-community/awesome-codex-skills, davila7/claude-code-templates,
jeremylongshore/tons-of-skills-marketplace, rmyndharis/antigravity-skills); runtimes that compete with artel
(affaan-m/ECC, Yeachan-Heo/oh-my-claudecode, Yeachan-Heo/oh-my-codex, code-yeongyu/oh-my-openagent); archived or
obsolete (GPTomics/bioSkills, malhashemi/opencode-skills, numman-ali/openskills); unvetted registries
(ClawHub, skillsmp.com, claudemarketplaces.com). No authoritative library was found for Kubernetes and SRE,
education, or notebooks; anthropics/knowledge-work-plugins and posit-dev/skills cover part of the gap.

## 5. How a project uses the libraries
1. **Index.** `skills-lib/index.tsv` in artel lists every skill of every submodule and every known source at
   its pinned commit: library, path, name, description cut to 200 characters, licence, whether it bundles
   scripts, whether its frontmatter carries `allowed-tools` or `hooks`. It is generated from the GitHub API
   (no clone needed) and regenerated with every pin bump. The 31 submodules hold 2,725 skills at the current pins.
2. **Choice.** The installer picks the library groups that match `goal.md` (a research project gets
   `research`, a web product gets `core` and its `platform` entries) and fetches them. The super agent then
   picks skills per project and records each choice with its reason in `agents/environment.md`. The number of
   active skills is a cost: start with a handful and add one when a run shows the need.
3. **Review before activation.** A skill with scripts, `allowed-tools`, `hooks`, binaries or archives is read in
   full by the super agent (a strong model) before it is linked; an instruction-only skill from a `core`
   library may be linked after reading its `SKILL.md`. A known source enters the project as the project's own
   submodule under the same rule, never as a tracked branch.
4. **Activation.** Used as is: a symlink `skills/<name>` to `artel/skills-lib/<lib>/<path>`, so it follows the
   artel pin. Adapted: a copy in `skills/<name>` whose frontmatter `metadata` names the upstream library,
   commit and path, kept under the upstream licence. An adaptation is a change to a curated skill, measured
   like an identity tuning (report 07, section 8, item 4): hypothesis, metric, rollback. This is what keeps it in the
   "curated" arm of SkillsBench rather than the "self-generated" one.
5. **Bump.** Pins move here, in artel, by an explicit commit after reading the upstream diff (new scripts,
   hooks, changed privilege fields). A project picks the bump up with `artel update`; adapted copies are
   compared with the new upstream and the super agent decides whether to rebase them.

## 6. Open questions
- agy and opencode symlink handling inside skill directories is undocumented; `artel link` already relies on
  symlinks for the `super` skill, so a Linux test of a symlinked vendored skill settles it.
- Per-agent skill sets: today `skills/` is shared by every agent of a project; a worker that needs three
  skills still sees all of them. Per-agent skill directories would lower shadowing; measure first.
- The four Anthropic document skills are licensed under Anthropic's terms; whether using them from Codex, agy
  or opencode is covered was not checked. Until it is, a project uses them from Claude Code only.
- Star counts for several repositories (over 300,000 for two individual collections) were not audited and are
  not a quality measure; the selection rests on maintainer, activity, licence and the sample read.

## Sources and method
Candidate lists, the verification script output (`gh api repos/<r>` and the recursive git tree per
repository) and the sample results were kept in the session scratchpad and are summarised in the tables above;
anyone can reproduce a row with `gh api repos/<owner>/<repo>` and
`gh api "repos/<owner>/<repo>/git/trees/<branch>?recursive=1" --jq '[.tree[].path | select(endswith("/SKILL.md"))] | length'`.
