#!/usr/bin/env bash
# Bootstrap a repository created from project-templates-org/project-template.
#
# GitHub does NOT copy rulesets, extra branches, settings or project boards when a repo is
# generated from a template — this script applies all of them. It is idempotent (safe to re-run).
#
# Usage (create the project board first in the UI from the "Project Template" template,
# named like --project-title; see docs/github-setup.md §3):
#   scripts/bootstrap.sh <owner>/<repo> [--project-title "My Project"] [--no-project]
#                        [--sprint-start YYYY-MM-DD] [--sprint-days 14] [--sprints 6]
#
# Requires: gh CLI authenticated with a token that has (repo) Administration, Contents, Issues,
# Pull requests, Workflows, Actions = read/write and (org) Projects = read/write.
set -euo pipefail

REPO="${1:?usage: scripts/bootstrap.sh <owner>/<repo> [--project-title TITLE] [--no-project]}"
shift
OWNER="${REPO%%/*}"
PROJECT_TITLE=""
SPRINT_START=""
SPRINT_DAYS=14
SPRINTS=6
WITH_PROJECT=true
TEMPLATE_PROJECT_TITLE="Project Template"
while [ $# -gt 0 ]; do
  case "$1" in
    --project-title) PROJECT_TITLE="$2"; shift 2 ;;
    --no-project) WITH_PROJECT=false; shift ;;
    --sprint-start) SPRINT_START="$2"; shift 2 ;;
    --sprint-days) SPRINT_DAYS="$2"; shift 2 ;;
    --sprints) SPRINTS="$2"; shift 2 ;;
    *) echo "unknown option $1"; exit 1 ;;
  esac
done
PROJECT_TITLE="${PROJECT_TITLE:-${REPO#*/}}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

step() { printf '\n==> %s\n' "$*"; }
# Date helpers: GNU date (Linux, Git Bash) with a BSD/macOS fallback
add_days() { date -u -d "$1 +$2 days" +%F 2>/dev/null || date -u -j -v+"$2"d -f %F "$1" +%F; }
next_monday() { # today if Monday, else the coming Monday
  local dow; dow="$(date -u +%u)"
  if [ "$dow" = 1 ]; then date -u +%F; else add_days "$(date -u +%F)" $(( 8 - dow )); fi
}

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

step "Code scanning (CodeQL default setup)"
# Scans GitHub Actions workflows from day one; CodeQL adds more languages automatically when it detects them.
gh api -X PATCH "repos/$REPO/code-scanning/default-setup" -f state=configured -f query_suite=default >/dev/null \
  && echo "CodeQL default setup on" || echo "WARN: code scanning needs a public repo or GitHub Code Security"

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

step "Environments (development / staging / production)"
# Each environment only accepts deployments from its branch; production also needs an approval
# from the person running bootstrap (change reviewers in Settings → Environments).
ME_ID="$(gh api user --jq '.id')"
env_branch() { case "$1" in development) echo development ;; staging) echo staging ;; production) echo main ;; esac; }
for env in development staging production; do
  if [ "$env" = production ]; then
    body="{\"wait_timer\":0,\"prevent_self_review\":false,\"reviewers\":[{\"type\":\"User\",\"id\":$ME_ID}],\"deployment_branch_policy\":{\"protected_branches\":false,\"custom_branch_policies\":true}}"
  else
    body='{"wait_timer":0,"reviewers":[],"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}'
  fi
  echo "$body" | gh api -X PUT "repos/$REPO/environments/$env" --input - >/dev/null
  branch="$(env_branch "$env")"
  if ! gh api "repos/$REPO/environments/$env/deployment-branch-policies" --jq '.branch_policies[].name' | grep -qx "$branch"; then
    gh api -X POST "repos/$REPO/environments/$env/deployment-branch-policies" -f name="$branch" -f type=branch >/dev/null
  fi
  echo "$env ← $branch"
done

step "Private vulnerability reporting"
gh api -X PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null && echo "on"

step "Labels (runs labels-sync workflow)"
gh workflow run labels-sync.yml --repo "$REPO" --ref main && echo "labels-sync triggered" \
  || echo "WARN: could not trigger labels-sync (Actions disabled?)"

