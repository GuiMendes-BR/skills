---
name: release-to-qa
description: Release dev → qa by merging directly — no PR. 3-tier projects only. Runs the local test gate, then merges and pushes. Usage: /release-to-qa
---

# Release to QA

Release `dev` to `qa` by merging directly — there is no pull request. This is the hop where the **test gate runs**.

## Process

### 1. Read branch strategy

Read `docs/agents/branch-strategy.md`. If the strategy line reads `2-tier`, stop:

> This project uses a 2-tier strategy (`dev → prod`) — there is no `qa` branch. Use `/release-to-prod` to release directly to `prod`.

Read the `test-command:` line — you run it as the gate.

### 2. Sync and detect commits to release

```bash
git fetch origin
git checkout dev
git pull origin dev
git log qa..dev --oneline
```

If the output is empty, stop:

> Nothing to release — `dev` has no commits ahead of `qa`.

### 3. Run the test gate

Run the `test-command` from branch strategy in the repo root. If it exits non-zero, do NOT proceed silently — report the failure and ask:

> <N> test(s) failing. Merge to `qa` anyway? (y/N)

Continue only if the user explicitly answers yes. If they answer no, stop.

### 4. Show the diff and changelog

```bash
git diff qa..dev --stat
git log qa..dev --pretty=format:"%B"
```

Extract every `Closes #N` reference, collect unique issue numbers in the order they appear, and fetch each title:

```bash
gh issue view <N> --json title --jq '.title'
```

Present the changelog (one `#N — title` line per issue) and ask:

> Release <N> issue(s) to `qa`? (y/N)

Continue only on an explicit yes.

### 5. Merge to qa

```bash
git checkout qa
git pull origin qa
git merge --no-ff dev -m "Release to qa

<changelog: one 'Closes #N — title' line per issue>"
git push origin qa
git checkout dev
```

If the push fails (rejected, network error, etc.), stop and report.

### 6. Report

Tell the user:

> Released to `qa`.
> Released: #N1 <title1>, #N2 <title2>
> Next: deploy `qa` to your staging environment and verify manually, then run `/release-to-prod` to release to `prod`.
