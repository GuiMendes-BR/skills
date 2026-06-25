---
name: ship-issue
description: Print the git push command and comment on the linked GitHub issue. Invoke explicitly after reviewing the local diff from /implement. Usage: /ship-issue <issue-number>
---

# Ship Issue

Print the push command and comment on the GitHub issue. This is the human authorization gate — git-guardrails blocks automatic pushes; invoking this skill explicitly and running the printed command grants permission.

## Process

Tell the user upfront: "You have explicitly invoked /ship-issue. This will print the push command for you to run, then comment on the GitHub issue."

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

### 5. Print push command

Tell the user:

> Ready to push. Run this command:
>
> ```
> git push origin dev
> ```

### 6. Comment on issue

Get the current commit hash:

```bash
git rev-parse HEAD
```

Post the comment:

```bash
gh issue comment <number> --body "Implemented in \`<hash>\` — pushed to \`dev\`. Will be closed when promoted to prod."
```

### 7. Report

Tell the user:

> Done. Issue #<number> has been commented with the commit hash.
> Remember to include `Closes #<number>` in the body of your promotion PR (dev → prod or dev → qa) so GitHub closes it automatically on merge.
