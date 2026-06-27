---
name: setup-repo
description: One-time per-project setup. Gathers branch strategy, repo structure, and CI preferences, then runs a single idempotent script that configures agent config, git/GitHub, branch protection, and GitHub Actions. Run once at the start of each new project.
---

# Setup Repo

Configure this project for the full gmo engineering workflow.

The agent's only job is to **gather every answer up front**, then call `setup.ps1` once. All file creation, git/GitHub operations, branch protection, and workflow generation live in that frozen script — do not perform them inline.

## Process

### 1. Ask the structural questions

Ask these two together (one `AskUserQuestion` call):

- **Branch strategy** — options:
  - **2-tier** — `dev → prod` (simpler, good for solo or fast-moving projects)
  - **3-tier** — `dev → qa → prod` (adds a QA gate; good for teams with formal testing)
- **Repo structure** — options:
  - **Single repo** — one project, one root
  - **Monorepo** — separate `frontend/` and `backend/` subdirectories

### 2. Ask the configuration questions

Ask these together in a single `AskUserQuestion` call. Which questions to include depends on the answers from step 1:

- **Prod approval** (always) — Should PRs to `prod` require a manual approval before merging? Options: **yes** / **no**.
- **QA approval** (3-tier only) — Should PRs to `qa` require a manual approval before merging? Options: **yes** / **no**.
- **Project type** — if **single repo**, ask one question; if **monorepo**, ask two (frontend and backend):
  - Single repo options: **Python Flask**, **React**, **Chrome Extension**, **Python Streamlit**, **Other**
  - Monorepo frontend options: **React**, **Other**
  - Monorepo backend options: **Python Flask**, **Python Streamlit**, **Other**

The "Other" choice (and any custom value the user types) is fine — the script writes a `# TODO` test-command placeholder for unknown types.

### 3. Run the setup script

Call `setup.ps1` from this skill's directory once, passing every answer. Example shapes:

**Single repo:**
```powershell
& "<this-skill-dir>/setup.ps1" -Tier 3 -RepoStructure single -ProdApproval yes -QaApproval no -ProjectType "Python Flask"
```

**Monorepo:**
```powershell
& "<this-skill-dir>/setup.ps1" -Tier 2 -RepoStructure monorepo -ProdApproval yes -Frontend React -Backend "Python Flask"
```

Notes:
- Replace `<this-skill-dir>` with the absolute path to the directory containing this `SKILL.md`.
- Omit `-QaApproval` for 2-tier (it defaults to `no` and is ignored).
- Pass the user's literal project-type answers; the script owns the test-command lookup.

### 4. Report the result

The script prints `SETUP COMPLETE` on success, or `SETUP FAILED at stage: <stage>` with a reason on failure.

- **On success**, tell the user the project is fully set up and list the available workflow commands:
  - `/ship-issue #N` — commit and push to `dev`, comment on issue
  - `/release-to-qa` — open a PR promoting `dev → qa` (3-tier only)
  - `/release-to-prod` — open a PR promoting `qa → prod` (3-tier) or `dev → prod` (2-tier)

  If either branch was set to require approval, remind the user that GitHub Environment required-reviewer gates need the GitHub Team plan or higher.

- **On failure**, relay the failing stage and reason verbatim, help the user fix it, then re-run — the script is idempotent and safe to re-run.
