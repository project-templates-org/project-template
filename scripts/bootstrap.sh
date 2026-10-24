#!/usr/bin/env bash
# Bootstrap a repository created from project-templates-org/project-template.
#
# GitHub does NOT copy rulesets, extra branches, settings or project boards when a repo is
# generated from a template — this script applies all of them. It is idempotent (safe to re-run).
#
# Usage:
#   scripts/bootstrap.sh <owner>/<repo> [--project-title "My Project"] [--no-project]
#
# Requires: gh CLI authenticated with a token that has (repo) Administration, Contents, Issues,
# Pull requests, Workflows, Actions = read/write and (org) Projects = read/write.
set -euo pipefail

REPO="${1:?usage: scripts/bootstrap.sh <owner>/<repo> [--project-title TITLE] [--no-project]}"
shift
OWNER="${REPO%%/*}"
PROJECT_TITLE=""
WITH_PROJECT=true
TEMPLATE_PROJECT_TITLE="Project Template"
while [ $# -gt 0 ]; do
  case "$1" in
    --project-title) PROJECT_TITLE="$2"; shift 2 ;;
    --no-project) WITH_PROJECT=false; shift ;;
    *) echo "unknown option $1"; exit 1 ;;
  esac
done
PROJECT_TITLE="${PROJECT_TITLE:-${REPO#*/}}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

step() { printf '\n==> %s\n' "$*"; }

step "Repository settings"
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true -F allow_merge_commit=true -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=true -F allow_update_branch=true \
  -F has_wiki=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -f merge_commit_title=PR_TITLE -f merge_commit_message=PR_BODY >/dev/null
echo "merge settings applied"

step "Security features"
gh api -X PUT "repos/$REPO/vulnerability-alerts" >/dev/null && echo "dependabot alerts on"
gh api -X PUT "repos/$REPO/automated-security-fixes" >/dev/null && echo "dependabot security updates on"
gh api -X PATCH "repos/$REPO" --input - >/dev/null <<'EOF' && echo "secret scanning + push protection on" || echo "WARN: secret scanning needs a public repo or GitHub Advanced Security"
{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}
EOF

step "Actions: allow workflows to open PRs (sync-down back-merges)"
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true >/dev/null \
  && echo "ok" || echo "WARN: blocked by org policy — enable in org Settings → Actions → General"

step "Long-lived branches"
MAIN_SHA="$(gh api "repos/$REPO/git/ref/heads/main" --jq '.object.sha')"
for b in staging development; do
  if gh api "repos/$REPO/git/ref/heads/$b" >/dev/null 2>&1; then
    echo "$b exists"
  else
    gh api "repos/$REPO/git/refs" -f ref="refs/heads/$b" -f sha="$MAIN_SHA" >/dev/null && echo "$b created from main"
  fi
done

step "Rulesets (.github/rulesets/*.json)"
for f in "$HERE"/.github/rulesets/*.json; do
  name="$(basename "$f" .json)"
  id="$(gh api "repos/$REPO/rulesets" --jq ".[] | select(.name==\"$name\") | .id")"
  if [ -n "$id" ]; then
    gh api -X PUT "repos/$REPO/rulesets/$id" --input "$f" >/dev/null && echo "updated $name"
  else
    gh api -X POST "repos/$REPO/rulesets" --input "$f" >/dev/null && echo "created $name"
  fi
done

step "Labels (runs labels-sync workflow)"
gh workflow run labels-sync.yml --repo "$REPO" --ref main && echo "labels-sync triggered" \
  || echo "WARN: could not trigger labels-sync (Actions disabled?)"

if [ "$WITH_PROJECT" = true ]; then
  step "Project board (copy of '$TEMPLATE_PROJECT_TITLE')"
  existing="$(gh project list --owner "$OWNER" --format json --limit 200 --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number")"
  if [ -n "$existing" ]; then
    NUM="$existing"; echo "project '$PROJECT_TITLE' exists (#$NUM)"
  else
    TPL="$(gh project list --owner "$OWNER" --format json --limit 200 --jq ".projects[] | select(.title==\"$TEMPLATE_PROJECT_TITLE\") | .number" | head -1)"
    [ -n "$TPL" ] || { echo "ERROR: template project '$TEMPLATE_PROJECT_TITLE' not found in $OWNER"; exit 1; }
    NUM="$(gh project copy "$TPL" --source-owner "$OWNER" --target-owner "$OWNER" --title "$PROJECT_TITLE" --drafts --format json --jq '.number')"
    echo "created project #$NUM from template #$TPL"
  fi
  gh project link "$NUM" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 && echo "linked to $REPO" || echo "already linked"
  echo "https://github.com/orgs/$OWNER/projects/$NUM"
fi

cat <<EOF

==> Done. Manual steps (not available via API) — see docs/github-setup.md:
  1. Project → Workflows: enable "Auto-add to project" (filter: repo:$REPO is:issue,pr is:open),
     "Item closed" → Done, "Pull request merged" → Done, "Auto-archive items".
  2. Project views: set Group by / Sort / Slice where noted in docs/project-management.md.
  3. Replace CODEOWNERS owners with your team, and add project-specific checks to scripts/ci.sh.
EOF
