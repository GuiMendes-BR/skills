# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Reminders

> **CLAUDE INSTRUCTION — SESSION START:** If the list below has any items, announce them to the user BEFORE doing anything else — say "You have reminders from a previous session:" then list them. After the user acknowledges, offer to run /remember-me --clear to remove them.

## What this repo is

A Claude Code skill marketplace (`gmo-skills`). The deliverables are `SKILL.md` instruction files — there is no runnable application code and no test suite.

## Skill file format

Every skill follows this exact structure:

```markdown
---
name: <kebab-case-name>
description: <one-line description of what the skill does and when to use it>
---

# <Title>

<One-line summary of purpose.>

## Process

### 1. <Step name>
...

### 2. <Step name>
...
```

Match the frontmatter and section structure of existing skills (`skills/ship-issue/SKILL.md` is the canonical reference).

## Adding a new skill

Three things must happen — Claude must not skip any of them:

1. Create `skills/<skill-name>/SKILL.md` with the correct format above
2. Add `"./skills/<skill-name>"` to the `skills` array in `.claude-plugin/marketplace.json`
3. Add a row to the skills table in `README.md` and mention it in the workflow section

## Branch strategy

Commit directly to `master`. This repo is not governed by its own branch-strategy docs — those are for projects that *use* these skills.
