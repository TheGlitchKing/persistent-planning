#!/bin/bash

###############################################################################
# init-planning.sh - Persistent Planning Directory Setup
#
# Part of the persistent-planning plugin by TheGlitchKing
# https://github.com/TheGlitchKing/persistent-planning
#
# Usage:
#   bash scripts/init-planning.sh [task-name]
#   bash scripts/init-planning.sh "Refactor database layer"
#
# What it does:
#   1. Creates .planning/[task-slug]/ directory (separate per task)
#   2. Creates task_plan.md with templates
#   3. Creates notes.md with templates
#   4. Adds .planning/ to .gitignore (optional)
#   5. Confirms creation and provides next steps
#
# Multiple tasks example:
#   /start-planning "Refactor auth"      -> .planning/refactor-auth/
#   /start-planning "Debug memory leak"  -> .planning/debug-memory-leak/
#   Both plans coexist without conflicts!
###############################################################################

set -e

# Validate that task name was provided
if [ -z "$1" ]; then
    echo "Error: Task name required"
    echo ""
    echo "Usage: bash scripts/init-planning.sh \"Your Task Name\""
    echo ""
    echo "Examples:"
    echo "  bash scripts/init-planning.sh \"Refactor authentication\""
    echo "  bash scripts/init-planning.sh \"Debug API performance\""
    exit 1
fi

TASK_NAME="$1"

# Convert task name to slug
# "Refactor Authentication" -> "refactor-authentication"
task_name_to_slug() {
    local name="$1"
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    name=$(echo "$name" | sed 's/[[:space:]_]\+/-/g')
    name=$(echo "$name" | sed 's/[^a-z0-9-]//g')
    name=$(echo "$name" | sed 's/^-\+\|-\+$//g')
    name=$(echo "$name" | sed 's/-\+/-/g')
    echo "$name"
}

TASK_SLUG=$(task_name_to_slug "$TASK_NAME")

# Validate slug
if [ -z "$TASK_SLUG" ]; then
    echo "Error: Task name must contain at least one alphanumeric character"
    echo "Provided: $TASK_NAME"
    exit 1
fi

# Determine project root
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLANNING_DIR="${PROJECT_ROOT}/.planning"
TASK_DIR="${PLANNING_DIR}/${TASK_SLUG}"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}Initializing Planning Structure${NC}"
echo ""

# Step 1: Create .planning directory
if [ ! -d "$PLANNING_DIR" ]; then
    mkdir -p "$PLANNING_DIR"
    echo -e "${GREEN}+${NC} Created .planning/ directory"
else
    echo -e "${YELLOW}*${NC} .planning/ directory exists"
fi

# Step 2: Create task directory
if [ ! -d "$TASK_DIR" ]; then
    mkdir -p "$TASK_DIR"
    echo -e "${GREEN}+${NC} Created task directory: ${CYAN}.planning/${TASK_SLUG}/${NC}"
else
    echo -e "${YELLOW}*${NC} Task directory already exists: ${CYAN}.planning/${TASK_SLUG}/${NC}"
fi

# Step 3: Create task_plan.md
TASK_PLAN_FILE="${TASK_DIR}/task_plan.md"
if [ ! -f "$TASK_PLAN_FILE" ]; then
    cat > "$TASK_PLAN_FILE" << 'EOF'
# Task Plan: TASK_NAME_PLACEHOLDER

## Goal
[One sentence describing the end state]

## Phases
- [ ] Phase 1: Plan and setup
- [ ] Phase 2: Research/gather information
- [ ] Phase 3: Execute/build
- [ ] Phase 4: Review and deliver

## Key Questions
1. [Question to answer]
2. [Question to answer]

## Decisions Made
- [Decision]: [Rationale]

## Errors Encountered
- [Error]: [Resolution]

## Status
**Currently in Phase 1** - Setting up planning structure

---

## Notes
- This file persists across sessions
- Update status after each phase
- Mark completed phases with [x]
- Save research to notes.md instead of stuffing context
EOF

    sed -i "s/TASK_NAME_PLACEHOLDER/${TASK_NAME}/g" "$TASK_PLAN_FILE"
    echo -e "${GREEN}+${NC} Created task_plan.md"
else
    echo -e "${YELLOW}*${NC} task_plan.md already exists (not overwritten)"
fi

# Step 4: Create notes.md
NOTES_FILE="${TASK_DIR}/notes.md"
if [ ! -f "$NOTES_FILE" ]; then
    cat > "$NOTES_FILE" << 'EOF'
# Notes: TASK_NAME_PLACEHOLDER

## Key Findings
- [Finding 1]
- [Finding 2]

## Research Sources
- [Source 1]: [URL or reference]
- [Source 2]: [URL or reference]

## Synthesized Findings

### [Category/Topic 1]
- [Finding]
- [Finding]

### [Category/Topic 2]
- [Finding]
- [Finding]

## Decisions Made
- [Decision]: [Rationale]
- [Decision]: [Rationale]

## Errors & Solutions
- [Error]: [Resolution]
- [Error]: [Resolution]

---

## Append-Only Log
Store findings here as you discover them. This builds a searchable history.

### [Date/Time]
- [What I found/did]
EOF

    sed -i "s/TASK_NAME_PLACEHOLDER/${TASK_NAME}/g" "$NOTES_FILE"
    echo -e "${GREEN}+${NC} Created notes.md"
else
    echo -e "${YELLOW}*${NC} notes.md already exists (not overwritten)"
fi

# Step 5: Update .gitignore
if [ -f "${PROJECT_ROOT}/.gitignore" ]; then
    if ! grep -q "^\.planning/" "${PROJECT_ROOT}/.gitignore"; then
        echo ".planning/" >> "${PROJECT_ROOT}/.gitignore"
        echo -e "${GREEN}+${NC} Added .planning/ to .gitignore"
    else
        echo -e "${YELLOW}*${NC} .planning/ already in .gitignore"
    fi
else
    echo -e "${YELLOW}*${NC} No .gitignore found (not added)"
fi

# Step 6: List other active tasks
OTHER_TASKS=$(find "$PLANNING_DIR" -maxdepth 1 -type d -not -name ".planning" -not -path "$TASK_DIR" 2>/dev/null | wc -l)
if [ "$OTHER_TASKS" -gt 0 ]; then
    echo ""
    echo -e "${CYAN}Other active tasks:${NC}"
    find "$PLANNING_DIR" -maxdepth 1 -type d -not -name ".planning" -not -path "$TASK_DIR" | sort | while read dir; do
        task_slug=$(basename "$dir")
        echo "   .planning/${task_slug}/"
    done
fi

# Step 7: Confirmation
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Task Plan Ready${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

echo -e "${BLUE}Task:${NC} ${TASK_NAME}"
echo -e "${BLUE}Location:${NC} .planning/${TASK_SLUG}/"
echo ""

echo -e "${BLUE}Files:${NC}"
echo "  task_plan.md   (your task plan)"
echo "  notes.md       (research & findings)"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Edit .planning/${TASK_SLUG}/task_plan.md to define your phases"
echo "  2. As you work, update the Status section"
echo "  3. Save findings to .planning/${TASK_SLUG}/notes.md"
echo "  4. Re-read task_plan.md before major decisions"
echo ""

echo -e "${BLUE}Cleanup:${NC}"
echo "  rm -rf .planning/${TASK_SLUG}/  # Remove this task"
echo "  rm -rf .planning/               # Remove all tasks"
echo ""
