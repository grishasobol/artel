---
name: artel-create
description: Install a new artel user project in quiz mode. Runs in a clone of the artel repository on a Linux machine with Incus (or without it, then installs it with permission). Finds out the user's goal with simple questions one at a time, writes goal.md in their words, creates a container with an agent team, transfers harness credentials and hands the project over to the super agent. Use when the user asks to create, install or set up an artel project, "create an artel project", "install artel", "/artel-create".
---

# /artel-create

Read `docs/install.md` from the root of this repository in full and carry out part 1 step by step in quiz
mode: one question at a time, in plain words, with a default option, with confirmation before every action
on the machine. Part 1 is the default scenario; the user may change any step, and section 8 covers an
installation from inside a container the user created themselves. The installation ends only when the super
agent's first run, started by you, has put the agents on the schedule (section 7), and the user holds the
cheat sheet (`artel cheatsheet`). Part 2 of the same document explains what the super agent is: retell it in
five sentences at the hand-over.

The root of the artel repository is the folder that holds this skill (`$ARTEL_REPO`); scripts are in
`install/`, templates in `templates/`. Never read or print files with keys or tokens.
