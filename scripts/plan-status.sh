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

# frontmatter_field <file> <key> -> value of `<key>:` inside the leading --- block
#
# Scoped to the frontmatter on purpose. Grepping a whole file for a frontmatter field
# matches it in prose, tables and fenced examples too — a notes.md documenting the
# contract then reads as an artifact that declares it (issue #14).
frontmatter_field() {
  [[ -f "$1" ]] || return
  awk -v key="$2" '
    NR==1 && $0 != "---" { exit }
    NR>1 && $0 == "---" { exit }
    index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "")
      gsub(/["\047]/, "")
      sub(/[[:space:]]+$/, "")
      print; exit
    }' "$1"
}

# frontmatter_status <file> -> value of `status:` inside the leading --- block
frontmatter_status() {
  frontmatter_field "$1" "status"
}

# Emits "<total> <checked>" for every markdown file under a plan directory.
#
# Checkboxes inside fenced code blocks are examples, not work. A plan whose notes.md
# quotes markdown — which is what notes.md is for — used to have those quoted boxes
# counted against it, and a quoted `- [ ]` inflates only the denominator, so the plan
# became permanently uncompletable with no visible reason (issue #14).
#
# An unterminated fence swallows the rest of the file. That is the safe direction:
# ambiguous content is not counted as outstanding work.
count_boxes() {
  local total=0 checked=0 f out
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    out=$(awk '
      # Fence open/close: ``` or ~~~, optionally indented, optional info string.
      # A fence closes only on the same character.
      /^[[:space:]]*(```|~~~)/ {
        line = $0
        sub(/^[[:space:]]*/, "", line)
        ch = substr(line, 1, 1)
        if (!infence) { infence = 1; fencechar = ch }
        else if (ch == fencechar) { infence = 0 }
        next
      }
      infence { next }
      /^[[:space:]]*- \[[ xX]\] / { t++ }
      /^[[:space:]]*- \[[xX]\] /  { c++ }
      END { print t + 0, c + 0 }
    ' "$f" 2>/dev/null) || continue
    total=$((total + ${out%% *}))
    checked=$((checked + ${out##* }))
  done < <(find "$1" -type f -name '*.md' 2>/dev/null)
  echo "$total $checked"
}

# Files under a plan whose FRONTMATTER declares <key>: <value>.
frontmatter_files_with() {
  local dir="$1" key="$2" want="$3" f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    [[ "$(frontmatter_field "$f" "$key")" == "$want" ]] && echo "$f"
  done < <(find "$dir" -type f -name '*.md' 2>/dev/null)
}

# Counts mandatory tasks under a plan that are not yet done.
#
# The two closing tasks carry `mandatory: true`. A plan cannot be COMPLETE while one
# of them is unfinished, however the boxes happen to add up — that gate was stated in
# the templates and enforced nowhere (issue #12).
#
# Additive by design: a plan with no `mandatory: true` artifacts behaves exactly as it
# did before. Retroactively reopening finished plans would be worse than the bug.
unfinished_mandatory() {
  local n=0 f st
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    st=$(frontmatter_status "$f")
    [[ "$st" == "done" || "$st" == "archived" ]] || n=$((n + 1))
  done < <(frontmatter_files_with "$1" "mandatory" "true")
  echo "$n"
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
  blocked=$(frontmatter_files_with "${plan_path%/}" "status" "blocked" | wc -l | tr -d ' ')
  pending_mandatory=$(unfinished_mandatory "${plan_path%/}")

  if [[ "$status" == "archived" ]]; then
    verdict="archived"
  elif [[ "$status" == "done" ]] || { [[ "$total" -gt 0 ]] && [[ "$checked" -eq "$total" ]]; }; then
    if [[ "$pending_mandatory" -gt 0 ]]; then
      # Every box ticked, but a mandatory closer is not done. Not complete.
      verdict="in progress"
    else
      verdict="COMPLETE"
      COMPLETE+=("$slug")
    fi
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
