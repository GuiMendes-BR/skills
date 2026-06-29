# Branch Strategy

Strategy: 2-tier (dev → prod)

## Branches

| Branch | Purpose            | Releases to |
|--------|--------------------|-------------|
| dev    | Active development | prod        |
| prod   | Production / main  | —           |

## Commit convention

Work commits directly to `dev`. There are no per-issue feature branches.
Each issue implementation should be a single commit on `dev` for easy revert if needed.

## Releases

No pull requests. Releases merge directly after a local test gate.

- dev → prod: the `release-to-prod` skill runs the test command below as a gate (if tests
  fail it asks before continuing), shows the accumulated `git diff prod..dev` and the
  `Closes #<number>` changelog, then `git merge --no-ff` and pushes to `prod`. It tags each
  release `prod-YYYY-MM-DD` for rollback. Issues are already closed when they ship to `dev`,
  so the changelog lines record what the release carries.

The test gate runs on the hop out of `dev` (here, `dev → prod`).
