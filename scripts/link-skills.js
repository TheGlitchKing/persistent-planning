#!/usr/bin/env node
// Postinstall — delegates to @theglitchking/claude-plugin-runtime.
// See https://github.com/TheGlitchKing/claude-plugin-runtime/blob/main/docs/PLUGIN_AUTHORING_SCAFFOLD.md

import { runPostinstall } from "@theglitchking/claude-plugin-runtime";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

try {
  runPostinstall({
    packageName: "@theglitchking/persistent-planning",
    pluginName: "persistent-planning",
    configFile: "persistent-planning.json",
    skillsDir: "skills",
    packageRoot,
    hookCommand:
      "node ./node_modules/@theglitchking/persistent-planning/hooks/session-start.js",
  });
} catch (err) {
  console.warn(`[persistent-planning] postinstall failed: ${err?.message || err}`);
}
