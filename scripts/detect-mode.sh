#!/bin/bash
###############################################################################
# detect-mode.sh - Sm/lg mode detection for persistent-planning v3.0
#
# Usage:
#   bash scripts/detect-mode.sh [--explain]
#
# Output:
#   "sm" or "lg" on stdout. With --explain, also prints a one-line decision
#   banner to stderr explaining which signals fired.
#
# Heuristic:
#   - If $CLAUDE_PROJECT_DIR/.planning/.meta/workspace.json exists with a
#     "mode" field, that wins (override is sticky).
#   - Otherwise count distinct git authors over the last 90 days. Two or
#     more distinct emails → "lg". Otherwise "sm".
#   - If the repo isn't a git repo or git fails for any reason, default
#     to "sm" (the safer/less-surprising option for solo flows).
#
# Why this design:
#   - Solo devs get the historical sm experience with zero ceremony.
#   - Multi-contributor projects get the layered model surface immediately.
#   - The decision banner avoids "magic" — the user sees what fired.
#   - The workspace.json override means a single --mode flag sticks for
#     all subsequent runs (no flag needed every time).
###############################################################################
set -e

EXPLAIN=0
if [[ "${1:-}" == "--explain" ]]; then
  EXPLAIN=1
fi

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
WORKSPACE_JSON="${PROJECT_ROOT}/.planning/.meta/workspace.json"

# 1. Override wins if workspace.json exists
if [[ -f "$WORKSPACE_JSON" ]]; then
  # Naive jq-free read: grep the mode line. workspace.json is small/structured.
  MODE_FROM_JSON=$(grep -oE '"mode"[[:space:]]*:[[:space:]]*"(sm|lg)"' "$WORKSPACE_JSON" | sed -E 's/.*"(sm|lg)".*/\1/')
  if [[ "$MODE_FROM_JSON" == "sm" || "$MODE_FROM_JSON" == "lg" ]]; then
    echo "$MODE_FROM_JSON"
    if [[ $EXPLAIN -eq 1 ]]; then
      echo "[mode] $MODE_FROM_JSON (from .planning/.meta/workspace.json)" >&2
    fi
    exit 0
  fi
fi

# 2. Auto-detect via git author count over 90 days
DETECTED="sm"
CONTRIB=0
if command -v git >/dev/null 2>&1 && git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  CONTRIB=$(git -C "$PROJECT_ROOT" log --since="90 days ago" --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [[ "$CONTRIB" -ge 2 ]]; then
    DETECTED="lg"
  fi
fi

echo "$DETECTED"
if [[ $EXPLAIN -eq 1 ]]; then
  if [[ "$DETECTED" == "lg" ]]; then
    echo "[mode] lg (auto-detected: $CONTRIB distinct git authors over the last 90 days; threshold ≥ 2)" >&2
  else
    echo "[mode] sm (auto-detected: $CONTRIB distinct git authors over the last 90 days; threshold for lg is ≥ 2)" >&2
  fi
fi
