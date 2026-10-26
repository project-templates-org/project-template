# Status & release flow (multi-repo product)

For a product with **several repositories** (e.g. .NET API, React web, Flutter app) on **one board**, where the team works in **sprints** but code reaches users in **releases**. Board template: **Product Template**.

> The single-repo **Project Template** board (Status … Done) is still available. See [project-management.md](project-management.md).

## The key idea: a sprint and a release are different things

| Question | Answered by |
|---|---|
| Did the team finish its sprint work? | **Status = Dev done** (merged into `development`) + **Iteration** |
| Is it live for users? | **Status = Released** + **Release** (release train) |

A task merged in Sprint 3 can go live in release `2026.12` weeks later. The board shows both, with no extra bookkeeping.

## Statuses

```
Backlog → Ready → In progress → In review → Dev done → In staging → Verified → Released
                  └────────── sprint work ─────────┘   └──────── release flow ────────┘
```

| Status | Meaning | Who / how it moves |
|---|---|---|
| **Backlog** | Captured, not refined | automatic when added |
| **Ready** | Refined (acceptance criteria, size); can be planned | team, at triage / planning |
| **In progress** | Being built | developer: assign yourself, then **Create a branch** from the issue |
| **In review** | PR open into `development` | automatic: *Pull request linked to issue* |
| **Dev done** ✅ | Merged into `development`. **Done for the sprint**; the developer picks the next task | developer, when merging (one drag) |
| **In staging** | `development` promoted to `staging` (Flutter: TestFlight / Play internal track) | release owner: bulk edit at promotion |
| **Verified** | Tested and accepted on staging | QA / product owner |
| **Released** 🚀 | Live in production / stores. The issue closes automatically | release owner: bulk edit at release |

### Why "Dev done" is one manual step
GitHub only links PRs to issues through keywords (`Closes #12`) when the PR targets the **default branch** (`main`). Feature PRs target `development`, so:
- start the branch **from the issue** (*Development → Create a branch*, base `development`). The branch and its PR are then linked to the issue, which moves it to *In review* automatically;
- when you merge, drag the card to **Dev done**.

