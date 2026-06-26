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

### 3. Initialize git and GitHub remote

All steps are idempotent — check before acting.

**3a. Init local repo**

Check whether `.git` exists in the current directory:

```
git rev-parse --git-dir
```

If it does NOT exist:
```
git init
git checkout -b dev
```

If it DOES exist but the current branch is not `dev`, check out `dev` (create it if needed):
```
git checkout -b dev 2>/dev/null || git checkout dev
```

**3b. Stage and commit existing files**

If there are uncommitted changes or untracked files, stage and commit everything:
```
git add .
git diff --cached --quiet || git commit -m "chore: initial project setup with agent config"
```

(Skip if the working tree is already clean and the commit already exists.)

**3c. Create GitHub repo**

Check whether the `origin` remote is already set:
```
git remote get-url origin
```

If it is NOT set, derive the repo name from the working directory name and create a private GitHub repo:
```
gh repo create <repo-name> --private --source . --remote origin
```

**3d. Push `dev` branch**

Push `dev` to origin (safe to re-run — `--set-upstream` is a no-op if tracking is already set):
```
git push -u origin dev
```

**3e. Create and push `prod` branch**

Check if `prod` exists locally or on origin, then create and push if needed:
```
git checkout -b prod 2>/dev/null || git checkout prod
git push -u origin prod
git checkout dev
```

**3f. Set `prod` as the default branch on GitHub**

```
gh api repos/{owner}/<repo-name> -X PATCH -f default_branch=prod
```

Derive `{owner}` from `gh api user --jq .login`.

### 4. Done

Tell the user: "Project is set up. Run `/ship-issue #<number>` after each implementation to push to dev and comment on the issue."
