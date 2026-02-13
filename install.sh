#!/bin/bash
# persistent-planning Plugin Installer
#
# Usage:
#   ./install.sh --scope user
#   ./install.sh --scope project
#   ./install.sh --help

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Defaults
SCOPE="user"
INSTALL_DIR=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --scope) SCOPE="$2"; shift 2 ;;
        --help)
            cat << 'HELP'
persistent-planning Installer

Usage: ./install.sh [OPTIONS]

Options:
  --scope {user|project}    Install scope (default: user)
  --help                    Show this help

Examples:
  ./install.sh --scope user       # Install globally (~/.claude/)
  ./install.sh --scope project    # Install in current project (.claude/)

Scopes:
  user      Install to ~/.claude/ (available in all projects)
  project   Install to .claude/ (current project only)

What gets installed:
  - skills/persistent-planning/SKILL.md     Core skill definition
  - skills/persistent-planning/scripts/     Init script
  - skills/persistent-planning/docs/        Reference docs
  - commands/start-planning.md              Slash command
HELP
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Determine install directory
if [ "$SCOPE" = "user" ]; then
    INSTALL_DIR="$HOME/.claude"
elif [ "$SCOPE" = "project" ]; then
    INSTALL_DIR=".claude"
else
    echo -e "${RED}Invalid scope: $SCOPE${NC}"
    echo "Use --scope user or --scope project"
    exit 1
fi

echo -e "${BLUE}persistent-planning Plugin Installer${NC}"
echo "======================================"
echo ""
echo -e "Scope:    ${GREEN}${SCOPE}${NC} (${INSTALL_DIR})"
echo ""

# Create directory structure
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "${INSTALL_DIR}/skills/persistent-planning/scripts"
mkdir -p "${INSTALL_DIR}/skills/persistent-planning/docs"
mkdir -p "${INSTALL_DIR}/commands"

# Copy skill files
echo -e "${BLUE}Installing skill...${NC}"
cp "${SCRIPT_DIR}/skills/SKILL.md" "${INSTALL_DIR}/skills/persistent-planning/SKILL.md"
echo -e "${GREEN}+${NC} Installed SKILL.md"

# Copy scripts
cp "${SCRIPT_DIR}/scripts/init-planning.sh" "${INSTALL_DIR}/skills/persistent-planning/scripts/init-planning.sh"
chmod +x "${INSTALL_DIR}/skills/persistent-planning/scripts/init-planning.sh"
echo -e "${GREEN}+${NC} Installed init-planning.sh"

# Copy docs
cp "${SCRIPT_DIR}/docs/reference.md" "${INSTALL_DIR}/skills/persistent-planning/docs/reference.md"
cp "${SCRIPT_DIR}/docs/examples.md" "${INSTALL_DIR}/skills/persistent-planning/docs/examples.md"
echo -e "${GREEN}+${NC} Installed reference docs"

# Copy command
cp "${SCRIPT_DIR}/.claude/commands/start-planning.md" "${INSTALL_DIR}/commands/start-planning.md"
echo -e "${GREEN}+${NC} Installed /start-planning command"

# Add to .gitignore if project scope
if [ "$SCOPE" = "project" ]; then
    if [ ! -f ".gitignore" ]; then
        touch .gitignore
    fi
    grep -q "^\.claude/" .gitignore 2>/dev/null || echo ".claude/" >> .gitignore
    echo -e "${GREEN}+${NC} Updated .gitignore"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Installation Complete${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Installed to:${NC} ${INSTALL_DIR}/"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo "  skills/persistent-planning/SKILL.md"
echo "  skills/persistent-planning/scripts/init-planning.sh"
echo "  skills/persistent-planning/docs/reference.md"
echo "  skills/persistent-planning/docs/examples.md"
echo "  commands/start-planning.md"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  In Claude Code, run: /start-planning \"Your task name\""
echo ""
echo -e "${BLUE}Uninstall:${NC}"
echo "  ./uninstall.sh --scope ${SCOPE}"
echo ""
