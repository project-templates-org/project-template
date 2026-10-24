# Project management on GitHub

## Work hierarchy

```
Epic            (issue type: Epic)      outcome, spans several iterations
 ├─ Feature     (issue type: Feature)   user-facing capability
 │   └─ Task    (issue type: Task)      concrete piece of work
 ├─ Task
 └─ Bug         (issue type: Bug)
```

- **Issue types** are defined once for the whole org (Epic, Feature, Task, Bug). Each issue form sets the type automatically.
- Hierarchy uses **sub-issues** (up to 8 levels, 100 per parent). On an issue: **Create sub-issue** / **Add existing issue**. Parents show a progress bar.
- Dependencies: use **Relationships → Blocked by / Blocking** on the issue, plus the `blocked` label.

## The project board

Each product gets its own org project, copied from **Project Template** by `scripts/bootstrap.sh`.

### Fields

| Field | Type | Values / meaning |
|---|---|---|
| Status | single select | **Backlog** (not ready) → **Ready** (refined, can be picked) → **In progress** → **In review** (PR open) → **In staging** (merged & promoted, UAT) → **Done** (in `main` / released) |
| Priority | single select | **P0** critical (drop everything) · **P1** high (this iteration) · **P2** medium (next) · **P3** low |
| Size | single select | **XS** < 2h · **S** ≤ 1d · **M** ≤ 3d · **L** ≤ 1 wk · **XL** > 1 wk → split it |
| Estimate | number | Optional story points (1, 2, 3, 5, 8, 13) if the team estimates |
| Iteration | iteration | 2-week sprints starting Mondays |
| Start date / Target date | date | Drive the Roadmap view (mainly Epics & Features) |
| Area | single select | Frontend · Backend · Infrastructure · Design · Documentation — rename per project |
| Type, Parent issue, Sub-issues progress, Linked pull requests, Assignees, Labels, Milestone | built-in | Shown automatically |

### Views

| View | Layout | Filter | Set in UI (not available via API) |
|---|---|---|---|
| **Backlog** | Table | `-status:Done` | Group by **Status**, sort by **Priority** |
| **Current sprint** | Board | `iteration:@current` | Columns = Status (default) |
| **Sprint planning** | Table | `iteration:@current,@next,""  -status:Done` | Group by **Iteration**, show sum of **Estimate** |
| **Roadmap** | Roadmap | `type:Epic,Feature` | Dates = Start date / Target date, zoom = Quarter |
| **Epics** | Table | `type:Epic` | Show Sub-issues progress column |
| **Bugs triage** | Table | `type:Bug -status:Done` | Sort by **Priority**, group by **Status** |
| **My work** | Board | `assignee:@me -status:Done` | — |

### Project automations (Project → ⋯ → Workflows, UI only)

| Workflow | Setting |
|---|---|
| Item added to project | Status = **Backlog** |
| Auto-add to project | `is:issue,pr is:open` for the linked repo (Free plan: 1 auto-add workflow) |
| Item reopened | Status = **In progress** |
| Pull request linked to issue | Status = **In review** (custom: when a PR is opened) |
| Pull request merged / Item closed | Status = **Done** |
| Auto-archive items | `is:closed updated:<@today-30d` |

Note: `Closes #N` only closes the issue when the PR merges into the **default branch (`main`)**.
Feature PRs target `development`, so their issues are moved to **In staging** / **Done** by the promotion
— use `Refs #N` on feature PRs and list `Closes #N ...` in the `staging → main` promotion PR (or close manually).

## Cadence (Scrum-style, adjust freely)

| When | What | Board view |
|---|---|---|
| Continuous | **Triage** new issues (`needs-triage`): set Type, Priority, Size, Area; remove label; Status = Backlog/Ready | Bugs triage, Backlog |
| Sprint start (Mon, every 2 weeks) | **Planning**: pull Ready items into the iteration by priority until capacity | Sprint planning |
| Daily | **Stand-up** walk the board right-to-left | Current sprint |
| Sprint end | **Review** demo from `staging`; **Retro**; post a **project status update** (On track / At risk / Off track) | Roadmap, Epics |
| Release | Promote to `main`, run Release workflow, move items to Done | — |

**Pure Kanban option:** ignore Iteration; limit WIP per column by agreement (GitHub boards show counts and support column limits in the UI).

## Milestones vs iterations

- **Iteration** = time box (sprint) — project field.
- **Milestone** = release scope (e.g. `v1.2.0`) — repository object, shows % done. Use both: iterations for "when", milestones for "what ships together".

## Labels

Labels are kept for what types and fields don't cover — PR kind (release notes), triage state and flow. Full list: [`.github/labels.yml`](../.github/labels.yml).
