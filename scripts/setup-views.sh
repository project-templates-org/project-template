#!/usr/bin/env bash
# (Re)creates the standard views on an org project board with grouping, sorting and
# visible fields (REST Projects views API). Existing views with the same names are replaced.
#
# Usage: scripts/setup-views.sh <org> <project-number> [basic|product]
#   basic   - "Project Template" board (one repo, Status ... Done)              [default]
#   product - "Product Template" board (many repos, sprint != release:
#             ... Dev done → In staging → Verified → Released, Release train field)
#
# Not settable by any API (do in the UI, see docs/manual-setup-guide.md §4.4):
#   roadmap date fields / zoom / markers, field sums, column limits, Insights charts.
set -euo pipefail

ORG="${1:?usage: scripts/setup-views.sh <org> <project-number>}"
NUM="${2:?usage: scripts/setup-views.sh <org> <project-number>}"
PRESET="${3:-basic}"

# field name -> REST field id
declare -A F
while IFS='=' read -r name id; do F["$name"]="$id"; done < <(
  gh api "orgs/$ORG/projectsV2/$NUM/fields?per_page=100" --jq '.[] | "\(.name)=\(.id)"')
COMMON=(Title Status Priority Size Estimate Iteration "Start date" "Target date" Assignees Labels Type "Parent issue" "Sub-issues progress" "Linked pull requests" Milestone Repository Reviewers)
case "$PRESET" in
  basic) NEED=("${COMMON[@]}" Area) ;;
  product) NEED=("${COMMON[@]}" Release "Found in") ;;
  *) echo "unknown preset '$PRESET' (basic|product)"; exit 1 ;;
esac
for need in "${NEED[@]}"; do
  [ -n "${F[$need]:-}" ] || { echo "ERROR: field '$need' missing on project $NUM"; exit 1; }
done
ids() { local out=""; for n in "$@"; do out="$out${F[$n]},"; done; echo "[${out%,}]"; }
asc() { echo "[${F[$1]},\"asc\"]"; }

# Existing views (name -> node id), used to replace views with the same name
declare -A OLD
while IFS=$'\t' read -r name id; do OLD["$name"]="$id"; done < <(
  gh api graphql -f query='query($o:String!,$n:Int!){ organization(login:$o){ projectV2(number:$n){ views(first:50){ nodes { id name } } } } }' \
    -f o="$ORG" -F n="$NUM" --jq '.data.organization.projectV2.views.nodes[] | "\(.name)\t\(.id)"')
CREATED=()

view() { # name layout filter json-extra
  local name="$1" layout="$2" filter="${3//\"/\\\"}" extra="$4"
  local body="{\"name\":\"$name\",\"layout\":\"$layout\",\"filter\":\"$filter\"${extra:+,$extra}}"
  echo "$body" | gh api -X POST "orgs/$ORG/projectsV2/$NUM/views" --input - --jq '"  + \(.name) (\(.layout))"'
  CREATED+=("$name")
}

echo "==> Creating '$PRESET' views on $ORG project #$NUM"
preset_basic() {
# Daily work
view "Board" board "-status:Done" \
  "\"vertical_group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Assignees Priority Size Iteration Labels Type)"
view "Current sprint" board "iteration:@current" \
  "\"vertical_group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Assignees Priority Size Estimate Labels Type)"
view "My work" board "assignee:@me -status:Done" \
  "\"vertical_group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Priority Size Iteration Type)"
view "Review queue" table "is:pr is:open" \
  "\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Assignees Reviewers Status Priority "Linked pull requests" Repository Labels)"
# Planning
view "Backlog" table "-status:Done" \
  "\"group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Priority Size Estimate Area Iteration Assignees "Parent issue" Labels)"
view "Triage inbox" table "no:priority -status:Done" \
  "\"sort_by\":[$(asc Type)],\"visible_fields\":$(ids Title Type Status Priority Size Area Labels Repository)"
view "Sprint planning" table "-status:Done" \
  "\"group_by\":$(ids Iteration),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Status Priority Size Estimate Assignees "Parent issue")"
view "Team workload" table "-status:Done -no:assignee" \
  "\"group_by\":$(ids Assignees),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Status Priority Size Estimate Iteration)"
view "Sprint review" table "iteration:@current status:Done" \
  "\"sort_by\":[$(asc Type)],\"visible_fields\":$(ids Title Type Assignees Estimate "Linked pull requests" "Parent issue")"
# Delivery & quality
view "Epics" table "type:Epic" \
  "\"sort_by\":[$(asc "Target date")],\"visible_fields\":$(ids Title Status "Sub-issues progress" Priority "Start date" "Target date" Milestone Assignees)"
view "Bugs" table "type:Bug -status:Done" \
  "\"group_by\":$(ids Priority),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Status Priority Size Area Assignees Labels Repository)"
view "Blocked" table "label:blocked -status:Done" \
  "\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Status Priority Assignees Labels "Parent issue")"
# Roadmaps (date fields must be set once in the UI: view menu → Dates → Start date / Target date)
view "Roadmap" roadmap "type:Epic,Feature" "\"sort_by\":[$(asc "Start date")]"
view "Roadmap by area" roadmap "type:Epic,Feature" "\"group_by\":$(ids Area),\"sort_by\":[$(asc "Start date")]"

}

