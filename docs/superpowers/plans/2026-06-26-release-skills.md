# Release Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `release-to-qa` and `release-to-prod` skills, configure branch protection in `setup-repo`, and register everything in the marketplace and README.

**Architecture:** Four self-contained changes to this skill-file-only repo — two new skill directories, one modified skill, and two registry/doc updates. No runnable code; "testing" means reading the written files and verifying their content matches the spec.

**Tech Stack:** Markdown skill files, `gh` CLI (branch protection + PR creation), PowerShell (setup-repo scripts), GitHub branch protection API.

## Global Constraints

- Skill file format: frontmatter (`name`, `description`) + `# Title` + `## Process` + `### N. Step` sections — match `skills/ship-issue/SKILL.md` exactly.
- Commit directly to `master` (no feature branches in this repo).
- `release-to-qa` and `release-to-prod` are 3-tier only — both must abort on 2-tier projects.
- Issue auto-detection parses `Closes #N` from `git log` output.
- PR title format: `Release #N1, #N2, #N3 to QA` / `Release #N1, #N2, #N3 to prod`.
- PR body format: one `Closes #N — <title>` line per issue.
- No issue comments after PR creation.
- Branch protection is configured in `setup-repo` as a new step after branches are created.
- `qa` branch must be created by `setup-repo` for 3-tier projects (currently missing).
- `setup-repo` must ask whether `prod` PRs require manual approval before configuring protection.

---

### Task 1: Create `release-to-qa` skill

**Files:**
- Create: `skills/release-to-qa/SKILL.md`

**Interfaces:**
- Consumes: `docs/agents/branch-strategy.md` (reads strategy tier), `gh` CLI, `git log`
- Produces: GitHub PR from `dev → qa`

- [ ] **Step 1: Create the skill file**

Create `skills/release-to-qa/SKILL.md` with this exact content:

```markdown
---
name: release-to-qa
description: Open a PR from dev → qa for 3-tier projects. Auto-detects promoted issues from commit history. Usage: /release-to-qa
---

# Release to QA

Open a PR promoting `dev` to `qa` with auto-detected issue numbers and titles.

## Process

### 1. Read branch strategy

Read `docs/agents/branch-strategy.md`. If the strategy line reads `2-tier`, stop:

> This project uses a 2-tier strategy (`dev → prod`) — there is no `qa` branch. Use `/release-to-prod` to promote directly to `prod`.

### 2. Check for existing PR

```bash
gh pr list --base qa --head dev --json number,url --jq '.[0]'
```

If the result is not null, stop:

> A PR from `dev → qa` already exists: <url>
> Merge or close it before opening a new one.

### 3. Detect commits to promote

```bash
git log qa..dev --oneline
```

If the output is empty, stop:

> Nothing to promote — `dev` has no commits ahead of `qa`.

### 4. Parse promoted issue numbers

```bash
git log qa..dev --pretty=format:"%B"
```

Extract every `Closes #N` reference from the output. Collect unique issue numbers in the order they appear.

### 5. Fetch issue titles

For each issue number N, run:

```bash
gh issue view <N> --json title --jq '.title'
```

### 6. Build PR title and body

Title — comma-separated issue numbers:

```
Release #<N1>, #<N2>, #<N3> to QA
```

Body — one line per issue:

```
Closes #<N1> — <title1>
Closes #<N2> — <title2>
```

### 7. Create the PR

```bash
gh pr create --base qa --head dev --title "<title>" --body "<body>"
```

### 8. Report

Tell the user:

