# Development workflow — from idea to production

| # | Step | Who | Board Status |
|---|---|---|---|
| 1 | Open an issue with the right form (Epic / Feature / Task / Bug). It is auto-added to the board | anyone | Backlog |
| 2 | Triage: Type, Priority, Size, Area, parent epic; remove `needs-triage` | maintainer | Backlog / Ready |
| 3 | Plan into an Iteration | team | Ready |
| 4 | Assign yourself, create `feature/<issue>-<slug>` from `development` | developer | In progress |
| 5 | Open a (draft) PR into `development`, title in Conventional Commits, body `Refs #<issue>` | developer | In review |
| 6 | Checks `branch-flow`, `pr-title`, `ci` pass; review | reviewer | In review |
| 7 | **Squash merge**; branch auto-deleted | developer | In review → (stays until promoted) |
| 8 | Promotion PR `development → staging` (merge commit, 1 approval) | release owner | In staging |
| 9 | UAT on staging environment | QA / PO | In staging |
| 10 | Promotion PR `staging → main` (merge commit, 1 approval), `Closes #...` for shipped issues | release owner | Done |
| 11 | Run **Release** workflow → tag `vX.Y.Z`, branch `release/vX.Y.Z`, GitHub Release | release owner | Done |

## Rules of thumb

- One issue ↔ one branch ↔ one PR where possible.
- Rebase/merge `development` into your branch if it falls behind (**Update branch** button is enabled).
- Draft PRs early; mark **Ready for review** when checks are green.
- Never commit secrets — use Actions secrets / environments. Push protection blocks known secret formats.
- Dependabot PRs target `development` and follow the same flow.

## Required checks

| Check | Workflow | Fails when |
|---|---|---|
| `branch-flow` | `pr-checks.yml` | head → base direction is not allowed |
| `pr-title` | `pr-checks.yml` | title isn't `type(scope)?: description` |
| `ci` | `ci.yml` → `scripts/ci.sh` | project checks fail (generic: invalid YAML/JSON, conflict markers) |
