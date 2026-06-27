# Design: `/setup-github-actions`

## Overview

A new skill that generates GitHub Actions workflow files for any project already configured with a branch strategy. It reads the existing `branch-strategy.md`, asks three questions, and writes the appropriate `.github/workflows/` files.

---

## Prerequisites

The skill checks that `docs/agents/branch-strategy.md` exists. If it does not, it stops and tells the user:

> This skill requires a branch strategy to be configured. Run `/setup-github-workflow` first, then re-run `/setup-github-actions`.

---

## Questions asked at runtime

The skill asks three questions in order:

### Q1 — Repo structure
> Is this a monorepo or a single-repo project?
> - **Single repo** — one project, one root
> - **Monorepo** — multiple apps in `frontend/` and `backend/` subdirectories

### Q2 — Project type
> What type of project is this?
> - Python Flask
> - React
> - Chrome Extension
> - Python Streamlit
> - Other

### Q3 — Trigger strategy
> Which CI strategy do you want?
> - **A) Push to dev + PR to prod** — tests run on every push to `dev` AND when opening a promotion PR
> - **B) PR to prod only** — tests run only when opening a promotion PR

---

## Test commands per project type

| Project type | Single repo | Monorepo |
|---|---|---|
| Python Flask | `pip install -r requirements.txt && pytest` | `cd backend && pip install -r requirements.txt && pytest` |
| React | `npm ci && npm test` | `cd frontend && npm ci && npm test` |
| Chrome Extension | `npm ci && npm test` | `cd extension && npm ci && npm test` |
| Python Streamlit | `pip install -r requirements.txt && pytest` | `cd backend && pip install -r requirements.txt && pytest` |
| Other | placeholder comment | placeholder comment |

For **monorepo**, the skill prefixes the test command with `cd <dir>` based on the selected project type — one job, one directory. There are no multi-job workflows unless the user selects multiple project types (not supported in this version; use `/setup-github-actions` once per type if needed).

---

## Files generated

### Strategy A — Push to dev + PR to prod

| Branch strategy | Files written |
|---|---|
| 2-tier (dev → prod) | `push-tests.yml`, `release-prod.yml` |
| 3-tier (dev → qa → prod) | `push-tests.yml`, `promote-qa.yml`, `release-prod.yml` |

### Strategy B — PR to prod only

| Branch strategy | Files written |
|---|---|
| 2-tier (dev → prod) | `release-prod.yml` |
| 3-tier (dev → qa → prod) | `promote-qa.yml`, `release-prod.yml` |

All files are written to `.github/workflows/`.

---

## Workflow file templates

### `push-tests.yml`

Node-based projects (React, Chrome Extension):
```yaml
name: Tests

on:
  push:
    branches: [dev]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: <test-command>
```

Python-based projects (Flask, Streamlit):
```yaml
name: Tests

on:
  push:
    branches: [dev]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: <test-command>
```

### `release-prod.yml`

```yaml
name: Release gate

on:
  pull_request:
    branches: [prod]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: <test-command>
```

### `promote-qa.yml` (3-tier only)

```yaml
name: QA gate

on:
  pull_request:
    branches: [qa]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: <test-command>
```

### Monorepo variant

Same templates as above — the only difference is the `run:` command is prefixed with `cd <dir> &&`. Example for React monorepo:

```yaml
      - run: cd frontend && npm ci && npm test
```

Example for Flask monorepo:

```yaml
      - run: cd backend && pip install -r requirements.txt && pytest
```

---

## Special cases

### Chrome Extension
E2E tests (loading the extension in a real Chrome instance) are skipped in CI — headless Chrome does not support `--load-extension`. A comment is added to the workflow explaining this and pointing the user to run E2E tests locally.

### Other
The test step is left as a placeholder:
```yaml
      # TODO: replace with your test command
      - run: echo "No test command configured"
```

---

## Skill file location

```
skills/setup-github-actions/
  SKILL.md
```

No additional template files needed — the YAML is generated inline by the skill instructions.

---

## Constraints

- The skill does not modify `branch-strategy.md` or `CLAUDE.md`.
- The skill does not set up GitHub Environments or required reviewers — those require a paid plan and must be configured manually in GitHub settings.
- The skill adds a note in `release-prod.yml` reminding the user that manual approval gates require the GitHub Team plan.