if [ "$WITH_PROJECT" = true ]; then
  step "Project board '$PROJECT_TITLE'"
  # Boards are created in the GitHub UI from the template ("New project → Templates → Project
  # Template"). The API copy (gh project copy) times out on a template this size and silently
  # drops Insights charts and draft items, so this script never copies the board itself.
  NUM="$(gh project list --owner "$OWNER" --format json --limit 200 --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number" | head -1)"
  if [ -z "$NUM" ]; then
    cat <<EOF
Board '$PROJECT_TITLE' not found. Create it, then re-run this script:
  1. https://github.com/orgs/$OWNER/projects → New project → Templates → "$TEMPLATE_PROJECT_TITLE"
  2. Name it exactly: $PROJECT_TITLE  → Create project
  3. bash scripts/bootstrap.sh $REPO --project-title "$PROJECT_TITLE"
EOF
    PROJECT_PENDING=true
  else
    echo "found #$NUM"
    # Not yet linked to any repository = just created from the template = sprints still hold
    # the template's dates and get replaced below.
    linked="$(gh api graphql -f query='query($o:String!,$n:Int!){ organization(login:$o){ projectV2(number:$n){ repositories(first:1){ totalCount } } } }'       -f o="$OWNER" -F n="$NUM" --jq '.data.organization.projectV2.repositories.totalCount')"
    [ "$linked" = 0 ] && FRESH_COPY=true
    gh project link "$NUM" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 && echo "linked to $REPO" || echo "already linked"

    step "Sprints (Iteration field)"
    # A fresh copy inherits the template's sprint dates, so it always gets its own schedule.
    # On re-runs, an existing board keeps its sprints while it has a current or upcoming one
    # (never wipes real sprint data); pass --sprint-start to force a new schedule.
    IT_Q='query($o:String!,$n:Int!){ organization(login:$o){ projectV2(number:$n){ field(name:"Iteration"){ ... on ProjectV2IterationField { id configuration { iterations { startDate duration } } } } } } }'
    IT_ID="$(gh api graphql -f query="$IT_Q" -f o="$OWNER" -F n="$NUM" --jq '.data.organization.projectV2.field.id // empty')"
    LAST_END="$(gh api graphql -f query="$IT_Q" -f o="$OWNER" -F n="$NUM"     --jq '[.data.organization.projectV2.field.configuration.iterations[] | (.startDate | strptime("%Y-%m-%d") | mktime) + .duration * 86400] | (max // 0) | strftime("%Y-%m-%d")')"
    if [ -z "$IT_ID" ]; then
      echo "WARN: no Iteration field on project #$NUM"
    elif [ "${FRESH_COPY:-false}" != true ] && [ -z "$SPRINT_START" ] && [[ "$LAST_END" > "$(date -u +%F)" ]]; then
      echo "has current/upcoming sprints (until $LAST_END) - left unchanged (pass --sprint-start to reset)"
    else
      START="${SPRINT_START:-$(next_monday)}"
      its=""
      for i in $(seq 0 $((SPRINTS - 1))); do
        its="$its{title:\"Sprint $((i + 1))\", startDate:\"$(add_days "$START" $((i * SPRINT_DAYS)))\", duration:$SPRINT_DAYS},"
      done
      gh api graphql -f query="mutation{ updateProjectV2Field(input:{fieldId:\"$IT_ID\", iterationConfiguration:{startDate:\"$START\", duration:$SPRINT_DAYS, iterations:[${its%,}]}}){ clientMutationId } }" >/dev/null
      echo "$SPRINTS sprints of $SPRINT_DAYS days from $START"
    fi
    echo "https://github.com/orgs/$OWNER/projects/$NUM"
  fi
fi

if [ "${PROJECT_PENDING:-false}" = true ]; then
  echo
  echo "==> NOT DONE: create the board '$PROJECT_TITLE' from the template in the UI (see above), then re-run."
  exit 2
fi

cat <<EOF

==> Done. Remaining manual steps (no API) — docs/manual-setup-guide.md:
  1. Board → Workflows → "Auto-add to project": repo $REPO, filter is:issue,pr is:open
     (the only workflow a template copy doesn't keep; views, charts and other workflows come with it).
  2. Replace CODEOWNERS owners with your team, and add project-specific checks to scripts/ci.sh.
EOF
