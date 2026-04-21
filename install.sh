#!/usr/bin/env bash
# install.sh — installs persistent-planning skills/commands into a project
# Usage: cd <project-dir> && bash /path/to/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install npm deps (needed for @theglitchking/claude-plugin-runtime)
(cd "$SCRIPT_DIR" && npm install --silent 2>/dev/null)

# Link skills and commands into the caller's working directory (project root)
node "$SCRIPT_DIR/scripts/link-skills.js"
