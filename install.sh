#!/usr/bin/env bash
# install.sh — installs persistent-planning skills/commands into a project
# Usage: bash install.sh [project-dir]
#   project-dir defaults to current working directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# Install npm deps (needed for @theglitchking/claude-plugin-runtime)
cd "$SCRIPT_DIR"
npm install --silent

# Link skills and commands into the project
cd "$PROJECT_DIR"
node "$SCRIPT_DIR/scripts/link-skills.js"
