# gmo-skills

A Claude Code skill marketplace whose skills automate a GitHub-based engineering workflow: bootstrapping machines and repos, then moving an issue's work forward through a branch pipeline.

## Language

### Workflow

**Issue**:
The unit of work. A GitHub issue that one or more commits implement; its number is carried in commit footers (`Closes #N`) so its progress can be tracked through the pipeline.

**Ship**:
To land an issue's commits on `dev` — the first hop into the pipeline. Done by `ship-issue`: commit, push to `dev`, and comment on the issue.

**Release**:
To move already-shipped commits from one branch to the next via a pull request — `dev → qa`, `qa → prod`, or `dev → prod`. Done by `release-to-qa` / `release-to-prod`.
_Avoid_: Promote, promotion.

### Pipeline

**Tier**:
A branch in the release pipeline. In this project a tier is treated as synonymous with an environment; the actual deploy environments (e.g. pointing Render at a branch) are configured per-repo later and are out of scope here. Today only `dev` and `prod` are real environments.

**2-tier**:
The pipeline `dev → prod`. There is no `qa` branch.

**3-tier**:
The pipeline `dev → qa → prod`. The `qa` branch mainly exists as a place to run tests on the code before it reaches `prod`.

**dev**:
The integration branch — where every issue is first shipped.

**qa**:
The testing tier (3-tier only). Code released here so tests can run against it before `prod`.

**prod**:
The production tier. Releasing to `prod` is what closes the issues it carries.
