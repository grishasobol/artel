# User project {{PROJECT}}

This folder's root is the artel agent team's working directory and a Git repository with submodules.
It is usually the `artel` user's home directory inside the Incus container `artel-{{PROJECT}}`.

- `goal.md` is the project goal in the user's words. Only the user changes it.
- `agents/` is the development process: `rules.md`, plans, journal, configuration, prompts, agent spheres, and
  scripts. A separate Git repository (submodule); run history is committed automatically.
- `skills/` contains agent skills linked into all harnesses by symlinks (`artel link`). Invoke the super agent as `/super`.
- `src/<repository>/` contains project code: Git submodules and host-mounted directories. All work happens here.
- `artel/` is the artel system: charter `artel/charter.md`, `artel` command, and templates. A submodule; update with `git -C artel pull`.
- `scratch/` contains drafts: worker worktrees, clones of other projects, and large data. It is not tracked by Git.
- `AGENTS.md` (`CLAUDE.md` symlink) is the introduction for any live harness session here.

The root `.gitignore` is a whitelist: nothing except the listed files and submodules is tracked, because harness
keys and state live nearby. After every timer run, `artel run` commits `agents/` and submodule pointers. Agents
make commits in project repositories from inside `src/<repository>`; nothing from `agents/` should enter them.
The root and `agents/` usually have no remote: history lives in the container and its snapshots.
