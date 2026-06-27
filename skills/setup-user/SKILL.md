---
name: setup-user
description: Bootstrap a new machine with all required Claude Code marketplaces, plugins, and skill install instructions. Run once after adding gmo-skills via /plugins add github:GuiMendes-BR/skills.
---

# Setup User

Bootstrap a new machine for the full gmo engineering workflow.

## Process

### 1. Read current settings

Read `~/.claude/settings.json`.

### 2. Add missing marketplaces

For each of the following not already present in `extraKnownMarketplaces`, add it and write the updated `settings.json`:

```json
"matt-pocock-skills": {
  "source": {
    "source": "github",
    "repo": "mattpocock/skills"
  }
},
"claude-code-skills": {
  "source": {
    "source": "git",
    "url": "https://github.com/alirezarezvani/claude-skills.git"
  }
},
"addyosmani-agent-skills": {
  "source": {
    "source": "github",
    "repo": "addyosmani/agent-skills"
  }
},
"anthropic-agent-skills": {
  "source": {
    "source": "github",
    "repo": "anthropics/skills"
  }
}
```

### 3. Enable required plugins

For each of the following not already set to `true` in `enabledPlugins`, add or update the entry and write the updated `settings.json`:

- `superpowers@claude-plugins-official: true`
- `github@claude-plugins-official: true`
- `notion@claude-plugins-official: true`
- `frontend-design@claude-plugins-official: true`

### 4. Print skill install checklist

Tell the user:

> Marketplaces and plugins are configured. Now install the following skills from the Claude Code skill browser:
>
> **From `matt-pocock-skills` (Matt Pocock's workflow):**
> - `setup-matt-pocock-skills`
> - `implement`
> - `to-issues`
> - `triage`
> - `grill-with-docs`
> - `to-prd`
> - `git-guardrails-claude-code`
>
> **From `addyosmani-agent-skills`:**
> - `context-engineering` ← your /sync skill: run at the start of every session
> - `documentation-and-adrs`
> - `git-workflow-and-versioning`
> - `shipping-and-launch`
>
> **From `gmo-skills` (this repo):**
> - `setup-repo`
> - `setup-github-workflow`
> - `ship-issue`
>
> Once installed, run `/setup-repo` inside each project.
