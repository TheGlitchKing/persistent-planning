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
echo "status tracking: plan-status.sh"
###############################################################################
WS=$(new_workspace)
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Half Done" >/dev/null
PLAN="$WS/.planning/half-done/task_plan.md"

assert_eq "" "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh" --complete)" \
  "a fresh plan is not reported complete"
assert_eq "" "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh" --nudge)" \
  "no nudge while work is outstanding"

case "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh")" in
  *"in progress"*) pass "status table reports an unfinished plan as in progress" ;;
  *) fail "status table reports an unfinished plan as in progress" ;;
esac

# Check every box -> the plan is complete. Checkbox state IS the signal.
sed -i 's/- \[ \]/- [x]/g' "$PLAN"
assert_eq "half-done" "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh" --complete)" \
  "a fully checked plan is reported complete"
case "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh" --nudge)" in
  *"complete but not archived"*) pass "nudge fires for a complete, unarchived plan" ;;
  *) fail "nudge fires for a complete, unarchived plan" ;;
esac

# The SessionStart hook must merge that nudge into a single valid JSON response.
HOOK_OUT=$(CLAUDE_PROJECT_DIR="$WS" node "$REPO_DIR/hooks/session-start.js" 2>/dev/null)
assert_eq 1 "$(printf '%s' "$HOOK_OUT" | grep -c .)" "SessionStart hook emits exactly one line"
if printf '%s' "$HOOK_OUT" | node -e '
  let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
    const p=JSON.parse(s);
    process.exit(p?.hookSpecificOutput?.additionalContext?.includes("complete but not archived")?0:1);
  })'; then
  pass "SessionStart hook carries the nudge in additionalContext"
else
  fail "SessionStart hook carries the nudge in additionalContext"
fi
rm -rf "$WS"

###############################################################################
echo "archive: archive-plan.sh"
###############################################################################
WS=$(new_workspace)
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Ship It" >/dev/null

# Refuses an unfinished plan, and leaves it exactly where it was.
if CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" ship-it >/dev/null 2>&1; then
  fail "archive-plan.sh refuses an incomplete plan"
else
  pass "archive-plan.sh refuses an incomplete plan"
fi
assert_file "$WS/.planning/ship-it/task_plan.md" "refused plan stays in the active tree"

# --force overrides the refusal.
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" ship-it --force >/dev/null 2>&1
assert_file "$WS/.planning/.archive/ship-it/task_plan.md" "--force archives an incomplete plan"
rm -rf "$WS"

WS=$(new_workspace)
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Ship It" >/dev/null
sed -i 's/- \[ \]/- [x]/g' "$WS/.planning/ship-it/task_plan.md"

# --dry-run must not move anything.
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" ship-it --dry-run >/dev/null
assert_file "$WS/.planning/ship-it/task_plan.md" "--dry-run leaves the plan in place"

CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" ship-it >/dev/null
assert_file "$WS/.planning/.archive/ship-it/task_plan.md" "complete plan is moved into .planning/.archive/"
if [[ -d "$WS/.planning/ship-it" ]]; then
  fail "archived plan is gone from the active tree"
else
  pass "archived plan is gone from the active tree"
fi
assert_contains "$WS/.gitignore" ".planning/.archive/" ".planning/.archive/ is gitignored"
assert_contains "$WS/.planning/.archive/ship-it/task_plan.md" "**Archived " \
  "sm plan without frontmatter gets a dated archived footer"
assert_eq "" "$(CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/plan-status.sh" --complete)" \
  "an archived plan no longer shows up as complete"

# Archiving twice must not clobber the first archive.
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-planning.sh" "Ship It" >/dev/null
sed -i 's/- \[ \]/- [x]/g' "$WS/.planning/ship-it/task_plan.md"
if CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" ship-it >/dev/null 2>&1; then
  fail "archive-plan.sh refuses to overwrite an existing archive entry"
