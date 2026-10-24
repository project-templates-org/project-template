# project-template

Template repository for projects in **project-templates-org**. It is language-agnostic: it holds the project's management setup (branches, reviews, checks, labels, releases and the project board), not application code.

## Use it

```bash
gh repo create project-templates-org/<name> --template project-templates-org/project-template --public --clone
cd <name>
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
  workflows/      pr-checks (branch-flow, pr-title, auto-label), ci, release, sync-down, labels-sync, deploy
  rulesets/       main, staging, development, release-backups, version-tags  (applied by bootstrap)
  labels.yml      label definitions
  release.yml     release-note categories
  dependabot.yml  dependency updates (target: development)
  CODEOWNERS
scripts/
  bootstrap.sh    applies settings, branches, rulesets, environments, labels and the project board
  ci.sh           generic checks + your project checks
  deploy.sh       deployment placeholder (called per environment by deploy.yml)
docs/             workflow, branching, project management, releases, setup, decisions
```

## Flow at a glance

`feature/*` → **development** → **staging** → **main** → `vX.Y.Z` tag and read-only `release/vX.Y.Z` backup branch. Hotfixes branch from `main` and are merged back down automatically.

Start with [docs/](docs/README.md).
