# Branch Strategy

Strategy: 3-tier (dev → qa → prod)

## Branches

| Branch | Purpose                          | Releases to |
|--------|----------------------------------|-------------|
| dev    | Active development               | qa          |
| qa     | Deployed staging env (manual QA) | prod        |
| prod   | Production / main                | —           |

## Commit convention

Work commits directly to `dev`. There are no per-issue feature branches.
Each issue implementation should be a single commit on `dev` for easy revert if needed.

## Releases

No pull requests. Releases merge directly after a local test gate.

- dev → qa: the `release-to-qa` skill runs the test command below as a gate (if tests fail it
  asks before continuing), shows `git diff qa..dev` and the `Closes #<number>` changelog, then
  `git merge --no-ff` and pushes to `qa`. Deploy `qa` to your staging environment and verify
  manually.
- qa → prod: the `release-to-prod` skill does NOT re-run the test gate here — the code already
  passed it at `dev → qa` and was manually QA'd on staging. It shows the diff and changelog,
  merges `qa → prod`, pushes, and tags `prod-YYYY-MM-DD` for rollback.

The test gate runs on the hop out of `dev` (here, `dev → qa`). `qa` is a real deployed staging
environment for manual QA — not a place where automated tests run.
