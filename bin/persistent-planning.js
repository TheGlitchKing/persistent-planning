#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const PLUGIN_ROOT = path.join(__dirname, '..');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

function showHelp() {
  console.log(`
${colors.blue}persistent-planning CLI${colors.reset}

${colors.green}Usage:${colors.reset}
  persistent-planning install [--scope user|project]
  persistent-planning uninstall [--scope user|project]
  persistent-planning status
  persistent-planning help

${colors.green}Commands:${colors.reset}
  install     Install persistent-planning skill and /start-planning command
  uninstall   Remove persistent-planning from Claude Code
  status      Show installation status
  help        Show this help message

${colors.green}Install Options:${colors.reset}
  --scope {user|project}    Install scope (default: user)
                            user     - Install globally (~/.claude/)
                            project  - Install in current project (.claude/)

${colors.green}Examples:${colors.reset}
  persistent-planning install --scope user
  persistent-planning install --scope project
  persistent-planning uninstall --scope user
  persistent-planning status

${colors.green}After Installation:${colors.reset}
  Run this command in Claude Code:
    /start-planning "Your task name"
  `);
}

function copyRecursive(src, dest) {
  const stats = fs.statSync(src);
  if (stats.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(file => {
      copyRecursive(path.join(src, file), path.join(dest, file));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

function getInstallDir(scope) {
  return scope === 'user'
    ? path.join(process.env.HOME || process.env.USERPROFILE, '.claude')
    : '.claude';
}

function checkInstallation(scope) {
  const installDir = getInstallDir(scope);
  const skillPath = path.join(installDir, 'skills', 'persistent-planning', 'SKILL.md');
  const commandPath = path.join(installDir, 'commands', 'start-planning.md');
  return {
    skill: fs.existsSync(skillPath),
    command: fs.existsSync(commandPath)
  };
}

function showStatus() {
  console.log(`\n${colors.blue}persistent-planning Installation Status${colors.reset}\n`);

  const userInstall = checkInstallation('user');
  const projectInstall = checkInstallation('project');

  console.log(`User Scope (~/.claude/):`);
  console.log(`  Skill:    ${userInstall.skill ? colors.green + 'Installed' : colors.yellow + 'Not installed'}${colors.reset}`);
  console.log(`  Command:  ${userInstall.command ? colors.green + 'Installed' : colors.yellow + 'Not installed'}${colors.reset}`);

  console.log(`\nProject Scope (./.claude/):`);
  console.log(`  Skill:    ${projectInstall.skill ? colors.green + 'Installed' : colors.yellow + 'Not installed'}${colors.reset}`);
  console.log(`  Command:  ${projectInstall.command ? colors.green + 'Installed' : colors.yellow + 'Not installed'}${colors.reset}`);

  if (!userInstall.skill && !projectInstall.skill) {
    console.log(`\n${colors.yellow}Run: persistent-planning install${colors.reset}`);
  }
  console.log();
}

function runInstall(args) {
  const scope = args.includes('--scope') ? args[args.indexOf('--scope') + 1] : 'user';
  const installDir = getInstallDir(scope);

  console.log(`${colors.blue}Installing persistent-planning...${colors.reset}`);
  console.log(`  Scope: ${scope} (${installDir})\n`);

  try {
    // Create directories
    const skillDir = path.join(installDir, 'skills', 'persistent-planning');
    const scriptsDir = path.join(skillDir, 'scripts');
    const docsDir = path.join(skillDir, 'docs');
    const commandsDir = path.join(installDir, 'commands');

    fs.mkdirSync(scriptsDir, { recursive: true });
    fs.mkdirSync(docsDir, { recursive: true });
    fs.mkdirSync(commandsDir, { recursive: true });

    // Copy skill
    fs.copyFileSync(
      path.join(PLUGIN_ROOT, 'skills', 'SKILL.md'),
      path.join(skillDir, 'SKILL.md')
    );
    console.log(`${colors.green}+${colors.reset} Installed SKILL.md`);

    // Copy init script
    const initScript = path.join(scriptsDir, 'init-planning.sh');
    fs.copyFileSync(
      path.join(PLUGIN_ROOT, 'scripts', 'init-planning.sh'),
      initScript
    );
    fs.chmodSync(initScript, 0o755);
    console.log(`${colors.green}+${colors.reset} Installed init-planning.sh`);

    // Copy docs
    fs.copyFileSync(
      path.join(PLUGIN_ROOT, 'docs', 'reference.md'),
      path.join(docsDir, 'reference.md')
    );
    fs.copyFileSync(
      path.join(PLUGIN_ROOT, 'docs', 'examples.md'),
      path.join(docsDir, 'examples.md')
    );
    console.log(`${colors.green}+${colors.reset} Installed reference docs`);

    // Copy command
    fs.copyFileSync(
      path.join(PLUGIN_ROOT, '.claude', 'commands', 'start-planning.md'),
      path.join(commandsDir, 'start-planning.md')
    );
    console.log(`${colors.green}+${colors.reset} Installed /start-planning command`);

    // Update .gitignore if project scope
    if (scope === 'project') {
      const gitignorePath = '.gitignore';
      if (fs.existsSync(gitignorePath)) {
        const content = fs.readFileSync(gitignorePath, 'utf8');
        if (!content.includes('.claude/')) {
          fs.appendFileSync(gitignorePath, '\n.claude/\n');
          console.log(`${colors.green}+${colors.reset} Updated .gitignore`);
        }
      } else {
        fs.writeFileSync(gitignorePath, '.claude/\n');
        console.log(`${colors.green}+${colors.reset} Created .gitignore`);
      }
    }

    console.log(`\n${colors.green}Installation Complete!${colors.reset}\n`);
    console.log(`${colors.yellow}Usage:${colors.reset}`);
    console.log(`  In Claude Code, run: ${colors.cyan}/start-planning "Your task name"${colors.reset}\n`);
    console.log(`${colors.yellow}Uninstall:${colors.reset}`);
    console.log(`  ${colors.cyan}persistent-planning uninstall --scope ${scope}${colors.reset}\n`);

  } catch (error) {
    console.error(`${colors.red}Installation failed: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

function runUninstall(args) {
  const scope = args.includes('--scope') ? args[args.indexOf('--scope') + 1] : 'user';
  const installDir = getInstallDir(scope);

  console.log(`${colors.blue}Uninstalling persistent-planning...${colors.reset}`);
  console.log(`  Scope: ${scope} (${installDir})\n`);

  let removed = 0;

  try {
    const skillDir = path.join(installDir, 'skills', 'persistent-planning');
    if (fs.existsSync(skillDir)) {
      fs.rmSync(skillDir, { recursive: true, force: true });
      console.log(`${colors.green}+${colors.reset} Removed skill`);
      removed++;
    }

    const commandFile = path.join(installDir, 'commands', 'start-planning.md');
    if (fs.existsSync(commandFile)) {
      fs.unlinkSync(commandFile);
      console.log(`${colors.green}+${colors.reset} Removed /start-planning command`);
      removed++;
    }

    if (removed === 0) {
      console.log(`${colors.yellow}Nothing to remove. persistent-planning not found in ${installDir}/${colors.reset}`);
    } else {
      console.log(`\n${colors.green}Uninstall complete.${colors.reset}`);
      console.log(`\nNote: .planning/ directories in your projects are not removed.`);
      console.log(`To clean those up: rm -rf .planning/\n`);
    }

  } catch (error) {
    console.error(`${colors.red}Uninstallation failed: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

// Main
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'install':
    runInstall(args.slice(1));
    break;
  case 'uninstall':
    runUninstall(args.slice(1));
    break;
  case 'status':
    showStatus();
    break;
  case 'help':
  case '--help':
  case '-h':
  case undefined:
    showHelp();
    break;
  default:
    console.error(`${colors.red}Unknown command: ${command}${colors.reset}`);
    console.log(`Run 'persistent-planning help' for usage information`);
    process.exit(1);
}
