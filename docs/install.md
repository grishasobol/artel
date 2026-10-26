# Installing an artel user project

This document is followed by an LLM in the user's harness (claude, codex, agy, or opencode), opened in a clone
of the artel repository on a Linux machine. Entry point: the `/artel-create` skill. The document has two parts:
how to perform the installation in quiz mode and what the super agent is, which then runs the project.

## 0. Conduct

- **You are the installer.** Your job is to find out what the user wants, prepare a container with an agent team,
  and hand the work to the super agent. You do not write the project plan or assemble the agent team: the super
  agent does that on its first run (part 2).
- **The default path, not the only one.** Everything below is the default scenario: the image from
  `provision-base.sh`, a container from `artel-up.sh`, user `artel`, the home directory as the project, the
  first run of the super agent started by you. At any step the user may want something else: a container they
  already have (section 8), another user name, their own mounts and limits, a login done by hand, a different
  schedule. Follow their wish: use the scripts' options where they exist (`--user`, `--image`, `--mount`,
  `--skip`, `--only`) and skip a script when it does not fit; record every deviation in `agents/environment.md`
  so the super agent knows. What never changes is the end state in step 7: a working container, agents on the
  schedule, the cheat sheet in the user's hands.
- **The user is not an expert.** Not in Incus, artel, or possibly the project's subject area. Do not use
  technical terms without explaining them. Explain a "container" as a separate small computer inside this
  machine, where agents work and cannot break anything outside it. A "harness" is an agent program (Claude Code,
  Codex, Antigravity, OpenCode). A "quota" is how much work the subscription allows during a time window.
- **Quiz.** Ask one question at a time. For each question, offer a default option that can be accepted by saying
  "yes". Do not ask a question whose answer is already in what the user said or in the system. Before any action
  that installs or changes anything on the machine (installing packages, creating a container, copying keys), say
  in one sentence what you will do and wait for consent.
- **The user's words are material for `goal.md`.** Record their wording as close as possible to what they said:
  the super agent will rely on it as a constitution. Mark your own generalizations as your own.
- **Secrets.** Never read or print files containing keys or tokens (`~/.codex/auth.json`,
  `~/.claude/.credentials.json`, and similar). Scripts handle the transfer without showing them. If the user
  pasted a token into the chat, ask them not to do that again and to put it in a file.
- **Drafts.** Keep the user's answers and the `goal.md` draft in `~/.config/artel/<project-name>/` on the host
  (`answers.md`, `goal.md`) so an interrupted installation can continue. At the start, check whether an
  unfinished installation is there and offer to continue it.
- **Repository scripts.** Scripts from `install/` do all heavy work: building the image, creating the container,
  and authentication. Do not rewrite Incus commands by hand when a script exists. The paths below are relative to
  the root of the artel repository where you are running (`$ARTEL_REPO`).

## 1. Host

Check silently; tell the user only the result and what to do about it.

0. **Where am I.** If `incus` is missing and `systemd-detect-virt -c` prints `lxc` or `incus` (or `/dev/incus`
   exists), you are inside a container: this is the installation from inside, section 8, which replaces
   sections 1, 3 and 4. Otherwise you are on the host; continue.
1. **OS.** `uname -s`. Only Linux is supported. On macOS or Windows, explain that a Linux machine is needed
   (server, home computer, virtual machine) and stop: installation will not work there. The container runs around
   the clock afterward, so the machine must stay on continuously.
