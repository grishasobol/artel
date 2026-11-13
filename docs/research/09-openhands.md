> Report prepared on 2026-11-13 by Claude Code (claude-fable-5-2) in the main session. Three sonnet sub-agents
> fetched pages for it: 22 pages of `docs.openhands.dev`, one blog post, the abstract of the SDK paper and three
> source files of `OpenHands/software-agent-sdk` (`stuck_detector.py`, `types.py`, the first 40 KB of
> `local_conversation.py`). The lead compared their reports with this repository and checked the claims about
> the installed harness CLIs on macOS (claude 2.1.325, codex-cli 0.166.0, agy 1.5.8). OpenHands was at v1.36.0
> (2026-11-05) with agent-server 1.60.1. No OpenHands code was run. Statements marked (docs) come from the
> documentation, (code) from the source files, (checked) from a command run for this report.

# OpenHands: what artel shares with it and what to port

## Conclusion
OpenHands and artel sit on different layers and overlap in a narrow strip. OpenHands is an agent runtime: its
own reason-act loop over model APIs, an append-only event log, a sandboxed workspace, a server and a UI, with a
cloud and an enterprise product around it. artel has no loop of its own: it runs four vendor harnesses on
subscriptions and manages who works, when, and on whose quota, over weeks. OpenHands has nothing for
subscription windows, a standing team with identities and a plan, slots, or a manager that reshapes the team;
artel has nothing for a sandbox, an event log or a UI and does not need them.

artel should not be rebuilt on OpenHands. Since June 2026 OpenHands can drive Claude Code, Codex and Gemini CLI
on a subscription through the Agent Client Protocol, but for such an agent its own machinery is switched off:
what remains is a transport and a usage record, bought with an agent server and third-party adapters.

Five mechanisms are worth porting, each rewritten for artel's level (a run of a harness, not a step of a loop):
a repetition guard for runs and for the consilium, a token budget per run for every harness with spend split by
model, prompt modules attached by file path instead of inlined into every identity, a failover harness for
transient failures, and a written recipe for runs on external events that needs no webhook server. They form
phase 14 of `todo.md`. Three ideas were examined and not taken (section 5).

## 1. What OpenHands is today
- **Packages.** `openhands.sdk` (Agent, Conversation, LLM, Tool, MCP, events), `openhands.tools`,
  `openhands.workspace` (local, Docker or hosted execution) and `openhands.agent_server` (REST and WebSocket).
  The agent is a stateless `step()`: pending actions, condenser, model call, confirmation check, execution.
  Events are immutable and the log is append-only, so a conversation can be paused, resumed and replayed (docs).
- **Products.** The open-source application with Agent Canvas, OpenHands Cloud, and OpenHands Enterprise, where
  the GitHub event automations and budget dashboards live (docs).
- **External agents.** `ACPAgent` and Agent Canvas start an ACP server as a subprocess and speak JSON-RPC over
  stdio: `npx -y @agentclientprotocol/claude-agent-acp`, `npx -y @zed-industries/codex-acp`,
  `npx -y @google/gemini-cli --acp`, plus Pi and `opencode-ai acp` on local backends only. A CLI login takes
  priority over an API key; containers receive the login through environment variables (docs).
- **Automations.** A scheduled or event-triggered run gets a fresh sandbox and a new conversation that is saved
  and can be continued by hand. Nothing carries state from one run to the next except what the prompt itself
  writes somewhere (docs).

## 2. Overlap with artel
| concern | OpenHands | artel | verdict |
|---|---|---|---|
| unit of work | conversation: a loop of model calls in a sandbox | run: one harness process in a slot with a window | different layers |
| who pays | API keys by default; subscriptions through ACP | subscriptions; quota snapshot of four harnesses | artel's core, absent there |
| state between runs | none by design | plan, journal, spheres, `agents/` history | artel's core, absent there |
| schedule | cron automations, natural-language definition | `systemd --user` timers from `config.yaml`, slots, queue | same idea, artel's is richer |
| event triggers | hosted webhook endpoint with HMAC check and JMESPath filters | `watch_paths` planned (08-01); webhook server rejected | take the recipe, not the server (4.5) |
| stuck runs | detector over the event log, four live patterns | failure streak of three; "blocked" repeats unnoticed | port (4.1) |
| spend limit | USD per run over every model used | `max_budget_usd`, claude only | port as tokens (4.2) |
| context on demand | keyword skills, path-scoped rules | whole identity read every run | port path scoping (4.3) |
| model failure | per-call fallback list on transient errors | super agent redistributes by hand, hours later | port as harness failover (4.4) |
| sub-agents | task tool, synchronous, model of the parent | banned on strong models by the charter | nothing to take |
| history compaction | condenser at 120 events | done by each harness itself | not applicable |
| isolation | Docker or hosted sandbox per conversation | one Incus container per project | not applicable |

