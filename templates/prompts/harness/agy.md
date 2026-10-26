---
name: harness/agy
description: How to run the Antigravity CLI (agy, Gemini models) headless as a worker or consultant: the -p= form, --add-dir instead of cwd, permissions, flash/pro models and effort, empty-success checks, token accounting, two independent quotas, conversation continuation, and restrictions on expensive sub-agents.
---

# Antigravity CLI (`agy`, Gemini) as a worker

Tested with `agy` 1.4.x (1.4.7, 2026-10-25), Linux. Paid through a Google AI Pro subscription: two independent
quota groups, “Gemini Models” and “Claude and GPT models,” each with 5-hour and weekly windows. Snapshot:
`agy -p=/quota --output-format json` (and `/credits`), without an agent turn or charge. Quota is deducted
proportionally to token cost, so Flash uses it several times more slowly than Pro.

## Single-turn call
```bash
agy -p="<prompt with absolute paths>" --model gemini-3.8-flash-high \
  --add-dir /abs/path/project --dangerously-skip-permissions \
  --output-format json --print-timeout 20m 2>err.txt | tail -1
```
Three traps, each costing time:
1. **`-p` only with `=`.** Bare `-p "text"` may consume the next flag as the prompt.
2. **agy ignores cwd.** Its shell runs in `~/.gemini/antigravity-cli/scratch`. Only `--add-dir` sets the working
   directory, and paths in the prompt itself must be absolute. Otherwise files and tests go to scratch and the
   project remains untouched.
3. **Without permissions, a turn ends in empty “success.”** In headless mode, a tool that writes or runs a command is
   auto-rejected, the status remains `SUCCESS`, `response` is empty, and stderr contains a permission hint. Any work
   involving edits requires `--dangerously-skip-permissions`; `--mode accept-edits` permits file writes only, while
   shell commands are still blocked.

Other details: `--print-timeout` defaults to 5 minutes; increase it for a real task. Put long text in a file under
`--add-dir` and reference it by path rather than using `-p="…"`. If the prompt may begin with a slash, add
`--disable-slash-commands`.

## Result check
With `--output-format json`, the last line is JSON: check `status == "SUCCESS"` **and** a non-empty `response`, or
you will mistake an auto-rejection for success.
```bash
tail -1 out.json | python3 -c 'import sys,json; d=json.load(sys.stdin)
ok = d.get("status")=="SUCCESS" and (d.get("response") or "").strip()
print("OK" if ok else "FAIL", json.dumps(d.get("usage"), ensure_ascii=False))'
```

## Models and effort
| slug | role |
|---|---|
| `gemini-3.8-flash-low/medium/high` | Flash: seconds and pennies, the main inexpensive worker |
| `gemini-4-argon-low/medium/high` | higher-end next-generation model (replaced Pro 3.1 and Flash 3.7, no longer in the list): depth, more expensive than Flash |
| `claude-sonnet-5-5-*`, `claude-opus-5-5-*`, `gpt-oss-120b-medium` | their own quota group, unrelated to the Anthropic subscription |

Effort is either encoded in the slug or supplied with `--effort low|medium|high` over the base model. Flash is almost
always better value than the higher-end model; use Argon when maximum depth is needed. Its consumption has not been
measured yet, so compare the quota share before and after. List models with `agy models` (login required). Modes are
`--mode accept-edits | auto | plan`; headless work involving edits still requires `--dangerously-skip-permissions`
(see trap 3).

## Token accounting
`usage`: `input_tokens`, `output_tokens` (including `thinking_tokens`), `cache_read_tokens`, and `total_tokens`.
Traps: `input_tokens` **does not include** `cache_read_tokens` (codex includes it), and `total_tokens` also excludes
cache. Sub-agent spend is not included in the parent's `usage` and is not visible anywhere.

## Continuing a conversation
The first turn returns `conversation_id`; the next uses `--conversation "$id"`, even from another process.
`--continue`/`-c` takes the newest conversation and is unsafe in automation. One agy process is one conversation and
one folder, with turns strictly sequential. For parallel subtasks, use N processes with different `--add-dir` values.

## Sub-agents
agy has its own sub-agents (`invoke_subagent`, types in `.agents/agents/<name>.md`, field
`model: flash | pro | inherit`). Keep them on `flash` with effort no higher than `high`: `inherit` on argon multiplies
expensive context, and child spend is not visible anywhere. For external subtasks, it is simpler to launch parallel
processes.

## Common failures
- Empty SUCCESS: check stderr first (permission hint), then permissions.
- “Hung”: `--print-timeout` expired (5 minutes by default).
- File created in the wrong place: missing `--add-dir` or a relative path in the prompt.
- Login error in stderr: interactive login is required (`agy`, then `/login`); escalate.
- The Gemini group quota is exhausted while Claude/GPT is not: temporarily move the worker to
  `claude-sonnet-5-5-*` through agy or to another harness.
