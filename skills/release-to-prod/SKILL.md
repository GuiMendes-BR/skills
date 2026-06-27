---
name: release-to-prod
description: Open a PR to prod. On 3-tier projects promotes qa → prod; on 2-tier promotes dev → prod. Auto-detects promoted issues from commit history. Usage: /release-to-prod
---

# Release to Prod

Open a PR promoting to `prod` with auto-detected issue numbers and titles. Works for both 2-tier (`dev → prod`) and 3-tier (`qa → prod`) projects.

## Process

### 1. Read branch strategy

Read `docs/agents/branch-strategy.md` and determine the strategy tier:

- **2-tier** (`dev → prod`): the source branch is `dev`
- **3-tier** (`dev → qa → prod`): the source branch is `qa`

Use `$source` to refer to the source branch throughout the remaining steps.

### 2. Check for existing PR

```bash
gh pr list --base prod --head $source --json number,url --jq '.[0]'
```

If the result is not null, stop:

> A PR from `$source → prod` already exists: <url>
> Merge or close it before opening a new one.

### 3. Detect commits to promote

```bash
git log prod..$source --oneline
```

If the output is empty, stop:

> Nothing to promote — `$source` has no commits ahead of `prod`.

### 4. Parse promoted issue numbers

```bash
git log prod..$source --pretty=format:"%B"
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
gh pr create --base prod --head $source --title "<title>" --body "<body>"
```

### 8. Report

Tell the user:

> PR opened: <url>
> Promoting issues: #N1 <title1>, #N2 <title2>