2. **Incus.** `command -v incus && incus version`. If missing, explain what it is and install it with permission.
   Ubuntu 24.04+ and Debian 13: `sudo apt install -y incus`. Other distributions: Incus developer packages
   (the Zabbly repository) following the official instructions
   (https://linuxcontainers.org/incus/docs/main/installing/). Then `sudo incus admin init --minimal` and
   `sudo usermod -aG incus-admin "$USER"`; the group takes effect after a new login (or `newgrp incus-admin`
   in the current shell). Check: `incus list` without sudo and without an error.
3. **Image network.** `incus image list images:ubuntu/24.04 --format csv | head -1` should return something.
4. **Resources.** `nproc`, `free -g`, `df -h /var/lib/incus /` (or wherever Incus stores data), and
   `nvidia-smi` if available. Remember for step 3: by default the container gets 8 GiB of memory and all cores;
   offer less if the machine is weak.
5. **Harnesses on the host.** For each of `claude`, `codex`, `agy`, `opencode`, check whether the command exists
   and whether login is complete (`claude auth status`, `codex login status`, `agy -p=/quota`, `opencode auth
   list`). This helps with step 5: it shows what can be transferred to the container automatically (except
   Claude: its container login always uses a `claude setup-token` token; see step 5). A missing harness is not a
   problem: claude, codex and opencode are installed in the image, agy is copied from the host when present.
6. **artel repository.** `git -C "$ARTEL_REPO" remote get-url origin`. If origin exists, the container clones
   from it; otherwise the script mounts this clone read-only and clones from it.

## 2. Project conversation

The goal of the conversation is the `goal.md` file. There is a template at `templates/home/goal.md`, but the form
is free-form: the user's exact words matter more than the sections. Ask questions one at a time, in this order,
skipping anything already known:

1. What should exist at the end? Let the user describe it in their own words; clarify if it is not clear what
   counts as a result (a working website, a written article, data collected every day).
2. Where are the code or materials? Three options: a repository already exists (address), a folder exists on
   this machine (path), or nothing exists (agents start from scratch). The folder is mounted in the container as
   `src/<name>`, and agents change files directly there; ask whether that is acceptable or whether a copy is better.
3. How would the user do this themselves? Let them explain what matters in the result. If the answer is short,
   ask separately: what annoys them about similar solutions, and what are they worried about?
4. How will you know it is ready? Ask for 2–5 signs that can be checked from the outside.
5. What must not be done? Give examples one at a time if the user has trouble: spend money, touch external
   services, delete data, publish, deploy to a production server.
6. Deadline: a date, or continuous work with no end?
7. When may agents work (for example, only at night), so they do not interfere with the user's use of the same
   subscriptions during the day?
8. What counts as "good enough" so agents do not polish forever?
9. How does the user want to receive messages: Telegram, or only through a Claude session in the app? If Telegram
   is chosen, a bot and chat ID are needed; explain how to get them (create the bot through @BotFather; any bot
   such as @userinfobot shows the chat ID).
10. Quiet hours when agents must not disturb the user?
11. How often is a report needed, and what counts as urgent (what to write about immediately, even at night)?
12. Project name: lowercase Latin letters, digits, and hyphens (for example, `my-site`). This becomes the name of
    the `artel-<name>` container and the `src/<name>` folder.

Write a `goal.md` draft to `~/.config/artel/<name>/goal.md`, show it to the user in full, and ask them to correct
it in their own words. This is their file: agents obey it and do not change it.

## 3. Container environment and limits

Explain that an `artel-<name>` container will be created, and clarify each item one at a time:

- **Memory and cores.** By default, `--mem 8GiB` and all cores; suggest figures based on the machine.
- **Mounts.** The code folder from question 2 (`--mount <host-path>:src/<name>`), plus other data folders
  (possibly `:ro`, read-only). Explain: agents can see and change everything mounted; everything else lives
  separately from the host inside the container and is preserved by its snapshots.
- **Display.** If the project needs a browser or windows (website tests, graphics): `--novnc <port>`. The
  container has a virtual display, and the user can view it in their browser at
  `http://<host>:<port>/vnc.html` (noVNC is a "display in the browser"). Each project gets its own port.
- **GPU.** `--gpu`, only if NVIDIA is available and the project needs it.
- **Harnesses and subscriptions.** Which of the four harnesses to use inside and what share of the quota agents
  may spend (for example, "at night, no more than 60% of Claude's weekly quota"). Record this in `goal.md`,
  section "Horizon and pace", using the user's words.

## 4. Image and container

1. **Image, once per host.** `incus image list artel-base --format csv`. If empty or the image has an old layout
   (`artel-up.sh` compares the image's `artel.layout` property with `install/inside/provision.sh` and refuses to
   start a container from an outdated one), with permission run `"$ARTEL_REPO"/install/provision-base.sh`
   (10–20 minutes: Ubuntu 24.04, user `artel` by default, another name with `--user <name>`, harnesses claude,
   codex, opencode, virtual display, and storage for agy login keys). The `agy` program is copied from the host if installed there; otherwise it can be installed
   in the container later.
2. **Container.** `"$ARTEL_REPO"/install/artel-up.sh <name> [--mount …] [--mem …] [--cpu …] [--novnc …]
   [--gpu] [--user <name>] [--image <alias>]`. The script creates the container, mounts folders, clones artel
   into the user's home directory (`/home/artel/artel` for the default user; the user name comes from the
   image's `artel.user` property, `--user` overrides it) and runs `artel init` there. Every `sudo -iu artel`
   below uses that name. This lays out the home folder: a git repository with an allowlist, `artel` and `agents`
   submodules, `skills/` symlinked into every harness, `AGENTS.md`/`CLAUDE.md`, a `goal.md` template,
   `agents/` from templates (`planning/`, `journal.md`, `environment.md`, `config.yaml`, concierge prompt).
   Finally, it creates a `fresh` snapshot.
3. **Code by URL.** If the project repository was given as an address rather than a folder:
   `incus exec artel-<name> -- sudo -iu artel artel init --project <name> --src <url>` (a repeat `init` does not
   overwrite anything; it only adds the submodule). To `git push` from the container, a key is needed:
   `incus exec artel-<name> -- sudo -iu artel ssh-keygen -t ed25519 -N ''`. Add the public half in the repository
   settings as an access key with write permission (on GitHub this is called a deploy key). Explain why this is
   needed and show the key: the public half is not secret.
4. **Check.** `incus exec artel-<name> -- sudo -iu artel artel env`: the command is in PATH, submodules are in
   place, and there are no `WARNING` messages.

## 5. Harness login in the container

Explain in simple terms: inside the container, agents must be "logged in" to the same subscriptions as the user,
or they cannot work. Scripts do not show the contents of keys.

**Claude: long-lived token only.** Do not copy the host's Claude session (`~/.claude/.credentials.json`): its
refresh key is one-time, and as soon as Claude refreshes its session on the host, the copy in the container dies
with an `OAuth session expired` error and all Claude agents fail at startup (this is how the morning of the first
report was lost). Therefore, for Claude always:
1. On the host, the user runs `claude setup-token`: they sign in in a browser through the link, paste the code from
   the browser back into the terminal, and the command prints a token of the form `sk-ant-oat01-…` (that token,
   not the code from the browser).
2. The user pastes the token into `claude.oauth_token` in `~/.config/artel/<name>/auth.json` themselves (copy
   `templates/auth.json` there; do not read the file).

Other harnesses, from simple to manual:
1. **Transfer from the host.** `"$ARTEL_REPO"/install/auth-transfer.sh artel-<name> --from-host --auth-file
   ~/.config/artel/<name>/auth.json` (add `--user <name>` for a container whose user is not `artel`) copies codex and opencode login files and the agy token from the Linux system
   password store, takes Claude from `auth.json`, and configures everything inside. This works if the harnesses are
   already logged in on the host (step 1.5). Before agy, ask: Google blocks accounts if one login is used in many
   containers at once; if the user objects, add `--skip agy` (`--only <harness>` is also available). A repeat run
   does not overwrite an existing codex or opencode login in the container (it may have been refreshed inside); to
   replace it, use `--force`.
2. **`auth.json` file.** Values for any harness can be set in the same `auth.json` (the comments in the file explain
   where to get them): explain each field to the user and run
   `"$ARTEL_REPO"/install/auth-transfer.sh artel-<name> --auth-file ~/.config/artel/<name>/auth.json`.
3. **Manually inside.** `codex login --device-auth`, `agy` with `SSH_CONNECTION=1` (it gives a link instead of a
   browser), `opencode auth login`; everything through `incus exec artel-<name> -- sudo -iu artel <command>`.

Check (changes nothing): `"$ARTEL_REPO"/install/auth-transfer.sh artel-<name> --check` prints one line per harness,
with the real login state for Claude; a `WARNING` line about a copied session means the login is fragile and must be
replaced with a token. Details and risks (codex subscription login eventually expires, Google blocks accounts):
`docs/harness-auth-guide.md`. If a login does expire, `artel run` will write to the user's channel how to fix it
as soon as the first agent fails at login.

Telegram is optional: inside, use `~/.config/artel/<name>.telegram.env` with the lines `ARTEL_TG_TOKEN=` and
`ARTEL_TG_CHAT_ID=` (the path is set in `agents/config.yaml`). If Telegram is the only channel, set
`dedicated_bot: true` in `config.yaml` and disable the concierge (`concierge.enabled: false`).

**Secrets on the host.** After transfer, `~/.config/artel/<name>/` on the host still contains `auth.json` with
tokens and, if prepared there, `<name>.telegram.env` with the bot token. The container no longer needs them. Offer
to remove them: `auth-transfer.sh … --shred` overwrites `auth.json` immediately after a successful transfer;
delete the Telegram file with `shred -u` (or `rm`). `answers.md`, `goal.md`, and `environment.md` contain no secrets;
leave them.

## 6. Project files

1. **goal.md.** `incus file push ~/.config/artel/<name>/goal.md artel-<name>/home/artel/goal.md`, then
   `incus exec artel-<name> -- chown artel:artel /home/artel/goal.md` (the uid is not fixed: `--user` images
   differ).
2. **environment.md.** Fill in what you know (the template is already at `agents/environment.md`): host and its
   resources, container and limits, what is mounted, which harnesses are logged in and under which subscriptions,
   quota share and time windows as stated by the user, communication channels, and quiet hours. Edit via `incus
   file pull`, edit on the host, `incus file push` and the same `chown`. Helper module:
   `templates/prompts/artel/environment.md`.
3. **config.yaml.** In `agents/config.yaml`: `channel.quiet_hours`, Telegram, `harness`/`model` for `super`
   (choose from those logged in; default to claude opus) and for `concierge` (the concierge requires Claude; if
   Claude is unavailable, disable it with `enabled: false`). Do not touch the schedule or worker agents: that is
   the super agent's job.
4. **Commit.** `incus exec artel-<name> -- sudo -iu artel artel commit -m "installation"`.

## 7. First run of the super agent and hand-over

The installation is not finished when the container exists. It is finished when the super agent has done its
first run and the agents are on the schedule. You start that run yourself; the user does not have to enter the
container and talk to anyone.

1. **Start.** `incus exec artel-<name> -- sudo -iu artel artel run super`. It takes 10–40 minutes (the `super`
   slot window), longer than a tool call may last, so start it detached and poll:
   `incus exec artel-<name> -- sudo -iu artel sh -c 'nohup artel run super >/dev/null 2>&1 &'`; progress is in
   the newest file of `agents/state/logs/super/` and in `artel slot main`. Tell the user what is happening and
   how long it takes. The run is autonomous: the super agent reads `goal.md` and `environment.md` (that is why
   the quiz in section 2 must be complete), asks nothing, marks its own decisions in `rules.md` and lists the
   open questions in its first message to the user.
   If the user prefers to take part, the alternative is a live session: `incus exec artel-<name> -- sudo -iu
   artel claude` (or codex / agy / opencode) and `/super` inside; there the super agent asks its questions one
   at a time. Offer this only as an option; the default is the autonomous run.
2. **Working state.** Check inside (`incus exec artel-<name> -- sudo -iu artel <command>`); all must hold:
   - `agents/rules.md` and `agents/planning/ROADMAP.md` exist and are filled in, not templates;
   - `artel schedule` lists the agents and `systemctl --user list-timers 'artel-*'` shows their next runs;
   - the concierge service is active when enabled: `systemctl --user is-active artel-<name>-concierge`;
   - `artel slot main` is free and the super log ends without an error; `artel env` prints no `WARNING`.
   If the run failed (a login, a quota, a missing tool), fix the cause and run it again (`artel run super
   --force` after three failures). Never hand over a container whose schedule is empty.
3. **Hand-over.** In plain language: which agents exist, when they run, when the first report comes and through
   which channel (from `agents/planning/STATE.md` and the super agent's journal entry). Then show the cheat
   sheet verbatim: the output of `incus exec artel-<name> -- sudo -iu artel artel cheatsheet` (one screen, no
   blank lines; `artel-up.sh` prints the same at its end). Remind the user: only they change `goal.md`; after
   editing it they tell the super agent (`/super "goal.md changed"` or a message in the channel).

## 8. Variant: installation from inside a container

The user created a container (or any Linux machine) themselves, logged in, opened a harness there in a clone
of artel and called `/artel-create`, or pasted this document. There is no Incus here: memory, mounts, the
display port, GPU and snapshots are set on the host, and the user does that outside; give them the exact
commands when they ask. Everything else is the same, with these replacements.

1. **Checks instead of section 1.** `id -un` must be a regular user: agents do not run as root (Claude Code
   refuses it, and the timers are `systemd --user` units). If the user is root, create a user with them
   (`useradd -m -s /bin/bash -G sudo <name>`, a `NOPASSWD` line in `/etc/sudoers.d/<name>`,
   `loginctl enable-linger <name>`); the user then opens the harness as that user and calls `/artel-create`
   again (move the drafts from `/root/.config/artel/<name>/` to the new home). Then: `sudo -n true` (is sudo available),
   `systemctl --user is-system-running` (needs linger), `command -v` for claude, codex, agy, opencode,
   `python3 -c 'import yaml'`, `git`, `tmux`.
2. **Provisioning.** With sudo and permission: `sudo ARTEL_USER=$USER bash "$ARTEL_REPO"/install/inside/provision.sh`
   installs the same things the image has (packages, Node, harnesses, virtual display, linger, PATH); it is
   idempotent and keeps the existing user. Without sudo, install only what is missing with the harnesses' own
   user-level installers and ask the user to get an administrator for `python3-yaml`, `git`, `tmux` and linger.
3. **Layout instead of section 4.** The artel clone must be `~/artel`: `git clone <url> ~/artel` (or move the
   clone there), then `~/artel/bin/artel init --project <name> [--src <url>]` from the home directory.
   `artel init` adds the PATH line to `~/.profile` and `~/.bashrc` when `artel` is not found; open a new
   shell. Code from the host is mounted by the user on the host: `incus config device add <container> src
   disk source=<host path> path=/home/<user>/src/<name> shift=true`.
4. **Logins instead of section 5.** Copy `templates/auth.json` to `~/.config/artel/auth.json`, explain the
   fields, let the user fill it in (the Claude token comes from `claude setup-token` on any machine), then
   `bash "$ARTEL_REPO"/install/apply-auth.sh`; or by hand: `codex login --device-auth`, `agy` with
   `SSH_CONNECTION=1`, `opencode auth login`. Check: `apply-auth.sh --check`.
5. **Sections 2, 6 and 7 are unchanged.** Files are written directly instead of `incus file push`; the first
   run is `artel run super` started detached; the cheat sheet is `artel cheatsheet --container <name>` (its
   `incus` lines are for the host).

---

# Part 2. The super agent

The super agent manages the agent team. Its prompt is in `skills/super/SKILL.md` in the user project and is invoked
as `/super` from any harness in the container's home folder; on schedule, `artel run super` invokes it. The charter
for all agents is `charter.md` in the artel repository.

**First run (phase 0).** Started by the installer right after installation (`artel run super`), or by the user
in a live session (`/super`). Reads `goal.md` and the charter. Writes `agents/rules.md`: a translation of the goal into
verifiable rules, with each rule grounded in a quote from `goal.md` and its own decisions marked. Studies the
environment (`artel env`, `artel quota`, `agents/environment.md`). Writes the plan `agents/planning/ROADMAP.md`
with phases and next steps, and `STATE.md`. Assembles the agent team: roles, identities
`agents/agent-<name>.md`, the schedule in `agents/config.yaml`, and itself in the schedule too. Enables the
schedule with `artel register --apply` (it creates timers in the container).

**Each subsequent run (iteration).** Collects agent results (`artel team status`), the journal, agents' requests for
help, and quotas. Assesses whether the plan is moving, whether completed work is confirmed by evidence (commits,
tests, artifacts), and how much has been spent. Consolidates everything into the main `planning/` files. Adjusts
agent prompts, scripts, team composition and schedule, and the environment (it may install packages and start
services in the container). Writes to the user only about what cannot be resolved internally, and reports in the
mode specified in `rules.md`. Within the scope of `goal.md`, it is free to try different approaches; for anything
outside `goal.md`, it proposes the change to the user instead of doing it itself.

**What it does not do.** It does not edit `goal.md` without direct permission. It does not raise quota thresholds
above those set by the user. It does not bypass subscription limits. It does not disable the communication channel.
Worker agents do not edit its files or other agents' spheres: each file has one owner.

**What the user sees.** Scheduled reports from `rules.md`; questions through the Claude concierge session (in the
Claude app, session `artel-<name>`) or Telegram; the agents' display at the noVNC address, if enabled. All project
state is in `agents/` (its own git repository with the history of every run), and code is in `src/`.
