# Branch Strategy

Strategy: 2-tier (dev → prod)

## Branches

| Branch | Purpose            | Promotes to |
|--------|--------------------|-------------|
| dev    | Active development | prod        |
| prod   | Production / main  | —           |

## Commit convention

Work commits directly to `dev`. There are no per-issue feature branches.
Each issue implementation should be a single commit on `dev` for easy revert if needed.

## Pull request targets

PRs are used only for promotions. Never push directly to `prod`.

- dev → prod: manual PR with human review. Include `Closes #<number>` in the PR body
  for each issue implemented since the last release — GitHub closes them automatically on merge.

## GitHub Actions
- `.github/workflows/release-to-prod.yml` — runs tests on PRs to `prod`
