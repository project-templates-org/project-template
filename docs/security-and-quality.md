# Security & engineering practices

These are the defaults built into the template, the reason for each one, and how to adapt it. They follow common practice for production Node, .NET, Python or Go repositories on GitHub.

## Supply chain

| Practice | Where | Why |
|---|---|---|
| Actions are **pinned to a full commit SHA** (`uses: owner/action@<sha> # vX.Y.Z`) | all workflows | A version tag like `@v4` can be moved to point at different code; a commit SHA can't. Dependabot updates the SHA and the version comment together |
| Org policy: **only GitHub-owned, verified, or explicitly allowed actions**, **SHA pinning required** | org Settings → Actions | Blocks unreviewed third-party actions in every repo |
| Dependabot version updates with a **3-day cooldown**, grouped, targeting `development` | `.github/dependabot.yml` | Avoids adopting a release on the day it's published (most malicious packages are pulled within days); updates go through the normal promotion flow |
| Dependabot alerts + security updates | repo settings | Known-vulnerable dependencies get fix PRs |
| Downloaded tools are **checksum-verified** (actionlint) | `ci.yml` | No `curl \| bash` |

Add each ecosystem you use to `dependabot.yml`: `npm`, `nuget`, `pip`/`uv`, `gomod`, `docker`, `maven`/`gradle`.

## Workflow hardening

| Practice | Why |
|---|---|
| `permissions: {}` at the top of every workflow; each job asks only for the scopes it needs | Least privilege: a compromised step can't push code or edit releases |
| `persist-credentials: false` on checkout | The token isn't left in `.git/config` for later steps to read |
| Untrusted input (`github.head_ref`, PR title, ...) passed through `env:`, never inlined into `run:` | Prevents script injection |
| `timeout-minutes` on every job | Stops hung jobs from burning minutes (default is 6 hours) |
| `concurrency` with cancel-in-progress for PR checks and CI | Only the latest push runs |
| No `pull_request_target` | That trigger is the most common source of Actions vulnerabilities; fork PRs run with a read-only token |
| **actionlint** in CI | Catches workflow syntax, expression and shell errors before merge |

## Code scanning & posture

| Tool | What it does |
|---|---|
| **CodeQL default setup** | Scans workflows (and JS/TS, C#, Python, Java, Go, ... once code exists) on PRs and on a schedule. Results appear in Security → Code scanning |
| **OpenSSF Scorecard** (`scorecard.yml`) | Weekly 0–10 score for branch protection, pinned dependencies, token permissions, code review and more, with findings in Code scanning. A badge is available at `https://api.scorecard.dev/projects/github.com/<org>/<repo>/badge` |
| **Secret scanning + push protection** | Blocks pushes that contain known credential formats |
| **Private vulnerability reporting** | Researchers can report vulnerabilities privately (Security → Report a vulnerability) |

## Release safety

- The release workflow refuses to tag unless the `ci` check **passed on that exact commit**.
- Tags `v*` and branches `release/*` can't be moved or deleted (rulesets).
- Release notes are generated from PR labels, so the PR title and labels matter.

## Repository hygiene

| Practice | Setting |
|---|---|
| PR size labels `size/XS…XL` | Promotions and back-merges are excluded. Keep work PRs at M or smaller (under 200 lines) for fast, thorough reviews |
| Stale bot (conservative) | Only `needs-info` issues (14 + 7 days) and idle PRs (30 + 14 days). Normal backlog issues are never closed automatically. `pinned` exempts an item |
| One issue → one branch → one PR | Keeps traceability, and keeps check results unambiguous (checks attach to commits) |
| Conventional Commits | Readable history, generated changelogs, SemVer hints |

## Optional, stricter settings (turn on as the team grows)

| Setting | How | Trade-off |
|---|---|---|
| **Signed commits** | add `{ "type": "required_signatures" }` to `main`/`staging`/`development` rulesets, re-run bootstrap | Every contributor needs an SSH or GPG signing key set up |
| **Code-owner review** | `require_code_owner_review: true` in rulesets | Needs 2+ maintainers |
| Remove admin bypass | delete `bypass_actors` from `main`/`staging` | Needs 2+ approvers |
| **Merge queue** on `main` | ruleset `merge_queue` rule | Useful once many PRs merge per day |
| Require 2FA for the org | org Settings → Authentication security | Members without 2FA are removed |
| `strict_required_status_checks_policy: true` | rulesets | Branch must be up to date with its base before merging. Safer, but slower |
