# Release process

Versioning: [SemVer](https://semver.org) `MAJOR.MINOR.PATCH` — breaking change → MAJOR, feature → MINOR, fix → PATCH.

## Cut a release

1. Make sure `staging → main` promotion (or hotfix) is merged and `main` CI is green.
2. **Actions → Release → Run workflow** on branch `main`, enter the version (e.g. `1.4.0`), optionally *pre-release*.
   CLI: `gh workflow run release.yml --ref main -f version=1.4.0`
3. The workflow:
   - validates SemVer and that tag/branch don't exist yet
   - creates tag **`v1.4.0`** on the current `main` commit
   - creates backup branch **`release/v1.4.0`** (read-only via ruleset `release-backups`)
   - publishes a **GitHub Release** with notes grouped by PR labels (`.github/release.yml`)
4. Close the milestone `v1.4.0` (if used) and set the project status update.

## Why both a tag and a backup branch?

The tag marks the exact released commit; the `release/*` branch is the backup you asked for — a protected, immutable branch per release that can be checked out, compared or deployed from even if `main` moves on. Rulesets block deleting, force-pushing or updating both.

## Patch an old release

Branches `release/*` are read-only. To patch an older version: branch `hotfix/<issue>-<slug>` from the tag (`git switch -c hotfix/... v1.4.0`), and agree with an admin how to ship it (admins can bypass the release ruleset if a maintenance line is truly needed). For normal fixes, hotfix `main` and release a new patch.

## Rollback

Deploy the previous tag / `release/vX.Y.Z` branch, then fix forward with a hotfix.

## Deployments

`deploy.yml` deploys on every push to a long-lived branch once `DEPLOY_ENABLED=true` is set:

| Branch | Environment | Gate |
|---|---|---|
| `development` | development | none |
| `staging` | staging | none |
| `main` | production | 1 reviewer must approve the run (Actions → run → **Review deployments**) |

Each environment only accepts deployments from its own branch (deployment branch policy).
