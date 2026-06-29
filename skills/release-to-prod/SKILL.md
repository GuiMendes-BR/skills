---
name: release-to-prod
description: Release to prod by merging directly — no PR. On 2-tier releases dev → prod after a local test gate; on 3-tier releases qa → prod without re-running the gate (already tested at dev → qa). Tags each release for rollback. Usage: /release-to-prod
---

# Release to Prod

Release to `prod` by merging directly — there is no pull request. Auto-detects released issues from commit history and tags the release for rollback.

## Process

### 1. Read branch strategy

Read `docs/agents/branch-strategy.md` and determine the strategy tier:

- **2-tier** (`dev → prod`): the source branch is `dev`. This hop **runs the test gate** (step 3).
- **3-tier** (`dev → qa → prod`): the source branch is `qa`. This hop is **gate-free** — the tests already ran at `dev → qa`, so they are NOT re-run here.

Use `$source` to refer to the source branch throughout. Also read the `test-command:` line — you need it for the 2-tier gate.

### 2. Sync and detect commits to release

```bash
git fetch origin
git checkout $source
git pull origin $source
git log prod..$source --oneline
```

If the output is empty, stop:

> Nothing to release — `$source` has no commits ahead of `prod`.

### 3. Run the test gate (2-tier only)

**Skip this step entirely on 3-tier** — `qa → prod` does not re-run the gate.

On 2-tier, run the `test-command` from branch strategy in the repo root. If it exits non-zero, do NOT proceed silently — report the failure and ask:

> <N> test(s) failing. Merge to `prod` anyway? (y/N)

Continue only if the user explicitly answers yes. If they answer no, stop.

### 4. Show the diff and changelog

Show the user what they're about to ship:

```bash
git diff prod..$source --stat
git log prod..$source --pretty=format:"%B"
```

Extract every `Closes #N` reference, collect unique issue numbers in the order they appear, and fetch each title:

```bash
gh issue view <N> --json title --jq '.title'
```

Present the changelog (one `#N — title` line per issue) and ask:

> Ship <N> issue(s) to `prod`? (y/N)

Continue only on an explicit yes.

### 5. Merge to prod

```bash
git checkout prod
git pull origin prod
git merge --no-ff $source -m "Release to prod

<changelog: one 'Closes #N — title' line per issue>"
git push origin prod
```

If the push fails (rejected, network error, etc.), stop and report — nothing is tagged until the push succeeds.

### 6. Tag the release for rollback

Tag with today's date (`prod-YYYY-MM-DD`). If that tag already exists — a second release the same day — append `-2`, `-3`, etc.:

```bash
git tag -a prod-YYYY-MM-DD -m "<changelog>"
git push origin prod-YYYY-MM-DD
```

### 7. Return to dev

```bash
git checkout dev
```

### 8. Report

Tell the user:

> Released to `prod` and tagged `prod-YYYY-MM-DD`.
> Shipped: #N1 <title1>, #N2 <title2>
> Roll back with: `git checkout prod-YYYY-MM-DD`
