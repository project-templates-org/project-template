# project-template

Template repository for projects in **project-templates-org**. It is language-agnostic: it holds the project's management setup (branches, reviews, checks, labels, releases and the project board), not application code.

## Use it

1. **Repository:**
   ```bash
   gh repo create project-templates-org/<name> --template project-templates-org/project-template --public --clone
   cd <name>
   ```
2. **Board (in the GitHub website):** [org Projects](https://github.com/orgs/project-templates-org/projects) → **New project** → **Templates** tab → **Project Template** → name it `<Name>` → **Create project**.
   The website copy keeps everything: fields, sprints, 14 views, Insights charts, automations and onboarding drafts. Don't use `gh project copy`: on a template this size it times out and silently drops the charts and drafts.
3. **Apply everything else:**
   ```bash
   bash scripts/bootstrap.sh project-templates-org/<name> --project-title "<Name>"
   ```

Or click **Use this template**, then run `bootstrap.sh`. GitHub doesn't copy rulesets, extra branches or boards from a template, so the script sets them up. It's safe to run more than once.

After that:
1. Replace this README with your project's.
2. Put the real lint/test/build commands in [`scripts/ci.sh`](scripts/ci.sh).
3. Add your package ecosystems to [`.github/dependabot.yml`](.github/dependabot.yml).
4. Set your team in [`.github/CODEOWNERS`](.github/CODEOWNERS).
5. Do the UI-only steps in [docs/github-setup.md](docs/github-setup.md#4-manual-steps-ui-only--no-api-exists).

## What's inside

```
.github/
  workflows/      pr-checks, ci (+actionlint), release, sync-down, labels-sync, deploy, scorecard, stale
  rulesets/       main, staging, development, release-backups, version-tags  (applied by bootstrap)
  labels.yml      label definitions
  release.yml     release-note categories
  dependabot.yml  dependency updates (target: development)
  CODEOWNERS
scripts/
  bootstrap.sh    applies settings, branches, rulesets, environments, labels and the project board
  ci.sh           generic checks + your project checks
  deploy.sh       deployment placeholder (called per environment by deploy.yml)
  setup-views.sh  (re)creates the 14 standard board views with grouping and sorting
docs/             workflow, branching, project management, releases, security, setup, decisions
```

## Flow at a glance

`feature/*` → **development** → **staging** → **main** → `vX.Y.Z` tag and read-only `release/vX.Y.Z` backup branch. Hotfixes branch from `main` and are merged back down automatically.

Several repos for one product (e.g. API + web + mobile) on one board, with sprints separate from releases? Use the **Product Template** board: see [docs/status-and-release-flow.md](docs/status-and-release-flow.md).

Start with [docs/](docs/README.md). To do everything by hand instead of running the script, follow the [manual setup guide](docs/manual-setup-guide.md).
