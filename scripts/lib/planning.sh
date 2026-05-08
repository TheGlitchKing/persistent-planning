#!/bin/bash
###############################################################################
# scripts/lib/planning.sh - Shared helpers for persistent-planning init scripts
#
# Source this file from init-phase.sh, init-task.sh, init-atom.sh, and any
# other planning-related script that needs slug, root, mode, or template
# rendering helpers.
#
# Usage:
#   #!/bin/bash
#   set -e
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/planning.sh"
#
# Provides:
#   - planning_slugify "Some Name"   →  "some-name" (echoed)
#   - planning_root                  →  prints project root (CLAUDE_PROJECT_DIR or pwd)
#   - planning_dir                   →  prints "<root>/.planning"
#   - planning_meta_dir              →  prints "<root>/.planning/.meta"
#   - planning_workspace_json        →  prints "<meta>/workspace.json"
#   - planning_mode                  →  prints active mode (sm | lg) via detect-mode.sh
#   - planning_today                 →  prints today's date as YYYY-MM-DD
#   - planning_render_template "<src>" "<dest>" "PLACEHOLDER1=value1" "PLACEHOLDER2=value2" ...
#       Renders a template file by sed-substituting PLACEHOLDER tokens.
#       Refuses to overwrite existing dest unless PLANNING_FORCE=1 in env.
#   - planning_color_<name>          →  ANSI color codes (green, blue, yellow, cyan, red, reset)
#                                       (only set when stdout is a tty; empty otherwise)
#   - Color-coded log helpers: planning_log, planning_ok, planning_warn, planning_err
###############################################################################

# Color codes (only when stdout is a tty)
if [[ -t 1 ]]; then
  planning_color_green='\033[0;32m'
  planning_color_blue='\033[0;34m'
  planning_color_yellow='\033[1;33m'
  planning_color_cyan='\033[0;36m'
  planning_color_red='\033[0;31m'
  planning_color_reset='\033[0m'
else
  planning_color_green=''
  planning_color_blue=''
  planning_color_yellow=''
  planning_color_cyan=''
  planning_color_red=''
  planning_color_reset=''
fi

planning_log()  { printf "${planning_color_blue}[planning]${planning_color_reset} %s\n" "$*"; }
planning_ok()   { printf "${planning_color_green}[planning]${planning_color_reset} %s\n" "$*"; }
planning_warn() { printf "${planning_color_yellow}[planning]${planning_color_reset} %s\n" "$*"; }
planning_err()  { printf "${planning_color_red}[planning]${planning_color_reset} %s\n" "$*" >&2; }

planning_slugify() {
  local name="$1"
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
  name=$(echo "$name" | sed 's/[[:space:]_]\+/-/g')
  name=$(echo "$name" | sed 's/[^a-z0-9-]//g')
  name=$(echo "$name" | sed 's/^-\+\|-\+$//g')
  name=$(echo "$name" | sed 's/-\+/-/g')
  echo "$name"
}

planning_root() {
  echo "${CLAUDE_PROJECT_DIR:-$(pwd)}"
}

planning_dir() {
  echo "$(planning_root)/.planning"
}

planning_meta_dir() {
  echo "$(planning_dir)/.meta"
}

planning_workspace_json() {
  echo "$(planning_meta_dir)/workspace.json"
}

planning_today() {
  date '+%Y-%m-%d'
}

planning_mode() {
  # Resolve via detect-mode.sh (in the same scripts/ dir as the caller's library).
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local detect="${lib_dir}/../detect-mode.sh"
  if [[ -x "$detect" ]]; then
    bash "$detect"
  else
    echo "sm"
  fi
}

# planning_render_template <template_src> <dest_path> <PLACEHOLDER1=value1> ...
# Renders a template file by sed-substituting placeholders.
#
# Return codes:
#   0  → rendered fresh
#   2  → skipped (dest already exists; pass PLANNING_FORCE=1 to overwrite)
#   1  → error (template not found, etc.)
#
# Callers can branch on the return code to log accurately.
planning_render_template() {
  local src="$1"
  local dest="$2"
  shift 2

  if [[ ! -f "$src" ]]; then
    planning_err "Template not found: $src"
    return 1
  fi

  if [[ -f "$dest" && "${PLANNING_FORCE:-0}" != "1" ]]; then
    planning_warn "Destination already exists, skipping: $dest"
    planning_warn "  (re-run with PLANNING_FORCE=1 to overwrite)"
    return 2
  fi

  # Copy template to dest
  cp "$src" "$dest"

  # Apply substitutions
  for kv in "$@"; do
    local key="${kv%%=*}"
    local value="${kv#*=}"
    # Use a safe delimiter (~) since values may contain /
    # Escape & and ~ in value
    local escaped_value
    escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\&~]/\\&/g')
    sed -i "s~${key}~${escaped_value}~g" "$dest"
  done
  return 0
}

# planning_render_and_log <template_src> <dest_path> <relative_label> <PLACEHOLDER=val> ...
# Wraps planning_render_template with accurate logging:
#   - Prints "Created <relative_label>" only when the template was actually rendered
#   - Prints nothing extra when skipped (the warn from render_template already covered it)
#   - Lets the script continue (set -e tolerant) regardless of skip vs render
planning_render_and_log() {
  local src="$1"
  local dest="$2"
  local label="$3"
  shift 3

  local rc=0
  planning_render_template "$src" "$dest" "$@" || rc=$?
  case $rc in
    0)
      planning_ok "Created ${label}"
      ;;
    2)
      # Already covered by the warn inside planning_render_template
      ;;
    *)
      planning_err "Failed to render ${label} (rc=$rc)"
      return $rc
      ;;
  esac
}