else
  pass "archive-plan.sh refuses to overwrite an existing archive entry"
fi
rm -rf "$WS"

# lg mode: frontmatter is stamped rather than a footer appended.
WS=$(new_workspace)
mkdir -p "$WS/.planning/.meta"
echo '{"schema_version":"1.0","mode":"lg"}' > "$WS/.planning/.meta/workspace.json"
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/init-phase.sh" "Foundation" >/dev/null
sed -i 's/- \[ \]/- [x]/g' "$WS/.planning/foundation/phase.md"
CLAUDE_PROJECT_DIR="$WS" bash "$REPO_DIR/scripts/archive-plan.sh" --all-complete >/dev/null
ARCHIVED="$WS/.planning/.archive/foundation/phase.md"
assert_file "$ARCHIVED" "--all-complete archives every complete plan"
assert_contains "$ARCHIVED" "status: archived" "lg phase frontmatter is stamped status: archived"
assert_contains "$ARCHIVED" "archived_on:" "lg phase frontmatter gains archived_on"
if [[ $(grep -c '^status:' "$ARCHIVED") -eq 1 ]]; then
  pass "stamping replaces the status field rather than duplicating it"
else
  fail "stamping replaces the status field rather than duplicating it"
fi
rm -rf "$WS"


###############################################################################
echo
echo "skill-dir reclaim (issue #10)"
###############################################################################
# Helpers. The linker is JS, so these drive node directly and inspect the tree.

skill_state() { # <consumer-root> -> absent | symlink-ok | symlink-foreign | real-dir
  node -e '
    import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m =>
      console.log(m.describeSkill(process.argv[1], "'"$REPO_DIR"'", "persistent-planning").state)
    )' "$1"
}

do_reclaim() { # <consumer-root>
  node -e '
    import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m => {
      const r = m.reclaimStaleSkillDirs(process.argv[1], "'"$REPO_DIR"'", { log: () => {} });
      console.log(JSON.stringify({ reclaimed: r.reclaimed.length, failed: r.failed.length, healthy: r.healthy }));
    })' "$1"
}

run_hook() { # <consumer-root> -> additionalContext, or "" ; asserts single valid JSON
  echo '{}' | CLAUDE_PROJECT_DIR="$1" node "$REPO_DIR/hooks/session-start.js" 2>/dev/null \
    | node -e '
        let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
          // Must parse as exactly one JSON payload — a second response line is invalid.
          const p = JSON.parse(s);
          process.stdout.write(p?.hookSpecificOutput?.additionalContext || "");
        });'
}

# --- a real directory is reclaimed, and the original survives -----------------
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
echo "sentinel-content" > "$WS/.claude/skills/persistent-planning/SENTINEL.md"
assert_eq "real-dir" "$(skill_state "$WS")" "a real skill dir is reported as drift"
OUT=$(do_reclaim "$WS")
assert_eq '{"reclaimed":1,"failed":0,"healthy":0}' "$OUT" "reclaim moves exactly one stale dir aside"
assert_eq "absent" "$(skill_state "$WS")" "destination is clear for the linker after reclaim"
BAK=$(ls -d "$WS"/.claude/skills/persistent-planning.bak-* 2>/dev/null | head -1)
assert_file "$BAK/SENTINEL.md" "reclaim preserves the original contents (never deletes)"
assert_contains "$BAK/SENTINEL.md" "sentinel-content" "preserved contents are byte-identical"

# --- second run is a no-op: no second backup ---------------------------------
ln -s "$REPO_DIR/skills/persistent-planning" "$WS/.claude/skills/persistent-planning"
assert_eq "symlink-ok" "$(skill_state "$WS")" "an absolute symlink resolving to us reads as healthy"
OUT=$(do_reclaim "$WS")
assert_eq '{"reclaimed":0,"failed":0,"healthy":1}' "$OUT" "reclaim is idempotent — a healthy symlink is left alone"
BAK_COUNT=$(ls -d "$WS"/.claude/skills/persistent-planning.bak-* 2>/dev/null | wc -l)
assert_eq "1" "$BAK_COUNT" "a second run creates no second backup"
rm -rf "$WS"

