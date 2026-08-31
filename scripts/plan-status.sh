#!/bin/bash
###############################################################################
# plan-status.sh - Report completion status for every plan under .planning/
#
# Usage:
#   bash scripts/plan-status.sh              # table of every active plan
#   bash scripts/plan-status.sh --nudge      # one line if plans are archivable, else silence
#   bash scripts/plan-status.sh --complete   # print the slug of each complete plan, one per line
#
# A plan is COMPLETE when every checkbox in it is checked, or when its
# top-level artifact declares `status: done` in frontmatter. Completion is
# derived from the artifacts themselves so no separate state file can drift
# away from what the plan actually says.
#
# This is the single implementation of the scan: the SessionStart hook and the
# /plan-status slash command both shell out to it.
###############################################################################
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/planning.sh"

MODE="table"
case "${1:-}" in
  --nudge)    MODE="nudge" ;;
  --complete) MODE="complete" ;;
  -h|--help)
    sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  "") ;;
  *)
    planning_err "Unknown option: $1 (try --help)"
    exit 1
    ;;
esac

PLANNING="$(planning_dir)"
[[ -d "$PLANNING" ]] || { [[ "$MODE" == "table" ]] && planning_warn "No .planning/ directory here."; exit 0; }

# plan_root_artifact <plan-dir> -> path of the plan's top-level file, or empty
plan_root_artifact() {
  for f in "$1/phase.md" "$1/task_plan.md" "$1/task.md"; do
    [[ -f "$f" ]] && { echo "$f"; return; }
  done
}

# frontmatter_status <file> -> value of `status:` inside the leading --- block
frontmatter_status() {
  [[ -f "$1" ]] || return
  awk 'NR==1 && $0 != "---" { exit }
       NR>1 && $0 == "---" { exit }
       /^status:[[:space:]]*/ { sub(/^status:[[:space:]]*/, ""); gsub(/["\047]/, ""); print; exit }' "$1"
}

# Emits "<total> <checked>" for every markdown file under a plan directory.
count_boxes() {
  local total checked
  total=$(grep -rhoE '^[[:space:]]*- \[[ xX]\] ' --include='*.md' "$1" 2>/dev/null | wc -l | tr -d ' ')
  checked=$(grep -rhoE '^[[:space:]]*- \[[xX]\] ' --include='*.md' "$1" 2>/dev/null | wc -l | tr -d ' ')
  echo "$total $checked"
}

COMPLETE=()
ROWS=()

for plan_path in "$PLANNING"/*/; do
  [[ -d "$plan_path" ]] || continue
  slug=$(basename "$plan_path")
  case "$slug" in .meta|.archive|archive) continue ;; esac

  root=$(plan_root_artifact "${plan_path%/}")
  [[ -n "$root" ]] || continue

  read -r total checked <<<"$(count_boxes "${plan_path%/}")"
  status=$(frontmatter_status "$root")
  blocked=$(grep -rl '^status: blocked' --include='*.md' "${plan_path%/}" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$status" == "archived" ]]; then
    verdict="archived"
  elif [[ "$status" == "done" ]] || { [[ "$total" -gt 0 ]] && [[ "$checked" -eq "$total" ]]; }; then
    verdict="COMPLETE"
    COMPLETE+=("$slug")
  elif [[ "$blocked" -gt 0 ]]; then
    verdict="blocked"
  elif [[ "$total" -eq 0 ]]; then
    verdict="empty"
  else
    verdict="in progress"
  fi

  ROWS+=("$(printf '%-38s %-12s %s/%s boxes' "$slug" "$verdict" "$checked" "$total")")
done

case "$MODE" in
  complete)
    printf '%s\n' "${COMPLETE[@]+"${COMPLETE[@]}"}"
    ;;
  nudge)
    if [[ ${#COMPLETE[@]} -gt 0 ]]; then
      printf 'persistent-planning: %d plan(s) complete but not archived — %s. Archive with: /archive-plan <slug>\n' \
        "${#COMPLETE[@]}" "$(IFS=', '; echo "${COMPLETE[*]}")"
    fi
    ;;
  table)
    if [[ ${#ROWS[@]} -eq 0 ]]; then
      planning_warn "No plans found under .planning/."
      exit 0
    fi
    planning_log "Plans under .planning/"
    echo ""
    printf '  %-38s %-12s %s\n' "PLAN" "STATUS" "PROGRESS"
    printf '  %s\n' "$(printf '%.0s-' {1..70})"
    printf '  %s\n' "${ROWS[@]}"
    echo ""
    if [[ ${#COMPLETE[@]} -gt 0 ]]; then
      planning_ok "${#COMPLETE[@]} plan(s) ready to archive:"
      for s in "${COMPLETE[@]}"; do echo "    bash scripts/archive-plan.sh $s"; done
    fi
    ;;
esac
