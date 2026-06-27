---
name: setup-github-actions
description: Generate GitHub Actions workflow files that run tests on PRs to qa and prod. Run after /setup-github-workflow.
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
> - **Monorepo** — separate `frontend/` and `backend/` subdirectories

### 3. Ask: project type(s)

**If single repo**, ask — present exactly these 5 options, do not omit any:

> What type of project is this?
> - **Python Flask**
> - **React**
> - **Chrome Extension**
> - **Python Streamlit**
> - **Other**

**If monorepo**, ask two separate questions:

First — present exactly these 2 options, do not omit any:

> What type is the **frontend** (`frontend/` directory)?
> - **React**
> - **Other**

Then — present exactly these 3 options, do not omit any:

> What type is the **backend** (`backend/` directory)?
> - **Python Flask**
> - **Python Streamlit**
> - **Other**

### 4. Resolve test commands and setup steps

Use this lookup table to determine `<setup-step>` and `<test-command>` for each project side:

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

For **monorepo**, resolve separate setup steps and test commands for both frontend and backend.

### 5. Create `.github/workflows/` directory

Create the directory if it does not exist.

### 6. Write workflow files

Which files to write — tests run only on PRs, never on push to `dev`:

| | 2-tier | 3-tier |
|---|---|---|
| Files | `release-to-prod.yml` | `release-to-qa.yml` + `release-to-prod.yml` |

---

#### `release-to-prod.yml` — single repo

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

#### `release-to-prod.yml` — monorepo (two jobs)

```yaml
name: Release gate

on:
  pull_request:
    branches: [prod]

jobs:
  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - <frontend-setup-step>
      - run: <frontend-test-command>

  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - <backend-setup-step>
      - run: <backend-test-command>

# Note: to require manual approval before merging to prod, configure a
# GitHub Environment with required reviewers in your repository settings.
# This feature requires the GitHub Team plan or higher.
```

---

#### `release-to-qa.yml` — single repo (3-tier only)

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

#### `release-to-qa.yml` — monorepo (3-tier only, two jobs)

```yaml
name: QA gate

on:
  pull_request:
    branches: [qa]

jobs:
  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - <frontend-setup-step>
      - run: <frontend-test-command>

  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - <backend-setup-step>
      - run: <backend-test-command>
```

---

### 7. Done

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