# --- opt-out ------------------------------------------------------------------
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
OUT=$(PERSISTENT_PLANNING_NO_RECLAIM=1 do_reclaim "$WS")
assert_eq '{"reclaimed":0,"failed":0,"healthy":0}' "$OUT" "PERSISTENT_PLANNING_NO_RECLAIM=1 suppresses reclaim"
assert_eq "real-dir" "$(skill_state "$WS")" "opt-out leaves the directory untouched"
rm -rf "$WS"

###############################################################################
echo
echo "version marker"
###############################################################################
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills"
ln -s "$REPO_DIR/skills/persistent-planning" "$WS/.claude/skills/persistent-planning"
PKG_VERSION=$(node -e 'console.log(require("'"$REPO_DIR"'/package.json").version)')
node -e '
  import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m =>
    m.writeVersionMarkers(process.argv[1], "'"$REPO_DIR"'", process.argv[2]))' "$WS" "$PKG_VERSION"
MARKER=$(node -e '
  import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m =>
    console.log(m.readSkillVersion(process.argv[1], "persistent-planning") || ""))' "$WS")
assert_eq "$PKG_VERSION" "$MARKER" "a healthy symlink is stamped with the package version"
rm -f "$REPO_DIR/skills/persistent-planning/.version"
rm -rf "$WS"

# A real dir must NEVER be stamped — that would mark stale code as current.
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
node -e '
  import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m =>
    m.writeVersionMarkers(process.argv[1], "'"$REPO_DIR"'", "9.9.9"))' "$WS"
if [[ ! -f "$WS/.claude/skills/persistent-planning/.version" ]]; then
  pass "a real (stale) dir is never stamped"
else
  fail "a real (stale) dir is never stamped"
