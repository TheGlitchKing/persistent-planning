#!/usr/bin/env node
// persistent-planning SessionStart hook.
// Delegates entirely to @theglitchking/claude-plugin-runtime — this plugin
// has no mcp.json wiring or project-side reconcile, so only the update
// check runs.

import { runSessionStart } from "@theglitchking/claude-plugin-runtime";

await runSessionStart({
  packageName: "@theglitchking/persistent-planning",
  pluginName: "persistent-planning",
  configFile: "persistent-planning.json",
});
