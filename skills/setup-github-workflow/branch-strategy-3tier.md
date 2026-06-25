# Branch Strategy

Strategy: 3-tier (dev → qa → prod)

## Branches

| Branch | Purpose               | Promotes to |
|--------|-----------------------|-------------|
| dev    | Active development    | qa          |
| qa     | QA testing / staging  | prod        |
| prod   | Production / main     | —           |

## Commit convention

Work commits directly to `dev`. There are no per-issue feature branches.
Each issue implementation should be a single commit on `dev` for easy revert if needed.

## Pull request targets

PRs are used only for promotions. Never push directly to `qa` or `prod`.

- dev → qa: manual PR after QA sign-off. Include `Closes #<number>` in the PR body
  for each issue implemented since the last release — GitHub closes them automatically on merge.
- qa → prod: manual PR after release approval.

## GitHub Actions (future — not yet configured)
- [ ] .github/workflows/push-tests.yml   — run tests on every push to dev
- [ ] .github/workflows/promote-qa.yml   — run tests when dev is merged to qa
- [ ] .github/workflows/release-prod.yml — require manual approval for qa → prod
