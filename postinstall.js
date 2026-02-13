#!/usr/bin/env node

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

console.log(`
${colors.cyan}persistent-planning installed successfully!${colors.reset}

${colors.green}+${colors.reset} Package installed: ${colors.blue}@theglitchking/persistent-planning${colors.reset}

${colors.yellow}Next Steps:${colors.reset}

  1. Run the installer to set up the plugin:
     ${colors.cyan}persistent-planning install --scope user${colors.reset}

     ${colors.blue}Scopes:${colors.reset}
       user    - Install globally (~/.claude/) for all projects
       project - Install locally (./.claude/) for this project only

  2. Check installation status:
     ${colors.cyan}persistent-planning status${colors.reset}

  3. After installation, use this Claude Code command:
     ${colors.cyan}/start-planning "Your task name"${colors.reset}

${colors.yellow}Documentation:${colors.reset}
  ${colors.blue}https://github.com/TheGlitchKing/persistent-planning${colors.reset}

`);
