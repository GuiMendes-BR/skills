---
name: setup-repo
description: One-time per-project setup. Calls Matt Pocock's setup skill, then adds branch strategy configuration. Run once at the start of each new project.
---

# Setup Repo

Configure this project for the full gmo engineering workflow.

## Process

### 0. Dependency check

Check whether `~/.claude/skills/setup-matt-pocock-skills/` exists (or an equivalent path showing the skill is installed).

If it does NOT exist, stop and tell the user:

> This skill requires Matt Pocock's engineering skills. Run `/setup-user` first to configure your machine, then install the required skills from the marketplace. Re-run `/setup-repo` once done.

### 1. Run Matt Pocock's setup

Invoke the `/setup-matt-pocock-skills` skill now. Wait for it to complete before continuing.

### 2. Run GitHub workflow setup

Invoke the `/setup-github-workflow` skill now. Wait for it to complete before continuing.

### 3. Done

Tell the user: "Project is set up. Run `/ship-issue #<number>` after each implementation to push to dev and comment on the issue."
