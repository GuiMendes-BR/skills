# Branch Strategy

Strategy: 3-tier (dev → qa → prod)

## Branches

| Branch | Purpose               | Releases to |
|--------|-----------------------|-------------|
| dev    | Active development    | qa          |
| qa     | QA testing / staging  | prod        |
| prod   | Production / main     | —           |

## Commit convention

Work commits directly to `dev`. There are no per-issue feature branches.
Each issue implementation should be a single commit on `dev` for easy revert if needed.

## Pull request targets

PRs are used only for releases. Never push directly to `qa` or `prod`.

- dev → qa: manual PR after QA sign-off. The `release-to-qa` skill generates the PR body,
  listing each issue released since the last release as `Closes #<number>`. Issues are already
  closed when they ship to `dev`, so these lines serve as a changelog of what the release carries.
- qa → prod: manual PR after release approval.

## GitHub Actions
- `.github/workflows/release-to-qa.yml`   — runs tests on PRs to `qa`
- `.github/workflows/release-to-prod.yml` — runs tests on PRs to `prod`
