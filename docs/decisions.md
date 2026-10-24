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