## 3. Why artel is not built on OpenHands
- **An ACP agent loses the runtime.** With `ACPAgent`, `tools`, `mcp_config`, `condenser` and `critic` raise
  `NotImplementedError`; skills reach the agent only as prompt text; permission requests of the ACP server are
  granted automatically. The stuck detector, the security analyzer and the confirmation policy work on
  OpenHands tool events, which an ACP agent does not produce. What survives is the transport, the conversation
  store and usage metrics taken from `PromptResponse.usage` and `UsageUpdate` (docs).
- **It adds what artel refused.** An agent server and `npx` adapters are a daemon and a second package
  ecosystem inside the container; artel's reliability rests on `systemd --user`, `flock` and the file system,
  and `bin/artel` is one file on the standard library (`todo.md`, Deferred).
- **Harness flags do not carry over.** artel controls each harness by its own command line: effort, the lean
  tool list, `--strict-mcp-config`, the sub-agent model pin. Whether the adapters pass any of these through is
  not documented, and for Claude Code and Codex the adapters are third-party packages: neither CLI has an ACP
  server of its own, while `agy acp` and `opencode acp` exist (checked).
- **It would not buy the missing part.** Quota windows, slots, the plan and the super agent would still have to
  be written on top.

## 4. Mechanisms worth porting

### 4.1 Repetition guard
**There.** The detector looks at the last 20 events after the last user message and compares events by
content, ignoring ids and timestamps. Defaults: the same action with the same observation 4 times; the same
failing action more than 3 times, with one nudge message to the agent at exactly 3; 3 agent messages in a row
without an action; two action-observation pairs alternating over 6 events. A fifth pattern, repeated
context-window errors, is listed in the documentation and is a stub that always returns false. On a hit the
conversation goes to status `STUCK` and `run()` returns without an exception; the next user message resumes it
(code).

**For artel.** The observed loop is one level up: an agent journalling the same "blocked" every two hours,
190K to 385K input tokens each time (`todo.md`, finding 2). The failure streak does not see it, because such a
run exits zero. Three guards follow, each a count over records artel already has or will have after 06-01:
- across runs: the same agent and task ending `blocked` or `noop` on the same step ids several times in a row
  pauses the agent exactly as three failures do, with an escalation;
- inside a run: the same tool call with the same result, or the same failing call, repeated in the harness
  stream ends the run as `killed`. Thresholds start from the OpenHands defaults and are config fields, not
  constants, because a harness loop may legitimately poll;
- in a consilium: the same voter objecting to two finals in a row, or a full circle whose messages repeat the
  previous one, raises an early `checkpoint` event with the pattern named. The driver ends nothing itself: the
  user rejected built-in caps, so the operator decides.

The nudge-before-stop detail is worth keeping where artel can speak to the agent: the consilium driver can; a
headless run cannot without a live session, so there the guard only stops and journals.

### 4.2 Budget per run, spend by model
**There.** `max_budget_per_run` is a USD limit compared with the accumulated cost of the conversation after
every step; the cost includes every LLM the conversation used (agent, condenser, fallbacks). Metrics are keyed
by a usage id per LLM (docs).

**For artel.** `max_budget_usd` exists for claude only and dollars mean little on a subscription. Once 06-01
reads usage from all four streams, the same reader can enforce `max_tokens` per agent or task and end the run
as `killed` with the reason in the journal. The second half matters more to this project: spend keyed by
model. A claude result already carries `modelUsage`, one entry per model with input, output and cache tokens,
and `subagent_stats` (checked on 2.1.325). Recorded in `runs.jsonl`, it lets `artel stats` flag a run in which
a second model above the cheap tier appears, which is how a strong-model sub-agent shows up, without reading
any transcript.

### 4.3 Prompt modules attached by path
**There.** A rule with `paths:` globs in its frontmatter costs nothing until the agent reads, edits or creates
a matching file; then it is injected once per conversation into that tool result. Keyword-triggered skills are
matched against user messages (docs).

**For artel.** The reading tax (finding 1) includes project knowledge that the super agent distils into every
identity whether or not the run touches that area. artel cannot inject into a harness tool result, but it
builds the brief (05-01): a project module in `agents/prompts/` with `paths:` is named in the brief only when
the paths written in the agent's active steps match, and the identity stops inlining it. One mechanism for all
four harnesses, no dependence on how each loads nested instruction files.

### 4.4 Failover harness
**There.** `fallback_llms` are tried in order on transient errors only (rate limit, timeout, connection);
authentication errors and bad requests are raised at once; every new request starts from the primary model
again; fallback spend is merged into the primary's metrics (docs).