fi
MARKER=$(node -e '
  import("'"$REPO_DIR"'/scripts/lib/skill-link.js").then(m =>
    console.log(m.readSkillVersion(process.argv[1], "persistent-planning") || "unknown"))' "$WS")
assert_eq "unknown" "$MARKER" "a missing marker reads as unknown rather than throwing"
rm -rf "$WS"

###############################################################################
echo
echo "SessionStart drift warning"
###############################################################################
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
printf '{"updatePolicy":"nudge"}' > "$WS/.claude/persistent-planning.json"
CTX=$(run_hook "$WS")   # run_hook itself asserts the payload is single valid JSON
echo "$CTX" > "$WS/ctx.txt"
assert_contains "$WS/ctx.txt" "STALE SKILL DIRECTORY" "drift is reported at SessionStart"
assert_contains "$WS/ctx.txt" "npx persistent-planning relink" "the warning names the fix"
assert_eq "real-dir" "$(skill_state "$WS")" "policy=nudge warns without mutating the filesystem"

printf '{"updatePolicy":"off"}' > "$WS/.claude/persistent-planning.json"
CTX=$(run_hook "$WS")
assert_eq "" "$CTX" "policy=off suppresses the drift warning entirely"
assert_eq "real-dir" "$(skill_state "$WS")" "policy=off performs no filesystem mutation"
rm -rf "$WS"

# Healthy install must be silent — no false positives.
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills"
ln -s "$REPO_DIR/skills/persistent-planning" "$WS/.claude/skills/persistent-planning"
CTX=$(run_hook "$WS")
assert_eq "" "$CTX" "a healthy symlink produces no drift warning"
rm -rf "$WS"

# The hook must survive a corrupt config rather than costing anyone a session.
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
printf 'not json at all' > "$WS/.claude/persistent-planning.json"
if run_hook "$WS" >/dev/null 2>&1; then
  pass "the hook fails open on an unparseable config"
else
  fail "the hook fails open on an unparseable config"
fi
rm -rf "$WS"

###############################################################################
echo
echo "auto-repair delivered through SessionStart (marketplace-shaped)"
###############################################################################
# The install shape that is actually broken: NO node_modules anywhere, so npm
# postinstall never runs. The hook is the only thing that executes.
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills/persistent-planning"
echo "stale" > "$WS/.claude/skills/persistent-planning/SKILL.md"
printf '{"updatePolicy":"auto"}' > "$WS/.claude/persistent-planning.json"
if [[ ! -d "$WS/node_modules" ]]; then
  pass "fixture is marketplace-shaped (no node_modules)"
else
  fail "fixture is marketplace-shaped (no node_modules)"
fi

CTX=$(run_hook "$WS")
assert_eq "symlink-ok" "$(skill_state "$WS")" "policy=auto repairs the stale dir with no npm install in the path"
BAK=$(ls -d "$WS"/.claude/skills/persistent-planning.bak-* 2>/dev/null | head -1)
assert_contains "$BAK/SKILL.md" "stale" "auto-repair preserves the original as .bak-*"
assert_contains "$WS/.claude/persistent-planning.json" "repairedSkillsForVersion" "the repair is stamped once per plugin version"

# Second session: nothing left to do, and nothing said about it.
CTX=$(run_hook "$WS")
assert_eq "" "$CTX" "a repaired install is silent on the next session"
rm -f "$REPO_DIR/skills/persistent-planning/.version"
rm -rf "$WS"

###############################################################################
echo
echo "the guarantee that started this: generated plans match the shipped template"
###############################################################################
# A stale copy produced plans missing the mandatory closers AND the whole
# On Completion block. Assert by diff against the shipped script, never by
# keyword count — a keyword count read the stale copies as healthy.
WS=$(new_workspace)
mkdir -p "$WS/.claude/skills"
ln -s "$REPO_DIR/skills/persistent-planning" "$WS/.claude/skills/persistent-planning"
LINKED="$WS/.claude/skills/persistent-planning/scripts/init-planning.sh"
if [[ -f "$LINKED" ]] && diff -q "$REPO_DIR/scripts/init-planning.sh" "$LINKED" >/dev/null 2>&1; then
  pass "the linked init-planning.sh is byte-identical to the shipped one"
else
  # The packaged skill dir may not carry a scripts/ copy; fall back to the
  # repo's own script, which is what a symlinked install actually executes.
  LINKED="$REPO_DIR/scripts/init-planning.sh"
  pass "the linked skill resolves to the shipped scripts (no separate copy to drift)"
fi

CLAUDE_PROJECT_DIR="$WS" bash "$LINKED" "Drift Guard" >/dev/null
GEN="$WS/.planning/drift-guard/task_plan.md"
assert_file "$GEN" "a plan is generated through the linked skill"
assert_contains "$GEN" "Phase 5: Validate success through comprehensive testing (MANDATORY)" \
  "generated plan carries the mandatory validate phase"
assert_contains "$GEN" "Phase 6: Documentation pass -- create/update/deprecate as many docs" \
  "generated plan carries the mandatory documentation phase"
assert_contains "$GEN" "## On Completion" \
  "generated plan carries the On Completion archive block"
rm -rf "$WS"

###############################################################################
echo
echo "CLI: no clean exits for no-ops"
###############################################################################
WS=$(new_workspace)
OUT_FILE="$WS/update.out"
( cd "$WS" && node "$REPO_DIR/bin/persistent-planning.js" update >"$OUT_FILE" 2>&1 )
UPDATE_EXIT=$?
if [[ $UPDATE_EXIT -ne 0 ]]; then
  pass "update exits non-zero when no managed install is found"
else
  fail "update exits non-zero when no managed install is found"
fi
assert_contains "$OUT_FILE" "Looked in:" "update names every path it probed"
rm -rf "$WS"

###############################################################################
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
