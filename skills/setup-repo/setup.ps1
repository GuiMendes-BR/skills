<#
.SYNOPSIS
  One-shot, idempotent project bootstrap for the gmo engineering workflow.
  Driven by /setup-repo: the agent gathers all answers via structured questions,
  then calls this script once. Windows PowerShell only.

.NOTES
  Stages run in dependency order and stop-and-report on the first failure.
  Re-running after a fix is always safe -- every stage is idempotent.
  ASCII-only by design: Windows PowerShell 5.1 reads BOM-less .ps1 files as ANSI,
  so non-ASCII characters in code would break parsing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('2', '3')][string]$Tier,
    [Parameter(Mandatory)][ValidateSet('single', 'monorepo')][string]$RepoStructure,
    [string]$ProjectType,
    [string]$Frontend,
    [string]$Backend
)

$ErrorActionPreference = 'Stop'

function Fail($stage, $msg) {
    Write-Host ""
    Write-Host "SETUP FAILED at stage: $stage"
    Write-Host $msg
    Write-Host "Fix the issue and re-run /setup-repo -- the script is idempotent and safe to re-run."
    exit 1
}

# --- Stage 0 - preflight (fail before any mutation) ---
if ($env:OS -ne 'Windows_NT') {
    Fail 'preflight' 'This skill requires Windows PowerShell. To run on macOS/Linux, port this script to pwsh 7+.'
}

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) { Fail 'preflight' 'GitHub CLI is not authenticated. Run: gh auth login' }

if ($RepoStructure -eq 'single' -and [string]::IsNullOrWhiteSpace($ProjectType)) {
    Fail 'preflight' '-ProjectType is required for a single repo.'
}
if ($RepoStructure -eq 'monorepo' -and ([string]::IsNullOrWhiteSpace($Frontend) -or [string]::IsNullOrWhiteSpace($Backend))) {
    Fail 'preflight' '-Frontend and -Backend are required for a monorepo.'
}

# --- Stage 1 - agent config (idempotent) ---
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

Infer the repo from `git remote -v` -- `gh` does this automatically when run inside a clone.

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
- **`CONTEXT-MAP.md`** at the repo root if it exists -- it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** -- read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.

If any of these files don't exist, proceed silently. Don't flag their absence; don't suggest creating them upfront.

## File structure

- **Single-context** (most repos): one `CONTEXT.md` + `docs/adr/` at the repo root.
- **Multi-context** (monorepo): `CONTEXT-MAP.md` at the root pointing to per-context `CONTEXT.md` files, with `docs/adr/` both at the root (system-wide) and under each context directory.

## Use the glossary's vocabulary

When your output names a domain concept, use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, note it for `/domain-modeling`.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly:

> _Contradicts ADR-0007 -- but worth reopening because..._
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

# --- Stage 2 - branch strategy (idempotent) ---
$tierFile = if ($Tier -eq '3') { 'branch-strategy-3tier.md' } else { 'branch-strategy-2tier.md' }
$tierSrc = Join-Path $PSScriptRoot $tierFile
if (-not (Test-Path $tierSrc)) { Fail 'strategy' "Template not found: $tierSrc" }
Copy-Item $tierSrc "docs/agents/branch-strategy.md" -Force

$claude = Get-Content "CLAUDE.md" -Raw
if ($claude -notmatch '### Branch strategy') {
    $tierDesc = if ($Tier -eq '3') { '3-tier: dev -> qa -> prod' } else { '2-tier: dev -> prod' }
    Add-Content "CLAUDE.md" "`n### Branch strategy`n`n[$tierDesc]. Work commits directly to ``dev``; releases merge directly after a local test gate -- no PRs. See ``docs/agents/branch-strategy.md``."
}

# --- Stage 3 - git + GitHub (idempotent) ---
$repoName = Split-Path -Leaf (Get-Location)

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

if (-not (Test-Path ".git")) {
    git init | Out-Null
    git checkout -b dev | Out-Null
}
else {
    $branch = git branch --show-current
    if ($branch -ne "dev") {
        git checkout -b dev 2>$null
        if ($LASTEXITCODE -ne 0) { git checkout dev }
    }
}

$dirty = git status --porcelain
if ($dirty) {
    git add .
    git commit -m "chore: initial project setup with agent config" | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail 'git' 'Initial commit failed.' }
}

$remotes = git remote
if ($remotes -notcontains "origin") {
    gh repo create $repoName --private --source . --remote origin
    if ($LASTEXITCODE -ne 0) { Fail 'github' "Failed to create GitHub repo '$repoName'." }
}

git push -u origin dev
if ($LASTEXITCODE -ne 0) { Fail 'github' 'Failed to push dev branch.' }

$prodLocal = git branch --list prod
if (-not $prodLocal) { git checkout -b prod } else { git checkout prod }
git push -u origin prod
if ($LASTEXITCODE -ne 0) { Fail 'github' 'Failed to push prod branch.' }
git checkout dev

$owner = gh api user --jq .login
if ($LASTEXITCODE -ne 0) { Fail 'github' 'Failed to read GitHub user.' }
gh api "repos/$owner/$repoName" -X PATCH -f default_branch=prod | Out-Null

if ($Tier -eq '3') {
    $qaLocal = git branch --list qa
    if (-not $qaLocal) { git checkout -b qa } else { git checkout qa }
    git push -u origin qa
    if ($LASTEXITCODE -ne 0) { Fail 'github' 'Failed to push qa branch.' }
    git checkout dev
}

# --- Stage 4 - test command in agent config (idempotent) ---
# The release skills run this command locally as the merge gate -- it is the single
# source of truth for "are the tests green". There is no GitHub Actions / branch
# protection: the gate lives in the skill, so no GitHub Pro plan is required.
# Commands are lean (no install step) -- they assume deps are already installed in
# the working tree where the release skill runs.
function Resolve-TestCommand($type, $dir) {
    $prefix = if ($dir) { "cd $dir && " } else { "" }
    switch -Regex ($type) {
        '^React$' { return "${prefix}npm test" }
        '^Chrome Extension$' { return "${prefix}npm test" }
        '^Python Flask$' { return "${prefix}pytest" }
        '^Python Streamlit$' { return "${prefix}pytest" }
        default { return "${prefix}echo 'No test command configured' && exit 1  # TODO: replace with your test command" }
    }
}

if ($RepoStructure -eq 'single') {
    $testCmd = Resolve-TestCommand $ProjectType ''
}
else {
    $fe = Resolve-TestCommand $Frontend 'frontend'
    $be = Resolve-TestCommand $Backend 'backend'
    $testCmd = "$fe && $be"
}

$strategyFile = "docs/agents/branch-strategy.md"
if ((Get-Content $strategyFile -Raw) -notmatch '## Test command') {
    Add-Content $strategyFile ""
    Add-Content $strategyFile "## Test command"
    Add-Content $strategyFile ""
    Add-Content $strategyFile "The release skills run this locally as the merge gate (assumes deps are installed):"
    Add-Content $strategyFile ""
    Add-Content $strategyFile "    test-command: $testCmd"
}

# --- Stage 5 - done ---
Write-Host ""
Write-Host "SETUP COMPLETE"