> PR opened: <url>
> Promoting issues: #N1 <title1>, #N2 <title2>
```

- [ ] **Step 2: Verify the file**

Read `skills/release-to-qa/SKILL.md` back and confirm:
- Frontmatter has `name: release-to-qa` and a one-line description
- All 8 process steps are present
- Step 1 checks for 2-tier and aborts
- Step 2 detects existing PR and aborts with URL
- Step 3 aborts on empty `git log qa..dev`
- Steps 4–6 parse issues, fetch titles, build title + body
- Step 7 creates the PR with correct `--base qa --head dev`

- [ ] **Step 3: Commit**

```bash
git add skills/release-to-qa/SKILL.md
git commit -m "feat: add release-to-qa skill"
```

---

### Task 2: Create `release-to-prod` skill

**Files:**
- Create: `skills/release-to-prod/SKILL.md`

**Interfaces:**
- Consumes: `docs/agents/branch-strategy.md`, `gh` CLI, `git log`
- Produces: GitHub PR from `qa → prod`

- [ ] **Step 1: Create the skill file**

Create `skills/release-to-prod/SKILL.md` with this exact content:

```markdown
---
name: release-to-prod
description: Open a PR from qa → prod for 3-tier projects. Auto-detects promoted issues from commit history. Usage: /release-to-prod
---

# Release to Prod

Open a PR promoting `qa` to `prod` with auto-detected issue numbers and titles.

## Process

### 1. Read branch strategy

Read `docs/agents/branch-strategy.md`. If the strategy line reads `2-tier`, stop:

> This project uses a 2-tier strategy (`dev → prod`) — there is no `qa` branch to promote from. Open a PR from `dev → prod` directly:
> `gh pr create --base prod --head dev`

### 2. Check for existing PR

```bash
gh pr list --base prod --head qa --json number,url --jq '.[0]'
```

If the result is not null, stop:

> A PR from `qa → prod` already exists: <url>
> Merge or close it before opening a new one.

### 3. Detect commits to promote

```bash
git log prod..qa --oneline
```

If the output is empty, stop:

> Nothing to promote — `qa` has no commits ahead of `prod`.

### 4. Parse promoted issue numbers

```bash
git log prod..qa --pretty=format:"%B"
```

Extract every `Closes #N` reference from the output. Collect unique issue numbers in the order they appear.

### 5. Fetch issue titles

For each issue number N, run:

```bash
gh issue view <N> --json title --jq '.title'
```

### 6. Build PR title and body

Title — comma-separated issue numbers:

```
Release #<N1>, #<N2>, #<N3> to prod
```

Body — one line per issue:

```
Closes #<N1> — <title1>
Closes #<N2> — <title2>
```

### 7. Create the PR

```bash
gh pr create --base prod --head qa --title "<title>" --body "<body>"
```

### 8. Report

Tell the user:

> PR opened: <url>
> Promoting issues: #N1 <title1>, #N2 <title2>
```

- [ ] **Step 2: Verify the file**

Read `skills/release-to-prod/SKILL.md` back and confirm:
- Frontmatter has `name: release-to-prod` and a one-line description
- All 8 process steps are present
- Step 1 checks for 2-tier and aborts with a helpful message (including manual `gh pr create` command)
- Step 2 detects existing PR with `--base prod --head qa` and aborts
- Step 3 uses `git log prod..qa` (not `qa..dev`)
- Step 7 uses `--base prod --head qa`

- [ ] **Step 3: Commit**

```bash
git add skills/release-to-prod/SKILL.md
git commit -m "feat: add release-to-prod skill"
```

---

### Task 3: Update `setup-repo` — qa branch + branch protection

**Files:**
- Modify: `skills/setup-repo/SKILL.md`

**Interfaces:**
- Consumes: result of `setup-github-workflow` (branch strategy choice written to `docs/agents/branch-strategy.md`)
- Produces: `qa` branch on GitHub (3-tier only), branch protection rules on `qa` and `prod`

The current step 3 PowerShell script creates `dev` and `prod` but never `qa`. Add a `3h` block after `3g`. Then add a new **Step 4** for branch protection.

- [ ] **Step 1: Add qa branch creation to step 3**

In `skills/setup-repo/SKILL.md`, find the block ending with:

```powershell
# 3g — set prod as default branch
$owner = gh api user --jq .login
gh api "repos/$owner/$repoName" -X PATCH -f default_branch=prod

