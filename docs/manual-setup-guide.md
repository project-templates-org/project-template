# Manual setup guide — the whole setup by hand

This guide recreates everything `scripts/bootstrap.sh` and the template provide, using only the GitHub website. Use it to:
- set up a new org from scratch,
- audit an existing repo ("is everything configured?"), or
- understand what each automated step does.

Each step has **where** (the click path), **what** (exact values) and **why**. ⭐ = recommended, 🔒 = security-relevant, 💲 = needs a paid plan for private repos.

> Automated route: create the repo from the template, then run `bash scripts/bootstrap.sh <org>/<repo> --project-title "<Name>"`. It does Parts 3.2–3.9 and 4.11 for you. Parts 1, 4.7–4.9 (UI-only) and 5 are always manual.

---

## Contents

0. [Prerequisites](#0-prerequisites)
1. [Organization settings](#1-organization-settings)
2. [The `.github` repository (org-wide defaults)](#2-the-github-repository-org-wide-defaults)
3. [A project repository](#3-a-project-repository)
4. [The project board](#4-the-project-board)
5. [Automation token (fine-grained PAT)](#5-automation-token-fine-grained-pat)
6. [Day-to-day by hand](#6-day-to-day-by-hand)
7. [Verification checklist](#7-verification-checklist)

---

## 0. Prerequisites

| Item | Recommendation |
|---|---|
| GitHub account | 🔒 **2FA enabled** (Settings → Password and authentication). Use a passkey or an authenticator app, not SMS |
| Organization | github.com → **+** → **New organization**. Free works for public repos; choose **Team** if repos must be private *and* protected 💲 |
| Local tools (optional) | `git`, [GitHub CLI](https://cli.github.com) `gh` |

**Free plan reminder:** rulesets, required reviews, environment protection, secret scanning and code scanning are only enforced on **public** repos. Private repos need Team (rulesets, reviews, environments) and GitHub Secret Protection / Code Security (scanning).

---

## 1. Organization settings

Open `https://github.com/organizations/<org>/settings`.

### 1.1 Profile — *Settings → General*
| Setting | Value |
|---|---|
| Display name, email, URL | Public org identity. Use a shared address, not a personal one |
| Profile README | Comes from `.github/profile/README.md` (Part 2) |

### 1.2 Member privileges — *Settings → Member privileges*
| Setting | ⭐ Value | Why |
|---|---|---|
| Base permissions | **Read** | Least privilege; give write access through teams |
| Repository creation | Public ✅, Private ✅ for members, or **disabled** if only admins should create repos | Prevents repo sprawl |
| Repository forking | Off for private repos | Stops code leaking out through forks |
| Pages creation | Off unless needed | |
| Allow members to delete or transfer repositories | ❌ | Prevents accidental data loss |
| Allow members to change repository visibility | ❌ | 🔒 Stops private code being made public by accident |
| Projects base permissions | **Read** (or Write for small teams) | |

### 1.3 Authentication security — *Settings → Authentication security*
| Setting | ⭐ Value |
|---|---|
| Require two-factor authentication | ✅ 🔒 (members without 2FA are removed, so warn them first) |

### 1.4 Actions — *Settings → Actions → General*
| Setting | ⭐ Value | Why |
|---|---|---|
| Policies | **Allow enterprise, and select non-enterprise, actions and reusable workflows** → ✅ *Allow actions created by GitHub* · ✅ *Allow actions by Marketplace verified creators* · allowed list: `ossf/scorecard-action@*` | 🔒 Blocks unreviewed third-party actions |
| Require actions to be pinned to a full-length commit SHA | ✅ | 🔒 A version tag can be moved to point at different code; a commit SHA can't. All template workflows are pinned |
| Fork pull request workflows from outside collaborators | **Require approval for first-time contributors** | Protects CI minutes and secrets |
| Workflow permissions | **Read repository contents and packages permissions** | Each workflow asks for only the extra scopes it needs |
| Allow GitHub Actions to create and approve pull requests | ✅ | Needed by `sync-down.yml` to open back-merge PRs |
| Artifact and log retention | 30 days (default 90) | Saves storage |

### 1.5 Planning → Issue types — *Settings → Planning → Issue types*
Create or keep these four. Issue forms set the type automatically.

| Name | Color | Description |
|---|---|---|
| **Epic** | Purple | A large body of work broken down into features and tasks |
| **Feature** | Blue | A user-facing capability or improvement |
| **Task** | Yellow | A specific piece of work |
| **Bug** | Red | Something isn't working |

### 1.6 Repository defaults — *Settings → Repository → Repository defaults / labels*
| Setting | Value |
|---|---|
| Default branch name | `main` |
| Repository labels | Optional: copy `.github/labels.yml` here so repos created *without* the template also get them |

### 1.7 Code security — *Settings → Code security → Configurations*
For public repos, create (or edit the GitHub-recommended) configuration and apply it to **all repositories**, enforced for new ones:

| Feature | Value |
|---|---|
| Dependency graph | Enabled |
| Dependabot alerts | Enabled |
| Dependabot security updates | Enabled |
| Code scanning — default setup | Enabled |
| Secret scanning | Enabled |
| Push protection | Enabled 🔒 |
| Private vulnerability reporting | Enabled |

### 1.8 Personal access tokens — *Settings → Personal access tokens*
| Setting | ⭐ Value |
|---|---|
| Fine-grained tokens | **Allow**, with **Require administrator approval** ✅ |
| Classic tokens | **Restrict** (fine-grained tokens are scoped per repo and per permission) |
| Maximum lifetime | 90 days |

### 1.9 Teams — *org page → Teams → New team* (once you have members)
| Team | Repo role | Purpose |
|---|---|---|
| `maintainers` | Admin | Approve to `staging` / `main`, cut releases |
| `developers` | Write | Day-to-day work |
| `triage` (optional) | Triage | Manage issues without code access |

Add teams to repos under *repo → Settings → Collaborators and teams*. Use the teams in `CODEOWNERS`.

### 1.10 Org rulesets — *Settings → Repository → Rulesets* 💲 (Team plan)
With Team you can define the branch rules in Part 3.4 **once for every repo** (target: *All repositories* or a custom property). On Free, rulesets are per repo.

---

## 2. The `.github` repository (org-wide defaults)

1. **New repository** → owner `<org>` → name **`.github`** → **Public** → create *without* a README.
2. Add these files (copy them from `project-templates-org/.github`):

| Path | Purpose |
|---|---|
| `profile/README.md` | Org landing page |
| `ISSUE_TEMPLATE/1-epic.yml` … `4-bug.yml` | Issue forms; each sets `type:` to the matching issue type |
| `ISSUE_TEMPLATE/config.yml` | `blank_issues_enabled: false` plus contact links |
| `pull_request_template.md` | Default PR body |
| `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md` | Community health files, inherited by every repo that has no copy of its own |
| `workflow-templates/*.yml` + `*.properties.json` | Starter workflows under *Actions → New workflow → By <org>* |
| `.gitattributes` | `* text=auto eol=lf` |

3. *Settings → General*: Features → turn off Wiki and Projects. Pull Requests → allow **squash** only, ✅ *Automatically delete head branches*.
4. *Settings → Rules → Rulesets → New branch ruleset*: name `main`, enforcement **Active**, bypass **Organization admin** (*For pull requests only*), target **Default branch**. Rules: ✅ Restrict deletions · ✅ Block force pushes · ✅ Require a pull request (0 approvals, ✅ require conversation resolution, allowed merge method **Squash**).
5. *Settings → Code security*: enable Dependabot alerts, secret scanning, push protection and private vulnerability reporting.

Check it worked: open **New issue** in any repo without its own templates. You should see Epic / Feature / Task / Bug and no blank-issue option.

---

## 3. A project repository

### 3.1 Create it
- **From the template (⭐):** open `project-template` → **Use this template** → **Create a new repository** → owner `<org>`, name, **Public** (Free) → leave *Include all branches* **off** (you create `staging` and `development` yourself in 3.3).
- **From scratch:** create an empty repo, then copy every file from `project-template`.

### 3.2 General settings — *repo → Settings → General*
| Section | Setting | ⭐ Value | Why |
|---|---|---|---|
| General | Template repository | ✅ only on `project-template` itself | |
| Features | Wikis | ❌ | Docs live in `docs/` with the code, reviewed in PRs |
| Features | Issues | ✅ | |
| Features | Discussions | optional | Q&A, RFCs |
| Features | Projects | ✅ | |
| Pull Requests | Allow merge commits | ✅ → default message **Pull request title and description** | Used for promotions and back-merges |
| Pull Requests | Allow squash merging | ✅ → default message **Pull request title and description** | Used for work branches; the PR title becomes the commit message |
| Pull Requests | Allow rebase merging | ❌ | Rewrites SHAs, so it doesn't mix with long-lived branches |
| Pull Requests | Always suggest updating pull request branches | ✅ | |
| Pull Requests | Allow auto-merge | ✅ | Merges itself once checks and reviews pass |
| Pull Requests | Automatically delete head branches | ✅ | No stale branches |
| Archives | Include Git LFS objects | as needed | |

### 3.3 Branches
1. Default branch: **`main`** (*Settings → General → Default branch*).
2. *Code → branch dropdown → View all branches → New branch*:
   - `staging` from `main`
   - `development` from `main`

| Branch | Environment | Who merges in |
|---|---|---|
| `main` | production | `staging` (promotion), `hotfix/*` |
| `staging` | staging / UAT | `development` (promotion), `hotfix/*`, `main` (back-merge) |
| `development` | development / integration | `feature/*`, `fix/*`, `chore/*`, `docs/*`, …, back-merges |

### 3.4 Rulesets — *Settings → Rules → Rulesets → New ruleset → New branch ruleset* 🔒
Create **five** rulesets. (Shortcut: *New ruleset → Import a ruleset* and upload the JSON from `.github/rulesets/`.)

**Ruleset `main`**
| Field | Value |
|---|---|
| Enforcement status | **Active** |
| Bypass list | **Organization admin** → *For pull requests only*; **Repository admin** role → *For pull requests only* |
| Target branches | **Add target → Include by pattern** → `main` |
| ✅ Restrict deletions | |
| ✅ Block force pushes | |
| ✅ Require a pull request before merging | Required approvals **1** · ✅ Dismiss stale approvals when new commits are pushed · ❌ Require review from Code Owners (turn on with 2+ maintainers) · ❌ Require approval of the most recent push · ✅ Require conversation resolution · Allowed merge methods: **Merge** only |
| ✅ Require status checks to pass | ❌ Require branches to be up to date · ✅ Do not require status checks on creation · checks: `branch-flow`, `pr-title`, `ci` (source **GitHub Actions**). A check only appears in the picker after it has run once, so open a test PR first |

**Ruleset `staging`**: same as `main`, but targeting `staging`.

**Ruleset `development`**: same, targeting `development`, with **0** required approvals and allowed merge methods **Squash** and **Merge**.

**Ruleset `release-backups`**
| Field | Value |
|---|---|
| Bypass list | Organization admin → *Always* |
| Target | Include by pattern `release/**` |
| Rules | ✅ Restrict deletions · ✅ Restrict updates · ✅ Block force pushes (leave *Restrict creations* off so the release workflow can create branches) |

**Ruleset `version-tags`** (*New ruleset → New tag ruleset*)
| Field | Value |
|---|---|
| Bypass list | Organization admin → *Always* |
| Target | Include by pattern `v*` |
| Rules | ✅ Restrict deletions · ✅ Restrict updates · ✅ Block force pushes |

Optional, stricter: ✅ *Require signed commits* on `main`, `staging` and `development` (every contributor needs a signing key). See [security-and-quality.md](security-and-quality.md#optional-stricter-settings-turn-on-as-the-team-grows).

### 3.5 Actions — *Settings → Actions → General*
| Setting | Value |
|---|---|
| Actions permissions | Inherits the org policy (1.4) |
| Workflow permissions | **Read repository contents** · ✅ Allow GitHub Actions to create and approve pull requests |

### 3.6 Environments — *Settings → Environments → New environment*
| Environment | Deployment branches and tags | Protection |
|---|---|---|
| `development` | **Selected branches and tags** → add `development` | none |
| `staging` | Selected → `staging` | none (optional: a reviewer) |
| `production` | Selected → `main` | ✅ **Required reviewers**: maintainers (up to 6) · ❌ Prevent self-review while you're solo (✅ once there are 2+) · optional wait timer |

Add deployment secrets per environment (e.g. `DEPLOY_TOKEN`) under each environment, not as repo secrets. Turn deploys on with *Settings → Secrets and variables → Actions → Variables → New repository variable* `DEPLOY_ENABLED` = `true`.

### 3.7 Code security — *Settings → Code security* 🔒
| Feature | Value |
|---|---|
| Private vulnerability reporting | Enable |
| Dependency graph | Enabled |
| Dependabot alerts | Enable |
| Dependabot security updates | Enable |
| Grouped security updates | Enable |
| Dependabot version updates | Configured by `.github/dependabot.yml` |
| Code scanning → CodeQL analysis | **Set up → Default** (languages are detected, including GitHub Actions) |
| Secret scanning | Enable |
| Push protection | Enable |

### 3.8 Labels — *Issues → Labels*
Create the labels from [`.github/labels.yml`](../.github/labels.yml), or run **Actions → Labels sync → Run workflow**. Groups:
- **Kind** (drives release notes): `feature`, `bug`, `enhancement`, `documentation`, `chore`, `dependencies`, `security`, `breaking-change`
- **Triage:** `needs-triage`, `needs-info`, `blocked`, `good first issue`, `help wanted`, `duplicate`, `wontfix`, `invalid`
- **Flow:** `promotion`, `back-merge`, `hotfix`, `skip-changelog`
- **Size:** `size/XS` … `size/XL`
- **Housekeeping:** `stale`, `pinned`

Don't create Priority, Type or Status labels: those are issue types and project fields.

### 3.9 Files to customise
| File | Change |
|---|---|
| `README.md` | Describe your project |
| `.github/CODEOWNERS` | `* @<org>/maintainers` |
| `.github/dependabot.yml` | Add ecosystems: `npm`, `nuget`, `pip`, `gomod`, `docker`, `maven`, … (keep `target-branch: development`) |
| `scripts/ci.sh` | Real lint / test / build (e.g. `npm ci && npm test`, `dotnet test`, `pytest`) |
| `scripts/deploy.sh` | Real deployment, per environment |

---

## 4. The project board

### 4.1 Create — *org page → Projects → New project*
Start from **Project Template** (the *Templates* tab) ⭐. That copies everything in 4.2–4.6, and you only need 4.7–4.11. To build one from scratch, pick **Table**, name it after the product, then:

### 4.2 Status field — *table header → Status → Edit field*
Rename and add options in this order:

| Option | Color | Description |
|---|---|---|
| Backlog | Gray | Not refined yet |
| Ready | Blue | Refined and ready to be picked up |
| In progress | Yellow | Being worked on |
| In review | Orange | PR open, awaiting review or checks |
| In staging | Purple | Merged and promoted to staging (UAT) |
| Done | Green | In main / released |

### 4.3 Custom fields — *table header → **+** → New field*
| Field | Type | Options |
|---|---|---|
| Priority | Single select | P0 (red) critical · P1 (orange) high · P2 (yellow) medium · P3 (gray) low |
| Size | Single select | XS < 2h · S ≤ 1d · M ≤ 3d · L ≤ 1wk · XL > 1wk (split it) |
| Estimate | Number | story points 1, 2, 3, 5, 8, 13 (optional) |
| Iteration | Iteration | Starts on a **Monday**, duration **2 weeks**; create 4 iterations ahead |
| Start date | Date | |
| Target date | Date | |
| Area | Single select | Frontend · Backend · Infrastructure · Design · Documentation (adapt per project) |

The built-in fields (*Type*, *Parent issue*, *Sub-issues progress*, *Linked pull requests*, *Assignees*, *Labels*, *Milestone*) only need to be shown: **+ → Hidden fields**.

### 4.4 Views — *+ New view*, then in each view open the **view menu ▾** and **Save**
| # | Name | Layout | Filter | Group by | Sort | Columns / extras |
|---|---|---|---|---|---|---|
| 1 | Backlog | Table | `-status:Done` | Status | Priority ↑ | Title, Status, Priority, Size, Area, Iteration, Assignees, Parent issue, Labels |
| 2 | Current sprint | Board | `iteration:@current` | — (columns = Status) | Priority | Card fields: Assignees, Priority, Size, Labels |
| 3 | Sprint planning | Table | `iteration:@current,@next -status:Done` | Iteration | Priority | Field sum: **Estimate** (Group menu → *Field sum*) |
| 4 | Epics | Table | `type:Epic` | — | Target date | Sub-issues progress, Status, Priority, Start / Target date, Milestone |
| 5 | Bugs triage | Table | `type:Bug -status:Done` | Status | Priority | Priority, Area, Assignees, Labels, Repository |
| 6 | My work | Board | `assignee:@me -status:Done` | — | Priority | Priority, Size, Iteration |
| 7 | Roadmap | Roadmap | `type:Epic,Feature` | — | Start date | Dates: **Start date → Target date** · Zoom **Quarter** · Markers: **Iteration** |

Optional on boards: *view menu → Column limit* (WIP limit, e.g. In progress = 3 per person).

### 4.5 Project README and description — *⋯ → Settings*
Short description plus a README explaining the status flow, hierarchy, fields and views (see the Project Template's README).

### 4.6 Visibility — *⋯ → Settings → Danger zone*
**Public** for public products, **Private** otherwise. *Manage access*: add teams (maintainers = Admin, developers = Write).

### 4.7 Built-in workflows — *⋯ → Workflows* (UI only)
| Workflow | ⭐ Setting |
|---|---|
| Item added to project | Status → **Backlog** |
| Item reopened | Status → **In progress** |
| Item closed | Status → **Done** |
| Pull request merged | Status → **Done** |
| Pull request linked to issue | Status → **In review** |
| Auto-add to project | Repository = your repo, filter `is:issue,pr is:open` (Free: 1 auto-add workflow per project) |
| Auto-archive items | `is:closed updated:<@today-30d` |
| Auto-close issue | when Status is set to Done → close the issue ✅ |

Remember: `Closes #N` only closes issues when a PR merges into **`main`**. Write `Refs #N` on feature PRs, and list `Closes #…` in the `staging → main` promotion PR.

### 4.8 Insights — *Insights → New chart* (UI only)
| Chart | Layout | Filter | X-axis / group |
|---|---|---|---|
| Sprint burn-up | (default) | `iteration:@current` | time |
| Status by priority | Stacked bar | `-status:Done` | Status, grouped by Priority |
| Open bugs by area | Bar | `type:Bug -status:Done` | Area |

### 4.9 Status updates — *project header → Status update*
Post one at every sprint end: **On track / At risk / Off track / Complete**, a target date, and 3 bullet points.

### 4.10 Make it a template (only for "Project Template") — *⋯ → Settings → Make template* ✅
Template projects appear under *New project → Templates* for the whole org.

### 4.11 Link the repository — *⋯ → Settings → Linked repositories → Link a repository*
Or from the repo: *Projects tab → Link a project*. The project then appears in the repo's Projects tab.

---

## 5. Automation token (fine-grained PAT)

*Your avatar → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token*

| Field | Value |
|---|---|
| Name | `org-automation-<purpose>` |
| Expiration | 30–90 days 🔒 |
| Resource owner | **the organization** (not your user) |
| Repository access | **All repositories** (needed to create and set up new repos) |

**Repository permissions** (Read and write unless noted): Administration · Contents · Issues · Pull requests · Workflows · Actions · Secrets · Variables · Environments · Commit statuses · Code scanning alerts (Read) · Dependabot alerts (Read) · Metadata (Read, mandatory).

**Organization permissions:** Projects (R/W) · Administration (R/W) · Members (R/W) · Issue types (R/W) · Custom properties (Admin, optional).

If the org requires approval, an owner approves it under *org Settings → Personal access tokens → Pending requests*. **Never paste tokens into chats, issues or code.** Log in with `gh auth login --with-token`, and revoke the token when the work is done.

---

## 6. Day-to-day by hand

| Step | Where / command |
|---|---|
| 1. Create work | *Issues → New issue* → pick a form. Large work → **Epic**, then **Create sub-issue** for each Feature / Task / Bug |
| 2. Triage | Board **Backlog** / **Bugs triage**: set Priority, Size, Area, Iteration, Status = Ready; remove `needs-triage` |
| 3. Plan | Board **Sprint planning**: drag Ready items into the current iteration until the Estimate sum reaches capacity |
| 4. Start | Assign yourself → Status **In progress** → issue sidebar **Development → Create a branch** (base `development`, name `feature/<n>-<slug>`) |
| 5. PR | Base **development**, title `feat(scope): …`, body `Refs #<n>`; draft until ready. Status → **In review** |
| 6. Merge | Checks green → **Squash and merge** |
| 7. Promote | *Pull requests → New* base `staging` ← compare `development`, title `promote: development to staging` → approval → **Create a merge commit**. Status → **In staging** |
| 8. Ship | base `main` ← `staging`, title `promote: staging to main`, body `Closes #…` → approval → **Create a merge commit** |
| 9. Release | *Actions → Release → Run workflow* (branch `main`, version `X.Y.Z`). Without Actions: *Releases → Draft a new release* → new tag `vX.Y.Z` on `main` → **Generate release notes** → Publish; then *Branches → New branch* `release/vX.Y.Z` from the tag |
| 10. Hotfix | Branch `hotfix/<n>-<slug>` from `main` → PR into `main` → release a patch → back-merge `main → staging → development` (sync-down opens these PRs; close and reopen to trigger checks) |

---

## 7. Verification checklist

Repository
- [ ] Default branch `main`; `staging` and `development` exist
- [ ] 5 rulesets active (*Settings → Rules → Rulesets*)
- [ ] PR from `feature/x` into `main` fails **branch-flow**
- [ ] Squash merge is not offered on `staging` / `main`
- [ ] Merging to `main` without approval is blocked (unless you are an admin using bypass)
- [ ] Pushing to `release/vX.Y.Z` is rejected
- [ ] Environments: production shows *Required reviewers* and branch `main`
- [ ] Security tab: Dependabot, code scanning (CodeQL) and secret scanning are active; *Report a vulnerability* button is visible
- [ ] Labels present (including `size/*`)

Org
- [ ] Actions policy: selected actions + SHA pinning required
- [ ] Issue types: Epic, Feature, Task, Bug
- [ ] `.github` issue forms appear in **New issue**
- [ ] 2FA required

Project board
- [ ] 7 views saved with grouping / sorting
- [ ] Workflows: auto-add, closed → Done, merged → Done, auto-archive
- [ ] Iterations scheduled for at least the next 2 sprints
- [ ] Repository linked
