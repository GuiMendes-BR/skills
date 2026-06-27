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
