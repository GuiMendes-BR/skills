---
name: setup-repo
description: One-time per-project setup. Pre-populates agent config, adds branch strategy configuration, and initializes git/GitHub. Run once at the start of each new project.
---

# Setup Repo

Configure this project for the full gmo engineering workflow.

## Process

### 0. Dependency check

Check whether the `gh` CLI is authenticated by running `gh auth status`.

If it is NOT authenticated, stop and tell the user:

> Run `gh auth login` first, then re-run `/setup-repo`.

### 1. Pre-create agent config

Run the following PowerShell script in a single call. It creates `CLAUDE.md` with the agent skills block and pre-populates the three `docs/agents/` config files with fixed defaults: GitHub issue tracker, default triage labels, auto-detected domain layout. The script is idempotent — existing files are left untouched.

```powershell
New-Item -ItemType Directory -Force -Path "docs/agents" | Out-Null

if (-not (Test-Path "docs/agents/issue-tracker.md")) {
    @'
# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
'@ | Set-Content "docs/agents/issue-tracker.md" -Encoding utf8
}

if (-not (Test-Path "docs/agents/triage-labels.md")) {
    @'
# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.
'@ | Set-Content "docs/agents/triage-labels.md" -Encoding utf8
}

if (-not (Test-Path "docs/agents/domain.md")) {
    @'
# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, or
- **`CONTEXT-MAP.md`** at the repo root if it exists — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.

If any of these files don't exist, proceed silently. Don't flag their absence; don't suggest creating them upfront.

## File structure

- **Single-context** (most repos): one `CONTEXT.md` + `docs/adr/` at the repo root.
- **Multi-context** (monorepo): `CONTEXT-MAP.md` at the root pointing to per-context `CONTEXT.md` files, with `docs/adr/` both at the root (system-wide) and under each context directory.

## Use the glossary's vocabulary

When your output names a domain concept, use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, note it for `/domain-modeling`.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly:

> _Contradicts ADR-0007 — but worth reopening because..._
'@ | Set-Content "docs/agents/domain.md" -Encoding utf8
}

if (-not (Test-Path "CLAUDE.md")) {
    @'
## Agent skills

### Issue tracker

GitHub Issues, no PR triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Auto-detected from `CONTEXT-MAP.md` presence (single-context by default). See `docs/agents/domain.md`.
'@ | Set-Content "CLAUDE.md" -Encoding utf8
}

Write-Host "Agent config pre-populated in docs/agents/ and CLAUDE.md."
```

### 2. Run GitHub workflow setup

Invoke the `/setup-github-workflow` skill now. Wait for it to complete before continuing.

### 3. Initialize git and GitHub remote

Run the following PowerShell script in a single call. It is fully idempotent.

```powershell
$repoName = Split-Path -Leaf (Get-Location)

# 3a — initial files
if (-not (Test-Path "README.md")) {
    Set-Content "README.md" "# $repoName" -Encoding utf8
}
if (-not (Test-Path ".gitignore")) {
    @'
# OS
.DS_Store
Thumbs.db
desktop.ini

# Editor / IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Node
node_modules/
dist/
build/
.npm
.yarn/cache
.pnp.*

# Python
__pycache__/
*.py[cod]
*.pyo
.venv/
venv/
env/
.Python
*.egg-info/
dist/
.pytest_cache/
.mypy_cache/

# Java / JVM
*.class
*.jar
*.war
*.ear
target/
.gradle/
build/

# Rust
target/

# Go
vendor/

# Terraform
.terraform/
*.tfstate
*.tfstate.backup

# Misc
*.bak
*.tmp
*.orig
coverage/
.cache/
'@ | Set-Content ".gitignore" -Encoding utf8
}

# 3b — init repo and ensure dev branch
if (-not (Test-Path ".git")) {
    git init
    git checkout -b dev
} else {
    $branch = git branch --show-current
    if ($branch -ne "dev") {
        git checkout -b dev
        if ($LASTEXITCODE -ne 0) { git checkout dev }
    }
}

# 3c — stage and commit if dirty
$dirty = git status --porcelain
if ($dirty) {
    git add .
    git commit -m "chore: initial project setup with agent config"
}

# 3d — create GitHub repo if no origin remote
$remotes = git remote
if ($remotes -notcontains "origin") {
    gh repo create $repoName --private --source . --remote origin
}

# 3e — push dev
git push -u origin dev

# 3f — prod branch
$prodLocal = git branch --list prod
if (-not $prodLocal) { git checkout -b prod } else { git checkout prod }
git push -u origin prod
git checkout dev

# 3g — set prod as default branch
$owner = gh api user --jq .login
gh api "repos/$owner/$repoName" -X PATCH -f default_branch=prod

# 3h — qa branch (3-tier projects only)
$strategyFile = "docs/agents/branch-strategy.md"
if ((Test-Path $strategyFile) -and (Get-Content $strategyFile -Raw) -match "3-tier") {
    $qaLocal = git branch --list qa
    if (-not $qaLocal) { git checkout -b qa } else { git checkout qa }
    git push -u origin qa
    git checkout dev
}

Write-Host "Git and GitHub setup complete."
```

### 4. Configure branch protection

Ask the user:

> Should PRs to `prod` require a manual approval before merging? (yes/no)

Then run the following PowerShell script in a single call, substituting the user's answer (`yes` or `no`) for `$requireProdApproval`:

```powershell
$owner = gh api user --jq .login
$repoName = Split-Path -Leaf (Get-Location)
$strategyFile = "docs/agents/branch-strategy.md"
$strategy = if (Test-Path $strategyFile) { Get-Content $strategyFile -Raw } else { "" }
$requireProdApproval = "yes"  # or "no" — substitute user's answer here

function Set-BranchProtection {
    param($branch, $approvalCount)
    $body = "{`"required_status_checks`":null,`"enforce_admins`":false,`"required_pull_request_reviews`":{`"required_approving_review_count`":$approvalCount,`"dismiss_stale_reviews`":false},`"restrictions`":null}"
    $tmpFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tmpFile -Value $body -Encoding utf8
    gh api "repos/$owner/$repoName/branches/$branch/protection" -X PUT --input $tmpFile
    Remove-Item $tmpFile
}

$prodApprovals = if ($requireProdApproval -eq "yes") { 1 } else { 0 }
Set-BranchProtection -branch "prod" -approvalCount $prodApprovals

if ($strategy -match "3-tier") {
    Set-BranchProtection -branch "qa" -approvalCount 0
}

Write-Host "Branch protection configured."
```

### 5. Done

Tell the user: "Project is set up. Available workflow commands:
- `/ship-issue #N` — commit and push to `dev`, comment on issue
- `/release-to-qa` — open a PR promoting `dev → qa` (3-tier only)
- `/release-to-prod` — open a PR promoting `qa → prod` (3-tier only)"
