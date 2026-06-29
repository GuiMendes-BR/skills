---
name: ship-issue
description: Stage, commit, and push changes to dev, then close the linked GitHub issue. Invoking this skill is the authorization gate — it commits and pushes automatically. Usage: /ship-issue <issue-number>
---

# Ship Issue

Commit and push changes to `dev`, then close the GitHub issue. Invoking this skill explicitly is the authorization — it stages, commits, and pushes without further confirmation.

## Process

Tell the user upfront: "You have explicitly invoked /ship-issue. This will commit your changes and push to `dev`, then close the GitHub issue."

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

> You're on `<branch>`, not `dev`. Switch to `dev` and re-run `/ship-issue #<number>`.

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

> Nothing to commit — no tracked changes found. Make your changes and re-run `/ship-issue #<number>`.

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

If the push fails (rejected, network error, etc.), stop and warn the user:

> Push to `dev` failed — your changes are committed locally but not on the remote. Issue #<number> was left open. Resolve the push and re-run `/ship-issue #<number>`.

Do not close the issue. The close runs only after a confirmed successful push.

### 8. Close the issue

Get the commit hash:

```bash
git rev-parse HEAD
```

Close the issue with an implementation note in one call:

```bash
gh issue close <number> --comment "Implemented in \`<hash>\` — pushed to \`dev\`."
```

This is best-effort: if the issue is already closed (e.g. you're shipping a follow-up fix), `gh` prints an "already closed" warning — ignore it and continue. The push already succeeded, so the work is shipped regardless.

### 9. Report

Tell the user:

> Done. Changes committed and pushed to `dev`, and issue #<number> has been closed.
> The commit still carries `Closes #<number>`, so your release PR (dev → prod or dev → qa) will list it as a changelog entry — no action needed.