**For artel.** A run that dies on an exhausted window or a rate limit is today a failure that waits for the
next super iteration. A task-level `fallback:` (harness, model, effort) lets `artel run` start the same task
once on another subscription when the quota snapshot or the harness error says "transient", and never on a
login failure, which still goes to the user. The rule "each request starts from the primary" maps to: the next
scheduled run uses the primary again. Spend is recorded under the harness that did the work, unlike OpenHands,
because here the two harnesses draw on different subscriptions.

### 4.5 Runs on external events without a server
**There.** A webhook automation is registered through an API, receives POSTs on a hosted endpoint, checks an
HMAC-SHA256 signature of the raw body, extracts an event key and applies JMESPath filters. For services that
cannot reach the installation the documentation itself recommends a cron automation that polls the service
(docs).

**For artel.** A webhook server in the container was rejected, and the polling variant is what artel already
does better: a `prepare` script is the poller and the filter, it runs without a model and exits 3 when nothing
matched. With 08-01 a spool directory under `watch_paths` covers pushes delivered by anything outside artel.
What is missing is the written recipe in `artel/config`, so that a super agent reaches for a `prepare` poller
instead of a model that wakes up to look.

## 5. Examined and not taken
- **ACP as the single transport to all harnesses.** It would replace four output parsers with one usage format
  and give session forking. Against it: adapters for claude and codex are third-party `npx` packages, permission
  requests are auto-granted, and pass-through of artel's flags is unknown (section 3). Deferred until 06-01
  shows whether four parsers are a real maintenance cost.
- **Checkpoint report of the consilium lead in a forked session.** `ask_agent()` forks the ACP session so a side
  question leaves the conversation untouched. claude has `--fork-session` and codex has `exec fork`; agy has no
  fork (checked). The gain in the consilium is the six-line report staying out of the lead's context, against a
  third code path per harness. Deferred.
- **Inline risk rating and confirmation policy.** The acting model fills a required `security_risk` argument of
  every non-read-only tool, and a policy decides whether to ask (docs). artel does not own the tool schemas of
  the harnesses, and its runs are unattended; phase 12 covers the same ground with one-way doors and the write
  guard.
- **Condenser.** Each harness compacts its own history; artel's growth problem is in files, which phase 5
  bounds.
- **Task-based model routing.** The agent calls `route_task_to_model`, a classifier LLM picks a saved profile
  and the same conversation switches model (docs). A harness session cannot change model mid-run, and 07-01
  already lets a `prepare` script choose the model before the harness starts, without a classifier call.
- **Hooks.** `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `SessionEnd`, blocking on
  exit code 2: the Claude Code hook model. `verify:` (07-02) is artel's portable counterpart for the one hook
  that matters across harnesses, the check after the work.

## 6. What could not be verified
- No OpenHands code was run; behaviour is taken from documentation and three source files. The tail of
  `local_conversation.py` (about 26 KB) was not read.
- What an event-triggered run receives as input, and whether events are deduplicated or rate limited, is not
  stated in the documentation.
- Whether a sub-agent type can run on a model different from its parent's is not stated; every example passes
  the parent's LLM.
- Pass-through of harness flags by the ACP adapters, and usage reporting by `agy acp`, were not tested.
- The claim of the SDK paper that V1 reduces system-attributable failures was read in the abstract only.
- The thresholds proposed in 4.1 are OpenHands defaults for a step loop; nothing measures them on harness
  streams yet.

## Sources
- OpenHands documentation, `docs.openhands.dev`: `sdk/arch/overview`, `sdk/arch/agent`, `sdk/arch/events`,
  `sdk/arch/condenser`, `sdk/arch/security`, `sdk/arch/skill`, `sdk/guides/agent-acp`,
  `sdk/guides/agent-stuck-detector`, `sdk/guides/task-tool-set`, `sdk/guides/metrics`, `sdk/guides/llm-routing`,
  `sdk/guides/llm-task-routing`, `sdk/guides/llm-fallback`, `sdk/guides/hooks`,
  `openhands/usage/agent-canvas/acp-agents`, `openhands/usage/automations/overview`,
  `openhands/usage/automations/event-automations`, `enterprise/automations/github-events`, and the index
  `llms.txt`.
- "Controlling any Coding Agent with the OpenHands Agent Canvas and SDK", openhands.dev blog, 2026-06-18.
- "The OpenHands Software Agent SDK", arXiv 2511.03690 (abstract).
- `github.com/OpenHands/software-agent-sdk`, branch `main` on 2026-11-13:
  `openhands-sdk/openhands/sdk/conversation/stuck_detector.py`, `types.py`, `impl/local_conversation.py`.
- `github.com/OpenHands/OpenHands`, release v1.36.0.
- This repository: `todo.md` (consilium findings of 2026-10-27, phases 5 to 8 and 12, Deferred), `bin/artel`.
- Commands run for this report: `claude --help`, `codex --help`, `codex exec fork --help`, `agy --help`,
  `agy help acp`, `opencode --help`, and one haiku call with `--output-format json` to read the result fields.
