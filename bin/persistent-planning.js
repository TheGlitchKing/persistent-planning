#!/usr/bin/env node

import { program } from "commander";
import { registerUpdateCommands } from "@theglitchking/claude-plugin-runtime";
import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join, resolve } from "node:path";

const require_ = createRequire(import.meta.url);
const { version } = require_("../package.json");

const PKG = "@theglitchking/persistent-planning";

function runRelink(cwd) {
  const linker = join(cwd, "node_modules", "@theglitchking", "persistent-planning", "scripts", "link-skills.js");
  const script = existsSync(linker) ? linker : resolve(process.cwd(), "scripts", "link-skills.js");
  if (!existsSync(script)) {
    console.error("link-skills.js not found — is the package installed?");
    return;
  }
  spawnSync(process.execPath, [script], {
    cwd,
    env: { ...process.env, INIT_CWD: cwd },
    stdio: "inherit",
  });
}

program
  .name("persistent-planning")
  .description("Persistent markdown-based planning for Claude Code.")
  .version(version);

registerUpdateCommands(program, {
  packageName: PKG,
  pluginName: "persistent-planning",
  configFile: "persistent-planning.json",
  onAfterUpdate: (cwd) => runRelink(cwd),
});

// Deprecated subcommands from v1. Accept them so existing automation
// doesn't silently break — print a migration pointer and exit 0.
function deprecationNotice(name) {
  console.error(`\n⚠️  'persistent-planning ${name}' was removed in v2.0.0.\n`);
  console.error(`The plugin now installs via the Claude Code plugin marketplace:`);
  console.error(`  /plugin marketplace add TheGlitchKing/persistent-planning`);
  console.error(`  /plugin install persistent-planning@persistent-planning-marketplace\n`);
  console.error(`Or, at the project level, via npm:`);
  console.error(`  npm install --save-dev @theglitchking/persistent-planning\n`);
  console.error(`See the v2.0.0 CHANGELOG for migration details:`);
  console.error(`  https://github.com/TheGlitchKing/persistent-planning/blob/main/CHANGELOG.md\n`);
}

program
  .command("install")
  .description("[removed in v2.0.0] use the Claude Code plugin marketplace or npm")
  .option("--scope <scope>")
  .action(() => { deprecationNotice("install"); process.exit(0); });

program
  .command("uninstall")
  .description("[removed in v2.0.0] use /plugin uninstall or npm uninstall")
  .option("--scope <scope>")
  .action(() => { deprecationNotice("uninstall"); process.exit(0); });

program.parse();
