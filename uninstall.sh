#!/bin/bash
# persistent-planning Plugin Uninstaller
#
# Usage:
#   ./uninstall.sh --scope user
#   ./uninstall.sh --scope project
#   ./uninstall.sh --help

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCOPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --scope) SCOPE="$2"; shift 2 ;;
        --help)
            cat << 'HELP'
persistent-planning Uninstaller

Usage: ./uninstall.sh [OPTIONS]

Options:
  --scope {user|project}    Uninstall scope (required)
  --help                    Show this help

Examples:
  ./uninstall.sh --scope user       # Remove from ~/.claude/
  ./uninstall.sh --scope project    # Remove from .claude/
HELP
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$SCOPE" ]; then
    echo -e "${RED}Error: --scope is required${NC}"
    echo "Usage: ./uninstall.sh --scope {user|project}"
    exit 1
fi

if [ "$SCOPE" = "user" ]; then
    INSTALL_DIR="$HOME/.claude"
elif [ "$SCOPE" = "project" ]; then
    INSTALL_DIR=".claude"
else
    echo -e "${RED}Invalid scope: $SCOPE${NC}"
    exit 1
fi

echo -e "${BLUE}persistent-planning Plugin Uninstaller${NC}"
echo "========================================"
echo ""

REMOVED=0

# Remove skill directory
SKILL_DIR="${INSTALL_DIR}/skills/persistent-planning"
if [ -d "$SKILL_DIR" ]; then
    rm -rf "$SKILL_DIR"
    echo -e "${GREEN}+${NC} Removed ${SKILL_DIR}/"
    REMOVED=$((REMOVED + 1))
fi

# Remove command
CMD_FILE="${INSTALL_DIR}/commands/start-planning.md"
if [ -f "$CMD_FILE" ]; then
    rm -f "$CMD_FILE"
    echo -e "${GREEN}+${NC} Removed ${CMD_FILE}"
    REMOVED=$((REMOVED + 1))
fi

if [ "$REMOVED" -eq 0 ]; then
    echo -e "${YELLOW}Nothing to remove. persistent-planning not found in ${INSTALL_DIR}/${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo ""
echo "Note: .planning/ directories in your projects are not removed."
echo "To clean those up: rm -rf .planning/"
echo ""
