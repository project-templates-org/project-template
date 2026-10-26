# Decision log

| # | Date | Decision | Alternatives considered | Why |
|---|---|---|---|---|
| 1 | 2026-10-24 | Org is a **template org** (language-agnostic) | single product; both | Reuse the same management setup for every project |
| 2 | 2026-10-24 | Branches: work branches → `development` → `staging` → `main`; `main` is the default | trunk-based; GitFlow with `develop` default | Environment-per-branch; `main` default so the repo landing page and `Closes #` reflect production |
| 3 | 2026-10-24 | Release backups as read-only `release/vX.Y.Z` branches **plus** tags | tags only | Requested backup branches; tags still mark exact commits |
| 4 | 2026-10-24 | Squash into `development`, merge commits for promotions / back-merges | squash everywhere | Squash promotions make long-lived branches diverge and conflict |
| 5 | 2026-10-24 | Approvals (option A): 1 approval on `main` and `staging`, 0 on `development`, admins may bypass on PRs | approvals everywhere, no bypass; checks only | Single maintainer today — must still be able to merge alone |
| 6 | 2026-10-24 | Public repos | private | Free plan enforces rulesets only on public repos |
| 7 | 2026-10-24 | Issue types (Epic/Feature/Task/Bug) + sub-issues instead of type labels | `type:*` labels | Native hierarchy, progress bars, filterable in projects |
| 8 | 2026-10-24 | Priority / Size / Iteration as **project fields**, not labels | labels | Sortable, groupable, one value per item |
| 9 | 2026-10-24 | Scrum-style hybrid board (2-week iterations + Kanban statuses) | pure Kanban; strict Scrum | Works for both; iterations can be ignored |
| 10 | 2026-10-24 | Checks implemented with plain shell in workflows (no third-party actions except `actions/checkout`) | marketplace actions | Fewer supply-chain dependencies, easy to read |
| 11 | 2026-10-24 | Issue forms live only in the org `.github` repo | copy into each repo | One source of truth; repos inherit automatically |
| 12 | 2026-10-24 | Environments per long-lived branch; production gated by a reviewer; deploy workflow opt-in via `DEPLOY_ENABLED` | always-on deploy | Template stays quiet until a project has something to deploy |
| 13 | 2026-10-24 | Pin all actions by commit SHA; org requires SHA pinning and allows only GitHub-owned/verified actions | version tags | Tags can be moved to point at other code; SHAs can't (supply-chain best practice, Scorecard "Pinned-Dependencies") |
| 14 | 2026-10-24 | `permissions: {}` per workflow + per-job grants, timeouts, `persist-credentials: false`, actionlint | defaults | Least privilege; catch workflow bugs before merge |
| 15 | 2026-10-24 | CodeQL default setup + OpenSSF Scorecard | none | Free for public repos; measurable security posture |
| 16 | 2026-10-24 | Release requires green `ci` on the tagged commit | trust the operator | Never tag a red build |
| 17 | 2026-10-24 | Conservative stale bot (needs-info issues, idle PRs only) + PR size labels | aggressive stale; none | Keeps queues healthy without closing real backlog |
| 18 | 2026-10-26 | Boards are created in the website from the template; `bootstrap.sh` only links them and sets sprints | `gh project copy` in the script | The API copy times out (502) on a template with 14 views and charts, and silently drops charts and drafts. The website copy is complete |
| 19 | 2026-10-26 | Second board template **Product Template** for multi-repo products: statuses split sprint work (… Dev done) from release flow (In staging → Verified → Released); Release train field; Found in field | one Done status; Milestones per repo | Sprint completion ≠ live; milestones are per repo, while a release train spans repos |
| 20 | 2026-10-26 | Tasks/Bugs in code repos + `topic:<name>` labels; Epic/Feature optional | mandatory planning repo + epics | Keep it light now; sub-issues work across repos when needed |
| 21 | 2026-10-26 | Dev done / In staging / Released moved by hand (one drag / bulk edit); no GitHub App yet | Actions + GitHub App | Keyword links only work against `main`; App setup deferred to keep things simple |
| 22 | 2026-10-26 | bootstrap creates labels directly and drops required checks when the repo lacks the template workflows | require template repos only | Lets existing .NET / React / Flutter repos join the setup safely |
