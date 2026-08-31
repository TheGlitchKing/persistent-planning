#!/usr/bin/env node
// persistent-planning SessionStart hook.
//
// Two jobs:
//   1. The update check, delegated entirely to @theglitchking/claude-plugin-runtime.
//   2. A completion nudge: if any plan under .planning/ has every box checked
//      but is still sitting in the active tree, say so, so the agent archives it
//      instead of rediscovering a finished plan next session.

import { runSessionStart } from "@theglitchking/claude-plugin-runtime";
import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

const projectRoot = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function planNudge() {
  try {
    if (!existsSync(join(projectRoot, ".planning"))) return "";
    const script = join(packageRoot, "scripts", "plan-status.sh");
    if (!existsSync(script)) return "";
    const r = spawnSync("bash", [script, "--nudge"], {
      cwd: projectRoot,
      env: { ...process.env, CLAUDE_PROJECT_DIR: projectRoot },
      encoding: "utf8",
      timeout: 5000,
    });
    return (r.stdout || "").trim();
  } catch {
    return "";
  }
}

const notice = planNudge();

if (!notice) {
  await runSessionStart({
    packageName: "@theglitchking/persistent-planning",
    pluginName: "persistent-planning",
    configFile: "persistent-planning.json",
  });
} else {
  // ponytail: the runtime owns the one SessionStart JSON response and exposes no
  // hook for appending to it, and a second response line on stdout is invalid.
  // So intercept its single write and merge the nudge into that same payload.
  // Fails open — anything unexpected is written through untouched.
  const realWrite = process.stdout.write.bind(process.stdout);
  let merged = false;
  process.stdout.write = (chunk, ...rest) => {
    if (!merged) {
      try {
        const payload = JSON.parse(String(chunk));
        const out = payload?.hookSpecificOutput;
        if (out && out.hookEventName === "SessionStart") {
          out.additionalContext = out.additionalContext
            ? `${out.additionalContext}\n${notice}`
            : notice;
          merged = true;
          return realWrite(JSON.stringify(payload) + "\n", ...rest);
        }
      } catch {
        // Not the response payload — fall through and write it as-is.
      }
    }
    return realWrite(chunk, ...rest);
  };

  await runSessionStart({
    packageName: "@theglitchking/persistent-planning",
    pluginName: "persistent-planning",
    configFile: "persistent-planning.json",
  });

  // The runtime can return without emitting (e.g. it chdir-failed). Say our piece.
  if (!merged) {
    realWrite(
      JSON.stringify({
        hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: notice },
      }) + "\n"
    );
  }
}