preset_product() {
  local open='-status:Released'
  local shipping='status:"Dev done","In staging",Verified,Released'
  # Sprint work (sprint goal = Dev done)
  view "Sprint board" board "iteration:@current"     "\"vertical_group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Assignees Priority Size Estimate Repository Labels Type)"
  view "My work" board "assignee:@me $open"     "\"vertical_group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Priority Size Iteration Repository Type)"
  view "By repository" board "$open"     "\"vertical_group_by\":$(ids Status),\"group_by\":$(ids Repository),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Assignees Priority Size Iteration Type)"
  # Release flow (Dev done -> production)
  view "Release board" board "$shipping"     "\"vertical_group_by\":$(ids Status),\"group_by\":$(ids Release),\"sort_by\":[$(asc Repository)],\"visible_fields\":$(ids Title Assignees Repository Iteration Labels Type)"
  view "QA queue" table 'status:"In staging"'     "\"group_by\":$(ids Repository),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Status Priority Assignees Release Labels "Linked pull requests")"
  view "Release readiness" table "$open -status:Backlog,Ready"     "\"group_by\":$(ids Release),\"sort_by\":[$(asc Status)],\"visible_fields\":$(ids Title Type Repository Status Priority Assignees Labels)"
  view "Released" table "status:Released"     "\"group_by\":$(ids Release),\"sort_by\":[$(asc Repository)],\"visible_fields\":$(ids Title Type Repository Assignees Iteration "Linked pull requests" Labels)"
  # Planning
  view "Backlog" table "status:Backlog,Ready"     "\"group_by\":$(ids Status),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Repository Priority Size Estimate Iteration Release Assignees Labels "Parent issue")"
  view "Triage inbox" table "no:priority $open"     "\"sort_by\":[$(asc Type)],\"visible_fields\":$(ids Title Type Repository Status Priority Size "Found in" Labels)"
  view "Sprint planning" table "$open"     "\"group_by\":$(ids Iteration),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Repository Status Priority Size Estimate Assignees)"
  view "Team workload" table "$open -status:Verified -no:assignee"     "\"group_by\":$(ids Assignees),\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Repository Status Priority Size Estimate Iteration)"
  # Quality & tracking
  view "Bugs" table "type:Bug $open"     "\"group_by\":$(ids Priority),\"sort_by\":[$(asc Status)],\"visible_fields\":$(ids Title Repository Status Priority "Found in" Size Assignees Release Labels)"
  view "Blocked" table "label:blocked $open"     "\"sort_by\":[$(asc Priority)],\"visible_fields\":$(ids Title Type Repository Status Priority Assignees Labels)"
  view "Epics & features" table "type:Epic,Feature"     "\"sort_by\":[$(asc "Target date")],\"visible_fields\":$(ids Title Type Status "Sub-issues progress" Priority Release "Start date" "Target date" Assignees)"
  # Timeline (date fields must be set once in the UI: view menu → Dates → Start date / Target date)
  view "Roadmap" roadmap "$open" "\"group_by\":$(ids Release),\"sort_by\":[$(asc "Start date")]"
}

"preset_$PRESET"

echo "==> Removing old views"
for name in "${!OLD[@]}"; do
  gh api graphql -f query='mutation($v:ID!){ deleteProjectV2View(input:{viewId:$v}){ clientMutationId } }' -f v="${OLD[$name]}" >/dev/null \
    && echo "  - $name" || echo "  ! could not delete $name"
done
echo "Done: ${#CREATED[@]} views. Remaining UI-only steps: roadmap dates, field sums, column limits, charts."