Fully automatic statuses (Dev done / In staging / Released set by Actions) are possible later with a GitHub App; see [Automation upgrade](#automation-upgrade-optional).

## Fields

| Field | Values | Notes |
|---|---|---|
| **Status** | the 8 above | |
| **Iteration** | 2-week sprints | when the work was *developed* |
| **Release** | `Unscheduled`, `2026.11`, `2026.12`, … | release train; add an option per release (*field → Edit*) |
| **Found in** | development · staging · production | bugs only. *production* = escaped bug |
| Priority | P0–P3 | |
| Size / Estimate | XS–XL / points | Estimate feeds velocity |
| Start / Target date | | roadmap |
| **Repository** (built-in) | e.g. `api`, `web`, `app` | shows the platform; no Platform field needed |
| Type (built-in) | Task, Bug (Feature, Epic optional) | |

## Work items

- **Task** and **Bug** in the repo where the code changes. That's the default.
- Work spanning repos (e.g. login on API + web + app) = one Task per repo, all with the same **`topic:<name>`** label (e.g. `topic:login`). Filter the board with `label:topic:login`.
- **Feature / Epic (optional):** use them any time. Create one in any repo, or in a dedicated `<product>-planning` repo, and add the Tasks as **sub-issues** (they can be in other repos). The board's *Epics & features* view and *Sub-issues progress* work without any change.

## Labels

| Group | Labels |
|---|---|
| Kind (release notes) | feature, bug, enhancement, documentation, chore, dependencies, security, breaking-change |
| Triage | needs-triage, needs-info, blocked, good first issue, help wanted, duplicate, wontfix, invalid |
| Flow | promotion, back-merge, hotfix, skip-changelog |
| Product | **regression**, **needs-migration** (handle with care when promoting), **store-review** (waiting for Apple/Google) |
| Topic | `topic:<name>`: same name in every repo, colour `5319E7` |
| Size | size/XS … size/XL (automatic on PRs) |

## Who is assigned

- **Assignee = the developer, from In progress until Released.** Ownership doesn't hop between people.
- **QA** owns *In staging → Verified* through the **QA queue** view; they don't need to be the assignee.
- **Reviewers** sit on the PR.
- A bug found on staging = **new Bug** (Found in = staging, linked to the task) assigned to the same developer, Priority P0/P1. Don't drag the original task backwards: that would rewrite sprint history.

## The cycle

### Sprint (every 2 weeks)
1. **Planning** (*Sprint planning* view): pull Ready items into the new Iteration up to capacity (sum of Estimate).
2. **Daily** (*Sprint board*): In progress → In review → **Dev done**.
3. **Sprint review** (*Sprint board* filtered to Dev done or later): what the team delivered. Unfinished items move to the next Iteration.

### Promotion to staging (any time, often after each sprint)
1. PR `development → staging` in each repo that changed (merge commit).
2. *Release board* → select all **Dev done** cards → set Status **In staging** (select rows, then paste the value into the Status cell).
3. QA tests from the **QA queue**: pass → **Verified**; fail → new Bug (Found in = staging).

### Release to production (release train)
1. *Release readiness* view: every item of the next release is **Verified**? (Anything else = blocked release or descoped.)
2. Set **Release = 2026.11** on the Verified items (bulk).
3. In each changed repo: PR `staging → main` → run **Release** workflow (`vX.Y.Z` tag + `release/vX.Y.Z` backup). Flutter: submit the store build; add `store-review` until approved.
4. Bulk set Status **Released** → *Auto-close issue* closes the issues.
5. Post a project **status update** (release notes link).

## Views (Product Template)

| View | Layout | What for |
|---|---|---|
| Sprint board | board, current Iteration | daily stand-up; the sprint goal is Dev done |
| My work | board, assignee:@me | personal queue |
| By repository | board, swimlanes per repo | API vs web vs app at a glance |
| Release board | board, swimlanes per Release | Dev done → Released pipeline |
| QA queue | table, In staging, by repo | QA's work list |
| Release readiness | table by Release, sorted by Status | "can we ship?" |
| Released | table by Release | release history / changelog |
| Backlog | table, Backlog + Ready by Status | refinement |
| Triage inbox | table, no priority | new items to triage |
| Sprint planning | table by Iteration | capacity planning (sum Estimate) |
| Team workload | table by assignee | balance work |
| Bugs | table by Priority, shows Found in | bug triage |
| Blocked | table, label:blocked | escalation |
| Epics & features | table | optional higher-level progress |
| Roadmap | roadmap by Release | timeline (set dates in UI) |

Create or reset them with `scripts/setup-views.sh <org> <number> product`.

## Built-in board workflows (set once in the template)

| Workflow | Setting |
|---|---|
| Item added to project | Status → **Backlog** |
| Item reopened | Status → **In progress** |
| Pull request linked to issue | Status → **In review** |
| Pull request merged | Status → **Dev done** (⚠️ never Released/Done) |
| Item closed | Status → **Released** |
| Auto-close issue | when Status = **Released** |
| Auto-archive items | `is:closed updated:<@today-30d` |
| Auto-add to project | **one per repository**: `is:issue,pr is:open` (not copied with the template; Free allows 1, paid plans more) |

## Insights charts (set once in the template; copied with it)

| # | Chart | Layout | Filter | X-axis | Group by | Y-axis |
|---|---|---|---|---|---|---|
| 1 | Sprint burn-up | historical line | `iteration:@current` | time | Status | count |
| 2 | Velocity | stacked column | `status:"Dev done","In staging",Verified,Released` | Iteration | Repository | sum of Estimate |
| 3 | Release burn-up | historical line | `release:2026.11` (edit per release) | time | Status | count |
| 4 | Cumulative flow | historical stacked area | `-status:Backlog` | time | Status | count |
| 5 | Waiting for production | stacked bar | `status:"Dev done","In staging",Verified` | Repository | Status | count |
| 6 | Escaped bugs | column | `type:Bug` | Found in | Repository | count |
| 7 | Open bugs by priority | column | `type:Bug -status:Released` | Priority | Repository | count |
| 8 | Workload | bar | `-status:Released,Verified` | Assignees | Status | sum of Estimate |

## Setting up a product

1. Create the board in the website: **Projects → New project → Templates → Product Template**. Name it after the product.
2. For **each** repository (new from `project-template`, or existing):
   ```bash
   bash scripts/bootstrap.sh <org>/<repo> --project-title "<Board name>" --board-template "Product Template"
   ```
   The first repo links the board and sets 6 sprints from next Monday; later repos are only linked.
   For existing repos without the template's workflows, rulesets are applied **without** required checks (copy `.github/workflows` from the template and re-run to enforce them).
3. On the board: one **Auto-add** workflow per repo; add **Release** options.
4. Plan: **Team** plan for private repos (rulesets, required reviews, environment approvals). Code scanning and secret scanning on private repos need GitHub Code Security / Secret Protection.

## Automation upgrade (optional)

A small workflow in each repo can set **Dev done** on merge into `development`, **In staging** on promotion and **Released** on release automatically. It needs a token with org-project write access: a **GitHub App** (recommended) or a fine-grained PAT stored as an org secret. Ask the maintainers when the manual steps start to cost time.
