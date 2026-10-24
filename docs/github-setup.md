# GitHub setup — what is configured, how, and the limits

Org: **project-templates-org** · Plan: **GitHub Free** · Last updated: 2026-10-24

## 1. Org level

| Item | State | How |
|---|---|---|
| `.github` repo (public) | issue forms, PR template, CONTRIBUTING / SECURITY / SUPPORT / CODE_OF_CONDUCT, org profile, workflow templates | git |
| Issue types | Feature, Task, Bug exist; **Epic pending** (#9) | REST `orgs/{org}/issue-types` or org Settings → Planning |
| Project [**Project Template** (#1)](https://github.com/orgs/project-templates-org/projects/1) | public, marked as template, linked to this repo; 7 fields, Sprint 1–4 (from 2026-10-26), 7 views, 3 onboarding drafts | GraphQL Projects v2 |
| Teams | none yet (single member) — create `maintainers`, `developers` when people join | UI / REST |
| Org rulesets | ❌ needs Team plan — rules are applied per repo instead | — |

## 2. Repository `project-template`

| Setting | Value |
|---|---|
| Visibility / template | public, **Template repository** ✅ |
| Default branch | `main` (+ `staging`, `development`) |
| Merge methods | squash ✅ merge commit ✅ rebase ❌ (per-branch limits in rulesets) |
| Squash / merge commit message | PR title + body |
| Auto-delete head branches, auto-merge, "Update branch" | on |
| Dependabot alerts + security updates | on |
| Secret scanning + push protection | on (free for public repos) |
| Rulesets | `main`, `staging`, `development`, `release-backups`, `version-tags` — JSON in [`.github/rulesets/`](../.github/rulesets) |
| Workflows | `pr-checks` (branch-flow, pr-title, auto-label), `ci`, `release`, `sync-down`, `labels-sync`, `deploy` (opt-in) |
| Environments | `development` ← branch development · `staging` ← staging · `production` ← main, **1 required reviewer** |
| Private vulnerability reporting | on |
| Labels | [`.github/labels.yml`](../.github/labels.yml) |

### Rulesets summary

| Ruleset | Target | Rules | Bypass |
|---|---|---|---|
| main | `main` | no delete, no force-push, PR + 1 approval (stale dismissed, threads resolved), merge-commit only, checks branch-flow/pr-title/ci | org admin + repo admin, **PR only** |
| staging | `staging` | same as main | same |
| development | `development` | no delete, no force-push, PR (0 approvals), squash/merge, same checks | same |
| release-backups | `release/**` | no delete, no force-push, **no updates** | org admin (always) |
| version-tags | tags `v*` | no delete, no move, no force | org admin (always) |

## 3. Creating a new project from the template

```bash
gh repo create project-templates-org/<name> --template project-templates-org/project-template --public --clone
cd <name>
bash scripts/bootstrap.sh project-templates-org/<name> --project-title "<Name>"
```

`bootstrap.sh` applies: settings, security, Actions PR permission, `staging` + `development` branches, rulesets, environments, labels, a copy of the **Project Template** board linked to the repo. Then do the manual steps below.

## 4. Manual steps (UI only — no API exists)

1. **Project → Workflows**: enable *Auto-add to project* (`is:issue,pr is:open`), *Item closed → Done*, *Pull request merged → Done*, *Auto-archive*. Details in [project-management.md](project-management.md#project-automations-project----workflows-ui-only).
2. **Project views**: Group by / Sort / field sums per the views table in [project-management.md](project-management.md#views) — the API can only set name, layout, filter and visible fields.
3. **Project → Insights**: create charts (burn-up per iteration, items by Status/Priority).
4. **Org Settings → Repository → Repository labels**: optionally copy labels so even non-template repos start with them.
5. **Deploys**: write `scripts/deploy.sh`, add environment secrets, then `gh variable set DEPLOY_ENABLED --body true`. Change production reviewers in Settings → Environments.

## 5. Free plan — possible vs not

| Feature | Public repos (Free) | Private repos (Free) | Needs |
|---|---|---|---|
| Repo rulesets / branch protection | ✅ | ❌ not enforced | Team |
| Org-wide rulesets | ❌ | ❌ | Team (Enterprise for push rules) |
| Required reviewers, CODEOWNERS enforcement | ✅ | ❌ | Team |
| Environments with required reviewers / wait timer | ✅ | ❌ | Team (Pro for personal) |
| Environment secrets | ✅ | ❌ | Team |
| Secret scanning + push protection | ✅ | ❌ | GitHub Secret Protection |
| Code scanning (CodeQL) | ✅ | ❌ | GitHub Code Security |
| Dependabot alerts / updates | ✅ | ✅ | — |
| Projects v2, issue types, sub-issues, iterations, roadmap | ✅ | ✅ | — |
| Project auto-add workflows | 1 per project | 1 | more on Team / Enterprise |
| Actions minutes | unlimited | 2,000 min/month | — |
| Internal visibility, custom repo roles, audit log streaming | ❌ | ❌ | Enterprise |

**Private products:** everything in this template works unchanged on a paid plan (Team+). On Free, keep repos public or accept that rulesets are not enforced on private repos.

## 6. Token used for automation (fine-grained PAT)

Resource owner **project-templates-org**, *All repositories*.

- Repository: Administration, Contents, Issues, Pull requests, Workflows, Actions, Secrets, Variables, Environments, Commit statuses — read & write; Metadata — read.
- Organization: Projects, Administration, Members, Issue types — read & write; Custom properties — admin (optional).

## 7. Verification log (2026-10-24)

| Test | Result |
|---|---|
| `branch-flow` rejects `chore/*` → `main` (PR #1) | ✅ failed as designed |
| Work branch → `development`, squash merge (PR #2) | ✅ |
| `development` → `staging` needs approval; squash rejected; admin bypass merge (PR #3) | ✅ |
| `staging` → `main` promotion (PR #4); sync-down skips when there are no file changes | ✅ |
| Release `v0.1.0`: tag, GitHub Release with categorized notes, `release/v0.1.0` created | ✅ |
| Push to `release/v0.1.0` | ✅ rejected ("Cannot update this protected ref") |
| `gh project copy` of the template: fields, views, sprints, drafts preserved | ✅ |

Known quirk: checks attach to a **commit**, so two PRs from the same branch show the same check results. Use one branch per PR.
