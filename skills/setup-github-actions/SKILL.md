---
name: setup-github-actions
description: Generate GitHub Actions workflow files based on your branch strategy, project type, and preferred CI trigger. Run after /setup-github-workflow.
---

# Setup GitHub Actions

Generate `.github/workflows/` files for this project.

## Process

### 1. Check prerequisites

Read `docs/agents/branch-strategy.md`. If it does not exist, stop and tell the user:

> This skill requires a branch strategy to be configured. Run `/setup-github-workflow` first, then re-run `/setup-github-actions`.

Note whether the project uses 2-tier (`dev → prod`) or 3-tier (`dev → qa → prod`).

### 2. Ask: repo structure

Ask the user:

> Is this a monorepo or a single-repo project?
> - **Single repo** — one project, one root
> - **Monorepo** — multiple apps in `frontend/` and `backend/` subdirectories

### 3. Ask: project type

Ask the user:

> What type of project is this?
> - **Python Flask**
> - **React**
> - **Chrome Extension**
> - **Python Streamlit**
> - **Other**

### 4. Ask: trigger strategy

Ask the user:

> Which CI strategy do you want?
> - **A) Push to dev + PR to prod** — tests run on every push to `dev` AND when opening a promotion PR
> - **B) PR to prod only** — tests run only when opening a promotion PR

### 5. Resolve test command and setup step

Based on answers from steps 2 and 3, use this lookup table:

| Project type | Setup step | Single repo command | Monorepo command |
|---|---|---|---|
| Python Flask | `uses: actions/setup-python@v5` with `python-version: '3.11'` | `pip install -r requirements.txt && pytest` | `cd backend && pip install -r requirements.txt && pytest` |
| React | `uses: actions/setup-node@v4` with `node-version: 20` | `npm ci && npm test` | `cd frontend && npm ci && npm test` |
| Chrome Extension | `uses: actions/setup-node@v4` with `node-version: 20` | `npm ci && npm test` | `cd extension && npm ci && npm test` |
| Python Streamlit | `uses: actions/setup-python@v5` with `python-version: '3.11'` | `pip install -r requirements.txt && pytest` | `cd backend && pip install -r requirements.txt && pytest` |
| Other | *(none)* | `echo "No test command configured" # TODO: replace with your test command` | *(same)* |

For **Chrome Extension**, prepend this comment block above the `run:` step in every workflow file generated:

```yaml
      # Note: E2E tests (loading the extension in Chrome) are skipped in CI.
      # Headless Chrome does not support --load-extension. Run E2E tests locally.
```

### 6. Create `.github/workflows/` directory

Create the directory if it does not exist.

### 7. Write workflow files

Which files to write:

| | 2-tier | 3-tier |
|---|---|---|
| Strategy A | `push-tests.yml` + `release-prod.yml` | `push-tests.yml` + `promote-qa.yml` + `release-prod.yml` |
| Strategy B | `release-prod.yml` | `promote-qa.yml` + `release-prod.yml` |

Write each file substituting `<setup-step>` and `<test-command>` from the table in step 5.

---

#### `push-tests.yml` (Strategy A only)

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
      - <setup-step>
      - run: <test-command>
```

---

#### `release-prod.yml`

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
      - <setup-step>
      - run: <test-command>

# Note: to require manual approval before merging to prod, configure a
# GitHub Environment with required reviewers in your repository settings.
# This feature requires the GitHub Team plan or higher.
```

---

#### `promote-qa.yml` (3-tier only)

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
      - <setup-step>
      - run: <test-command>
```

---

### 8. Done

Tell the user which files were created, then say:

> Push these files to GitHub to activate the workflows:
>
> ```
> git add .github/workflows/
> git push origin dev
> ```
>
> GitHub picks them up automatically once pushed. No additional configuration needed.
>
> **Note:** If you want manual approval gates before merging to prod, configure a GitHub Environment with required reviewers in your repository settings. This requires the GitHub Team plan or higher.
