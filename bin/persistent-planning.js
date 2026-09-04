#!/usr/bin/env node

import { program } from "commander";
import { registerUpdateCommands } from "@theglitchking/claude-plugin-runtime";
import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const require_ = createRequire(import.meta.url);
const { version } = require_("../package.json");

const PKG = "@theglitchking/persistent-planning";

// Where the linker can live, most specific first. The third probe matters: in a
// marketplace-only install there is no node_modules and cwd is the consumer repo,
// so the first two both miss and relink -- the one command that repairs a stale
// skill dir -- could not run at all in exactly the shape that needs it.
function linkerCandidates(cwd) {
  const out = [
    join(cwd, "node_modules", "@theglitchking", "persistent-planning", "scripts", "link-skills.js"),
    resolve(process.cwd(), "scripts", "link-skills.js"),
  ];
  if (process.env.CLAUDE_PLUGIN_ROOT) {
    out.push(join(process.env.CLAUDE_PLUGIN_ROOT, "scripts", "link-skills.js"));
  }
  // The package this CLI is itself running from — correct for `npx <pkg> relink`.
  out.push(resolve(dirname(fileURLToPath(import.meta.url)), "..", "scripts", "link-skills.js"));
  return out;
}

function runRelink(cwd) {
  const candidates = linkerCandidates(cwd);
  const script = candidates.find((p) => existsSync(p));
  if (!script) {
    // ponytail: never exit 0 after doing nothing — a clean success for a no-op is
    // how the stale-skill-dir bug stayed invisible for five months (issue #10).
    console.error("relink failed: link-skills.js not found. Looked in:");
    for (const p of candidates) console.error(`  ${p}`);
    console.error("\nIs @theglitchking/persistent-planning installed, or CLAUDE_PLUGIN_ROOT set?");
    process.exitCode = 1;
    return;
  }
  const r = spawnSync(process.execPath, [script], {
    cwd,
    env: { ...process.env, INIT_CWD: cwd },
    stdio: "inherit",
  });
  if (r.status !== 0) process.exitCode = r.status ?? 1;
}

program
  .name("persistent-planning")
  .description("Persistent markdown-based planning for Claude Code.")
  .version(version);

// The runtime's `update` resolves the installed version, finds none in a
// marketplace-only install, prints "Current: (not installed) / Now: (not installed)"
// and exits 0 -- a clean success for a no-op. Fail before it gets that far, and say
// where we looked. Same defect as runRelink's missing third probe (issue #10, fix #4).
// Deliberately NOT including the package this CLI runs from: under
// `npx --no @theglitchking/persistent-planning update` that copy always exists, which
// is what let the original bug report see a clean exit 0 for a no-op. Only a *managed*
// install -- a project dependency or a marketplace plugin root -- is updatable.
function installCandidates(cwd) {
  const out = [join(cwd, "node_modules", "@theglitchking", "persistent-planning", "package.json")];
  if (process.env.CLAUDE_PLUGIN_ROOT) out.push(join(process.env.CLAUDE_PLUGIN_ROOT, "package.json"));
  return out;
}

program.hook("preAction", (_thisCmd, actionCmd) => {
  if (actionCmd.name() !== "update") return;
  const candidates = installCandidates(process.cwd());
  if (candidates.some((p) => existsSync(p))) return;
  console.error("update failed: no managed install of @theglitchking/persistent-planning found.");
  console.error("Looked in:");
  for (const p of candidates) console.error(`  ${p}`);
  console.error("\nInstall it with `npm i -D @theglitchking/persistent-planning`,");
  console.error("or update the marketplace plugin with `/plugin` inside Claude Code.");
  process.exit(1);
});

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