Write-Host "Git and GitHub setup complete."
```

Replace it with:

```powershell
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

- [ ] **Step 2: Add branch protection step**

After the existing `### 3. Initialize git and GitHub remote` section (and before `### 4. Done`), insert a new step:

```markdown
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

# Branch protection body builder
function Set-BranchProtection {
    param($branch, $approvalCount)
    $body = "{`"required_status_checks`":null,`"enforce_admins`":false,`"required_pull_request_reviews`":{`"required_approving_review_count`":$approvalCount,`"dismiss_stale_reviews`":false},`"restrictions`":null}"
    $tmpFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tmpFile -Value $body -Encoding utf8
    gh api "repos/$owner/$repoName/branches/$branch/protection" -X PUT --input $tmpFile
    Remove-Item $tmpFile
}

# Always protect prod (PR required)
$prodApprovals = if ($requireProdApproval -eq "yes") { 1 } else { 0 }
Set-BranchProtection -branch "prod" -approvalCount $prodApprovals

# Protect qa for 3-tier projects (PR required, no required reviewers)
if ($strategy -match "3-tier") {
    Set-BranchProtection -branch "qa" -approvalCount 0
}

Write-Host "Branch protection configured."
```
```

- [ ] **Step 3: Renumber the old step 4**

Find `### 4. Done` and change it to `### 5. Done`. Update the message inside it to reflect the new skills:

```markdown
### 5. Done

Tell the user: "Project is set up. Available workflow commands:
- `/ship-issue #N` — commit and push to `dev`, comment on issue
- `/release-to-qa` — open a PR promoting `dev → qa` (3-tier only)
- `/release-to-prod` — open a PR promoting `qa → prod` (3-tier only)"
```

- [ ] **Step 4: Verify setup-repo changes**

Read `skills/setup-repo/SKILL.md` and confirm:
- Block `3h` exists and creates `qa` only when `branch-strategy.md` contains `3-tier`
- New step 4 asks about prod approval before running `gh api`
- `Set-BranchProtection` is called for `prod` with `$prodApprovals` (0 or 1)
- `Set-BranchProtection` is called for `qa` only when strategy is 3-tier, always with 0
- Old step 4 is now step 5

- [ ] **Step 5: Commit**

```bash
git add skills/setup-repo/SKILL.md
git commit -m "feat: add qa branch and branch protection to setup-repo"
```

---

### Task 4: Register skills in marketplace and README

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: skill names `release-to-qa`, `release-to-prod` (established in Tasks 1–2)
- Produces: marketplace registry + user-facing documentation

- [ ] **Step 1: Add skills to marketplace.json**

In `.claude-plugin/marketplace.json`, find:

```json
"./skills/setup-github-actions"
```

Replace with:

```json
"./skills/setup-github-actions",
"./skills/release-to-qa",
"./skills/release-to-prod"
```

- [ ] **Step 2: Add skills table rows to README**

In `README.md`, find the skills table and add two rows after `setup-github-actions`:

```markdown
| `release-to-qa` | Open a PR promoting `dev → qa` with auto-detected issues (3-tier only) |
| `release-to-prod` | Open a PR promoting `qa → prod` with auto-detected issues (3-tier only) |
```

- [ ] **Step 3: Update workflow section in README**

Find the `# Promotion:` section in the workflow block:

```
# Promotion:
Open PR: dev → prod with "Closes #N" in body
```

Replace with:

```
# Promotion (3-tier):
/release-to-qa   →  open PR dev → qa with auto-detected issues
/release-to-prod →  open PR qa → prod with auto-detected issues

# Promotion (2-tier):
/release-to-prod is unavailable — open PR dev → prod manually
```

- [ ] **Step 4: Verify marketplace and README**

- Read `.claude-plugin/marketplace.json` — confirm `release-to-qa` and `release-to-prod` are in the `skills` array
- Read `README.md` — confirm both rows appear in the skills table, workflow section updated

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "chore: register release-to-qa and release-to-prod in marketplace and README"
```
