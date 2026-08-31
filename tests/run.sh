#!/bin/bash
###############################################################################
# tests/run.sh - Smoke tests for the persistent-planning init scripts.
#
# Plain bash asserts, no framework. Each test runs the real scripts against a
# throwaway CLAUDE_PROJECT_DIR under $TMPDIR and inspects what landed on disk.
#
# Usage:  bash tests/run.sh          (or: npm test)
###############################################################################
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { printf '  ok   %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }

assert_eq() { # <expected> <actual> <label>
  if [[ "$1" == "$2" ]]; then pass "$3"; else
    fail "$3"; printf '       expected: %s\n       actual:   %s\n' "$1" "$2"
  fi
}

assert_contains() { # <haystack-file> <needle> <label>
  if grep -qF -- "$2" "$1"; then pass "$3"; else
    fail "$3"; printf '       %s does not contain: %s\n' "$1" "$2"
  fi
}

assert_file() { # <path> <label>
  if [[ -f "$1" ]]; then pass "$2"; else fail "$2"; printf '       missing: %s\n' "$1"; fi
}

# Prints the unchecked-checkbox lines of a markdown section, e.g.
#   checkbox_lines <file> "## Phases"
checkbox_lines() {
  awk -v section="$2" '
    $0 == section { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside && /^- \[[ x]\] / { print }
  ' "$1"
}

new_workspace() { # -> prints a fresh temp project dir
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/pp-test-XXXXXX")
  echo "$d"
}

###############################################################################
echo "sm mode: init-planning.sh"
###############################################################################
WS=$(new_workspace)
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Refactor Auth System" >/dev/null

PLAN="$WS/.planning/refactor-auth-system/task_plan.md"
assert_file "$PLAN" "task_plan.md created at the slugified path"
assert_file "$WS/.planning/refactor-auth-system/notes.md" "notes.md created"

if [[ -f "$PLAN" ]]; then
  mapfile -t PHASES < <(checkbox_lines "$PLAN" "## Phases")
  assert_eq 6 "${#PHASES[@]}" "sm plan seeds 6 phases"
  LAST=${PHASES[${#PHASES[@]}-1]}
  PENULT=${PHASES[${#PHASES[@]}-2]}
  case "$PENULT" in
    *"Validate success through comprehensive testing"*) pass "validation phase is second-to-last" ;;
    *) fail "validation phase is second-to-last"; printf '       got: %s\n' "$PENULT" ;;
  esac
  case "$LAST" in
    *"Documentation pass"*) pass "documentation phase is last" ;;
    *) fail "documentation phase is last"; printf '       got: %s\n' "$LAST" ;;
  esac
  assert_contains "$PLAN" "MUST stay the last two phases" "sm plan states the ordering rule"
  assert_contains "$PLAN" "Refactor Auth System" "task name substituted into the plan"
fi

# Idempotence: a second run must not clobber edits.
echo "EDITED BY USER" >> "$PLAN"
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Refactor Auth System" >/dev/null
assert_contains "$PLAN" "EDITED BY USER" "re-running init-planning.sh does not overwrite an existing plan"
rm -rf "$WS"

###############################################################################
echo "lg mode: init-phase.sh / init-task.sh / init-atom.sh"
###############################################################################
WS=$(new_workspace)
mkdir -p "$WS/.planning/.meta"
echo '{"schema_version":"1.0","mode":"lg"}' > "$WS/.planning/.meta/workspace.json"

assert_eq "lg" "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/detect-mode.sh")" \
  "detect-mode.sh honors the workspace.json override"

CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-phase.sh" "Foundation" >/dev/null
PHASE="$WS/.planning/foundation/phase.md"
assert_file "$PHASE" "phase.md created"
assert_file "$WS/.planning/foundation/notes.md" "phase notes.md created"

if [[ -f "$PHASE" ]]; then
  mapfile -t TASKS < <(checkbox_lines "$PHASE" "## Tasks")
  LAST=${TASKS[${#TASKS[@]}-1]}
  PENULT=${TASKS[${#TASKS[@]}-2]}
  case "$PENULT" in
    *"Validate success through comprehensive testing"*) pass "phase validation task is second-to-last" ;;
    *) fail "phase validation task is second-to-last"; printf '       got: %s\n' "$PENULT" ;;
  esac
  case "$LAST" in
    *"Documentation pass"*) pass "phase documentation task is last" ;;
    *) fail "phase documentation task is last"; printf '       got: %s\n' "$LAST" ;;
  esac
  assert_contains "$PHASE" "MUST remain the last two tasks" "phase states the ordering rule"
  assert_contains "$PHASE" "tier: plan" "phase carries HEWTD plan-tier frontmatter"
  if grep -q "PLACEHOLDER" "$PHASE"; then
    fail "no unsubstituted placeholders remain in phase.md"
    grep -n "PLACEHOLDER" "$PHASE" | sed 's/^/       /'
  else
    pass "no unsubstituted placeholders remain in phase.md"
  fi
fi

CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-task.sh" "Schema extension" --parent foundation >/dev/null
assert_file "$WS/.planning/foundation/schema-extension/task.md" "task.md created under the phase"
assert_contains "$WS/.planning/foundation/schema-extension/task.md" "parent: foundation" \
  "task frontmatter points at its parent phase"

CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-atom.sh" "First atom" --parent schema-extension >/dev/null
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-atom.sh" "Second atom" --parent schema-extension >/dev/null
ATOMS="$WS/.planning/foundation/schema-extension/atoms"
assert_contains "$ATOMS/first-atom.md" "sequence: 1" "first atom gets sequence 1"
assert_contains "$ATOMS/second-atom.md" "sequence: 2" "second atom auto-increments to sequence 2"
rm -rf "$WS"

###############################################################################
echo "mode guards"
###############################################################################
WS=$(new_workspace)
mkdir -p "$WS/.planning/.meta"
echo '{"schema_version":"1.0","mode":"sm"}' > "$WS/.planning/.meta/workspace.json"
if CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-phase.sh" "Nope" >/dev/null 2>&1; then
  fail "init-phase.sh refuses to run in sm mode"
else
  pass "init-phase.sh refuses to run in sm mode"
fi
rm -rf "$WS"

###############################################################################
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
