# Setup GitHub Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/setup-github-actions` skill that generates `.github/workflows/` files tailored to the project's branch strategy, project type, and preferred CI trigger.

**Architecture:** A single `SKILL.md` instruction file. No runnable code — the skill is prose instructions that Claude Code executes at invocation time. Registered in `marketplace.json` and documented in `README.md`.

**Tech Stack:** Markdown (SKILL.md format), JSON (marketplace.json), GitHub Actions YAML (generated output, embedded as templates in the skill).

## Global Constraints

- Skill files use YAML frontmatter with `name` and `description` fields, followed by a `# <Title>` heading and a `## Process` section with numbered `###` steps — match the pattern of `skills/ship-issue/SKILL.md` and `skills/setup-github-workflow/SKILL.md` exactly.
- No new template files — all YAML templates are embedded inline in the SKILL.md (unlike `setup-github-workflow` which uses separate template files; this skill is simpler and self-contained).
- The generated workflows target `ubuntu-latest` runners only.
- Node setup uses `actions/setup-node@v4` at `node-version: 20`.
- Python setup uses `actions/setup-python@v5` at `python-version: '3.11'`.

---

### Task 1: Create the skill file

**Files:**
- Create: `skills/setup-github-actions/SKILL.md`

**Interfaces:**
- Consumes: `docs/agents/branch-strategy.md` at invocation time (read by the skill, not by this task)
- Produces: the skill itself — registered as `./skills/setup-github-actions` in Task 2

- [ ] **Step 1: Verify existing skill structure to match**

  Read `skills/ship-issue/SKILL.md` and `skills/setup-github-workflow/SKILL.md` to confirm the exact frontmatter format and section structure. The new skill must follow the same pattern.

- [ ] **Step 2: Create the directory**

  ```powershell
  New-Item -ItemType Directory -Path "skills\setup-github-actions"
  ```

- [ ] **Step 3: Write the SKILL.md**

  Create `skills/setup-github-actions/SKILL.md` with this exact content:

  ````markdown
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
  ````

- [ ] **Step 4: Verify file structure**

  Confirm the file starts with `---`, contains `name:` and `description:` fields, closes with `---`, and has a `## Process` section with `###` numbered steps. Compare the frontmatter visually against `skills/ship-issue/SKILL.md`.

- [ ] **Step 5: Commit**

  ```bash
  git add skills/setup-github-actions/SKILL.md
  git commit -m "Add setup-github-actions skill"
  ```

---

### Task 2: Register the skill in marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: `skills/setup-github-actions/` from Task 1
- Produces: skill available in the Claude Code skill browser under `gmo-skills`

- [ ] **Step 1: Read the current marketplace.json**

  Read `.claude-plugin/marketplace.json` and locate the `"skills"` array inside the first plugin object.

- [ ] **Step 2: Add the new skill entry**

  Append `"./skills/setup-github-actions"` to the `skills` array. The array should now read:

  ```json
  "skills": [
    "./skills/setup-user",
    "./skills/setup-repo",
    "./skills/setup-github-workflow",
    "./skills/ship-issue",
    "./skills/setup-github-actions"
  ]
  ```

- [ ] **Step 3: Verify valid JSON**

  Run:
  ```powershell
  Get-Content .claude-plugin\marketplace.json | ConvertFrom-Json
  ```
  Expected: no error, object printed to console.

- [ ] **Step 4: Commit**

  ```bash
  git add .claude-plugin/marketplace.json
  git commit -m "Register setup-github-actions in marketplace"
  ```

---

### Task 3: Update README.md

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: skill name and description from Task 1
- Produces: accurate public documentation

- [ ] **Step 1: Read README.md**

  Read `README.md` and locate the skills table and the workflow section.

- [ ] **Step 2: Add row to the skills table**

  In the `## Skills` table, add a new row after `ship-issue`:

  ```markdown
  | `setup-github-actions` | Generate GitHub Actions workflow files based on branch strategy, project type, and CI trigger preference |
  ```

- [ ] **Step 3: Add skill to the workflow section**

  In the `## Workflow` code block, add `setup-github-actions` as an optional step after `/setup-repo`:

  ```
  # New project (one-time):
  /setup-repo              →  Matt's setup + branch strategy config
  /setup-github-actions    →  generate .github/workflows/ CI files
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add README.md
  git commit -m "Document setup-github-actions in README"
  ```
