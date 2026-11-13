# Run log fixtures

Logs of one small run per harness, in the form `artel run` writes them to `agents/state/logs/<agent>/`, read by
`tests/telemetry-smoke.sh`. Captured on 2026-11-13 on macOS with the commands `build_harness_cmd` assembles
(claude 2.1.325 haiku, codex-cli 0.166.0 gpt-5.6-luna, agy 1.5.8 gemini-3.8-flash-low); paths, session ids and
the unused fields of the claude result line were replaced, the token figures are as reported.

| file | what it is |
|---|---|
| `claude.log` | one tool call and an answer; one model in `modelUsage` |
| `claude-subagent.log` | a haiku run that started one sonnet sub-agent: the top-level `usage` holds haiku only, `modelUsage` holds both |
| `codex.log` | a fresh `codex exec` |
| `codex-resume.log` | `codex exec resume` of the same thread: its `usage` is the total of both runs |
| `agy.log` | one `agy -p` call |
| `opencode.log` | synthetic, written by hand from the opencode 1.x event shape; replace it with a captured log when a working opencode is at hand |

To refresh a fixture after a harness changes its output, run the agent once and copy its log from
`agents/state/logs/`; `artel run <agent> --dry-run --replay-log <file>` prints the record artel reads from it.
