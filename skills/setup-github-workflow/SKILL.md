---
name: setup-github-workflow
description: Add branch strategy configuration to a project that already ran /setup-matt-pocock-skills. Standalone fallback — /setup-repo calls this automatically.
---

# Setup GitHub Workflow

Add branch strategy configuration to this project. Use this if you already ran `/setup-matt-pocock-skills` in a previous session.

## Process

### 1. Check prerequisites

Confirm `docs/agents/issue-tracker.md` exists. If not, tell the user to run `/setup-repo` instead (which handles the full setup including Matt's skill).

### 2. Branch strategy

Ask the user:

> Which branch strategy does this project use?
> - **2-tier** — `dev → prod` (simpler, good for solo or fast-moving projects)
> - **3-tier** — `dev → qa → prod` (adds a QA gate; good for teams with formal testing)

### 3. Write branch strategy file

Write `docs/agents/branch-strategy.md` using the matching template from this skill's folder (`branch-strategy-2tier.md` or `branch-strategy-3tier.md`).

### 4. Update agent skills block

Open `CLAUDE.md` or `AGENTS.md` (whichever exists). Find the `## Agent skills` section and append:

```markdown
### Branch strategy

[2-tier: dev → prod] or [3-tier: dev → qa → prod]. Work commits directly to `dev`; PRs are used only for promotions. See `docs/agents/branch-strategy.md`.
```

If neither `CLAUDE.md` nor `AGENTS.md` exists, tell the user to run `/setup-repo` first.

### 5. Done

Tell the user setup is complete.
