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

## Pull request targets

PRs are used only for releases. Never push directly to `prod`.

- dev → prod: manual PR with human review. The `release-to-prod` skill generates the PR body,
  listing each issue released since the last release as `Closes #<number>`. Issues are already
  closed when they ship to `dev`, so these lines serve as a changelog of what the release carries.

## GitHub Actions
- `.github/workflows/release-to-prod.yml` — runs tests on PRs to `prod`
