#!/usr/bin/env node
// persistent-planning SessionStart hook.
//
// Three jobs:
//   1. The update check, delegated entirely to @theglitchking/claude-plugin-runtime.
//   2. A completion nudge: if any plan under .planning/ has every box checked
//      but is still sitting in the active tree, say so, so the agent archives it
//      instead of rediscovering a finished plan next session.
//   3. A drift warning: if .claude/skills/persistent-planning is a real directory
//      rather than a symlink into this package, it is a frozen v1 copy and every
//      /start-planning is running stale code. See issue #10.

import { runSessionStart } from "@theglitchking/claude-plugin-runtime";
import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { driftedSkills, readSkillVersion } from "../scripts/lib/skill-link.js";

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

function updatePolicy() {
  try {
    const raw = readFileSync(join(projectRoot, ".claude", "persistent-planning.json"), "utf8");
    return JSON.parse(raw)?.updatePolicy || "nudge";
  } catch {
    return "nudge";
  }
}

function driftNudge() {
  try {
    // A user who turned updates off did not ask to be nagged about them either.
    if (updatePolicy() === "off") return "";
    const drifted = driftedSkills(projectRoot, packageRoot, "skills");
    if (!drifted.length) return "";

    let pkgVersion = "unknown";
    try {
      pkgVersion = JSON.parse(readFileSync(join(packageRoot, "package.json"), "utf8")).version;
    } catch { /* keep "unknown" */ }

    const lines = drifted.map((d) => {
      const found = readSkillVersion(projectRoot, d.name) || "unversioned (pre-3.1.0 copy)";
      const why = d.state === "real-dir"
        ? "is a real directory, not a symlink into the installed package"
        : `is a symlink to ${d.target}, which is not this package`;
      return `  - ${d.dest}\n    ${why}\n    running: ${found} | installed: ${pkgVersion}`;
    });

    return [
      "[persistent-planning] STALE SKILL DIRECTORY — commands are running frozen code.",
      ...lines,
      "  Plans generated from a pre-3.1.0 copy silently omit the mandatory validate and",
      "  documentation phases and the whole 'On Completion' archive block.",
      "  Fix:  npx persistent-planning relink",
    ].join("\n");
  } catch {
    // Fail open. A broken drift check must never cost anyone their session start.
    return "";
  }
}

const notice = [planNudge(), driftNudge()].filter(Boolean).join("\n\n");

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
