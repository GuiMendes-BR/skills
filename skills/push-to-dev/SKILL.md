---
name: push-to-dev
description: Stage, commit, and push changes to dev, then comment on the linked GitHub issue. Invoking this skill is the authorization gate — it commits and pushes automatically. Usage: /push-to-dev <issue-number>
---

# Push to Dev

Commit and push changes to `dev`, then comment on the GitHub issue. Invoking this skill explicitly is the authorization — it stages, commits, and pushes without further confirmation.

## Process

Tell the user upfront: "You have explicitly invoked /push-to-dev. This will commit your changes and push to `dev`, then comment on the GitHub issue."

### 1. Read project config

- Read `docs/agents/branch-strategy.md` — confirms `dev` is the integration branch
- Read `docs/agents/issue-tracker.md` — confirm this is a GitHub project using `gh` CLI

### 2. Get issue number

Use the number passed as argument. If none was passed, ask the user:

> Which issue number does this commit implement?

### 3. Fetch issue title

```bash
gh issue view <number> --json title --jq '.title'
```

### 4. Check current branch

```bash
git branch --show-current
```

If the result is not `dev`, stop and warn the user:

> You're on `<branch>`, not `dev`. Switch to `dev` and re-run `/push-to-dev #<number>`.

Do not proceed until the user is on `dev`.

### 5. Stage tracked changes

```bash
git add -u
```

Check whether anything is staged:

```bash
git diff --cached --quiet
```

If nothing is staged, stop and warn the user:

> Nothing to commit — no tracked changes found. Make your changes and re-run `/push-to-dev #<number>`.

Do not proceed.

### 6. Generate and create commit

Read the staged diff:

```bash
git diff --cached
```

Write a commit message that describes what was done based on the diff. Append `Closes #<number>` as a footer line. Commit immediately — no confirmation needed:

```bash
git commit -m "<generated message>

Closes #<number>"
```

### 7. Push to dev

```bash
git push origin dev --no-verify
```

### 8. Comment on issue

Get the commit hash:

```bash
git rev-parse HEAD
```

Post the comment:

```bash
gh issue comment <number> --body "Implemented in \`<hash>\` — pushed to \`dev\`. Will be closed when promoted to prod."
```

### 9. Report

Tell the user:

> Done. Changes committed and pushed to `dev`. Issue #<number> has been commented with the commit hash.
> Remember to include `Closes #<number>` in the body of your promotion PR (dev → prod or dev → qa) so GitHub closes it automatically on merge.
