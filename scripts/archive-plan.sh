#!/bin/bash
###############################################################################
# archive-plan.sh - Retire a completed plan into .planning/.archive/
#
# Usage:
#   bash scripts/archive-plan.sh <plan-slug>
#   bash scripts/archive-plan.sh --all-complete
#   bash scripts/archive-plan.sh <plan-slug> --force     # archive an unfinished plan
#   bash scripts/archive-plan.sh <plan-slug> --dry-run
#
# What it does:
#   1. Refuses unless the plan is complete (every checkbox checked, or the
#      top-level artifact declares `status: done`) -- override with --force.
#   2. Ensures .planning/.archive/ exists and is gitignored.
#   3. Moves .planning/<slug>/ to .planning/.archive/<slug>/ (git mv when the
#      plan is tracked, so history follows it).
#   4. Stamps the plan's top-level artifact with status: archived + archived_on.
#
# Nothing is ever deleted. Restore by moving the directory back out.
###############################################################################
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/planning.sh"

SLUG=""
ALL_COMPLETE=0
FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all-complete) ALL_COMPLETE=1; shift ;;
    --force)        FORCE=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)             planning_err "Unknown option: $1"; exit 1 ;;
    *)              [[ -z "$SLUG" ]] && SLUG="$1"; shift ;;
  esac
done

if [[ -z "$SLUG" && $ALL_COMPLETE -eq 0 ]]; then
  planning_err "A plan slug is required (or --all-complete)."
  echo "Usage: bash scripts/archive-plan.sh <plan-slug> [--force] [--dry-run]"
  exit 1
fi

ROOT=$(planning_root)
PLANNING="$(planning_dir)"
ARCHIVE="${PLANNING}/.archive"
TODAY=$(planning_today)

# .planning/.archive/ must be gitignored: completed plans are local history, not
# something every clone should carry. Shared with the init scripts so there is one
# rule, not two — it also warns when a blanket .planning/ entry is hiding everything.
ensure_gitignored() {
  planning_ensure_archive_gitignored "${ROOT}" 1
}

plan_root_artifact() {
  for f in "$1/phase.md" "$1/task_plan.md" "$1/task.md"; do
    [[ -f "$f" ]] && { echo "$f"; return; }
  done
}

# Stamp the plan's top-level artifact so an archived plan reads as archived even
# when someone opens the file directly, with no directory context.
stamp_archived() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if head -1 "$file" | grep -q '^---$'; then
    # Frontmatter: flip status and add archived_on before the closing delimiter.
    awk -v today="$TODAY" '
      NR == 1 { print; next }
      !done_fm && /^status:[[:space:]]*/ { print "status: archived"; seen_status = 1; next }
      !done_fm && /^---$/ {
        if (!seen_status) print "status: archived"
        print "archived_on: \"" today "\""
        print; done_fm = 1; next
      }
      { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    printf '\n---\n\n**Archived %s** — retired by `scripts/archive-plan.sh`.\n' "$TODAY" >> "$file"
  fi
}

archive_one() {
  local slug="$1"
  local src="${PLANNING}/${slug}"
  local dest="${ARCHIVE}/${slug}"

  if [[ ! -d "$src" ]]; then
    planning_err "No such plan: .planning/${slug}/"
    return 1
  fi
  if [[ -e "$dest" ]]; then
    planning_err "Already archived: .planning/.archive/${slug}/ exists. Move or rename it first."
    return 1
  fi

  if [[ $FORCE -eq 0 ]]; then
    local complete
    complete=$(bash "${SCRIPT_DIR}/plan-status.sh" --complete | grep -Fx "$slug" || true)
    if [[ -z "$complete" ]]; then
      planning_err "Plan '${slug}' is not complete — refusing to archive."
      echo "  Check what is outstanding with: bash scripts/plan-status.sh"
      echo "  Archive anyway with:            bash scripts/archive-plan.sh ${slug} --force"
      return 1
    fi
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    planning_log "[dry-run] would archive .planning/${slug}/ -> .planning/.archive/${slug}/"
    return 0
  fi

  ensure_gitignored
  mkdir -p "$ARCHIVE"

  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 \
     && [[ -n "$(git -C "$ROOT" ls-files ".planning/${slug}" 2>/dev/null)" ]]; then
    git -C "$ROOT" mv ".planning/${slug}" ".planning/.archive/${slug}"
  else
    mv "$src" "$dest"
  fi

  stamp_archived "$(plan_root_artifact "$dest")"
  planning_ok "Archived .planning/${slug}/ -> .planning/.archive/${slug}/"
}

RC=0
if [[ $ALL_COMPLETE -eq 1 ]]; then
  mapfile -t SLUGS < <(bash "${SCRIPT_DIR}/plan-status.sh" --complete)
  if [[ ${#SLUGS[@]} -eq 0 || -z "${SLUGS[0]}" ]]; then
    planning_log "No complete plans to archive."
    exit 0
  fi
  for s in "${SLUGS[@]}"; do archive_one "$s" || RC=1; done
else
  archive_one "$SLUG" || RC=1
fi
exit $RC
