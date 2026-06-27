# GuiMendes-BR/skills

Claude Code skill marketplace — extends the Matt Pocock engineering workflow with GitHub integration and machine bootstrapping.

## Skills

| Skill | Description |
|-------|-------------|
| `setup-user` | Bootstrap a new machine with all required marketplaces, plugins, and skill install instructions |
| `setup-repo` | One-time per-project setup: runs Matt Pocock's setup skill then configures branch strategy |
| `ship-issue` | Stage, commit, and push changes to dev, then comment on the linked GitHub issue |
| `release-to-qa` | Open a PR promoting `dev → qa` with auto-detected issues (3-tier only) |
| `release-to-prod` | Open a PR to `prod` with auto-detected issues — promotes `qa → prod` on 3-tier, `dev → prod` on 2-tier |

## Installation

```
/plugins add github:GuiMendes-BR/skills
```

Then install individual skills from the Claude Code skill browser.

## Workflow

```
# New machine (one-time):
1. /plugins add github:GuiMendes-BR/skills
2. Install setup-user from the skill browser
3. /setup-user  →  adds marketplaces, enables plugins, prints install checklist

# New project (one-time):
/setup-repo  →  branch strategy, branch protection, GitHub Actions CI files

# Every session:
/context-engineering  →  briefs the agent on git history, open issues, TODOs

# Per feature:
/to-issues     →  create GitHub issues from a plan
/implement #N  →  commit to dev locally
/ship-issue #N →  commit, push to dev, comment on issue

# Promotion (3-tier):
/release-to-qa   →  open PR dev → qa with auto-detected issues
/release-to-prod →  open PR qa → prod with auto-detected issues

# Promotion (2-tier):
/release-to-prod →  open PR dev → prod with auto-detected issues
```
