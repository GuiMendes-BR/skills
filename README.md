# GuiMendes-BR/skills

Claude Code skill marketplace — extends the Matt Pocock engineering workflow with GitHub integration and machine bootstrapping.

## Skills

| Skill | Description |
|-------|-------------|
| `setup-user` | Bootstrap a new machine with all required marketplaces, plugins, and skill install instructions |
| `setup-repo` | One-time per-project setup: gathers preferences, then runs one idempotent script for agent config, branch strategy, git/GitHub, and the local test-gate command |
| `ship-issue` | Stage, commit, and push changes to dev, then close the linked GitHub issue |
| `release-to-qa` | Merge `dev → qa` directly after the local test gate, with auto-detected issues (3-tier only) |
| `release-to-prod` | Merge to `prod` directly with auto-detected issues — `qa → prod` (gate-free) on 3-tier, `dev → prod` (gated) on 2-tier — and tag the release for rollback |
| `designing-notion-system` | Design a Notion system with architecture-aware grilling questions; output ready-to-use SYSTEM_ARCHITECTURE.yaml and SYSTEM_ARCHITECTURE.md directly |

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
/setup-repo  →  branch strategy, git/GitHub, local test-gate command

# Per feature:
/to-issues     →  create GitHub issues from a plan
/implement #N  →  commit to dev locally
/ship-issue #N →  commit, push to dev, close issue

# Release (3-tier):
/release-to-qa   →  test gate, then merge dev → qa directly; deploy qa to staging, QA manually
/release-to-prod →  merge qa → prod directly (gate-free), tag the release

# Release (2-tier):
/release-to-prod →  test gate, then merge dev → prod directly, tag the release
```
