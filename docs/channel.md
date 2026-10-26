# File channel for the concierge session

Protocol between the `artel` script (agent side) and the Claude concierge session (concierge).

```
channel/
  inbox/<id>.md        agent request: frontmatter + body
  outbox/<id>.md       response: frontmatter (status) + text
  archive/<id>/        closed inbox.md + outbox.md pair
  concierge.alive      concierge heartbeat (mtime), updated by `artel channel watch`
```

Inbox frontmatter: `id`, `type` (`message` | `request`), `agent`, `project`, `created`, `deadline` (for request,
ISO), `urgent` (true|false), `title`, `options`, `default`. Outbox frontmatter: `id`, `status` (`answered` |
`rejected` | `delivered`), `at`, `by` (the protocol allows `user` or `concierge`; the script does not validate the value).

Request lifecycle: the agent writes to inbox and waits for outbox until `deadline` → the concierge replies
(`artel channel reply`) → the agent reads it and moves the pair to archive. If the agent does not wait that long,
the inbox remains; the concierge's late reply goes to archive and to `journal.md` (`channel-answered`), the agent
does not see it, and the super agent will read it in the journal.
Messages (`message`) are closed by the concierge with status `delivered`; the pair immediately goes to archive.

All entries are atomic (temporary file and rename), so incomplete files must not be read.
