#!/usr/bin/env node
// persistent-planning SessionStart hook.
//
// Three jobs:
//   1. The update check, delegated entirely to @theglitchking/claude-plugin-runtime.
//      That import is dynamic on purpose: the runtime resolves out of the shared
//      ~/.claude/plugins/npm-cache/, which is not guaranteed to be populated. A
//      static import made an unresolvable runtime fatal for the WHOLE hook, taking
//      jobs 2-4 down with it — including the repair that is the only way a fix
//      reaches an already-broken install. Jobs 2-4 need no runtime at all.
//   2. A completion nudge: if any plan under .planning/ has every box checked
//      but is still sitting in the active tree, say so, so the agent archives it
//      instead of rediscovering a finished plan next session.
//   3. A drift warning: if .claude/skills/persistent-planning is a real directory
//      rather than a symlink into this package, it is a frozen v1 copy and every
//      /start-planning is running stale code. See issue #10.
//   4. Under updatePolicy: auto, actually repair that drift. This hook is the only
//      code that runs every session in a marketplace install -- that shape has no
//      node_modules in the plugin cache and never runs npm postinstall -- so it is
//      the only delivery path a fix can reach existing broken installs through.

import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { driftedSkills, readSkillVersion } from "../scripts/lib/skill-link.js";

// Resolve the runtime lazily. Returns null when it cannot be loaded, which costs
// only the update check — never the drift warning or the repair.
async function loadRunSessionStart() {
  try {
    const mod = await import("@theglitchking/claude-plugin-runtime");
    return typeof mod?.runSessionStart === "function" ? mod.runSessionStart : null;
  } catch {
    return null;
  }
}

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

function packageVersion() {
  try {
    return JSON.parse(readFileSync(join(packageRoot, "package.json"), "utf8")).version || null;
  } catch {
    return null;
  }
}

const CONFIG = join(projectRoot, ".claude", "persistent-planning.json");

function readConfig() {
  try { return JSON.parse(readFileSync(CONFIG, "utf8")) || {}; } catch { return {}; }
}

/**
 * Repair a drifted skill dir, at most once per plugin version.
 *
 * Runs the package's own linker, which reclaims the stale dir, symlinks, and stamps
 * the version marker. Spawned rather than imported so a failure is contained in a
 * child process and cannot take the hook down with it.
 *
 * Returns a one-line summary to fold into the session notice, or "".
 */
function autoRepair() {
  try {
    const policy = updatePolicy();
    if (policy !== "auto") return "";                       // nudge/off: warn only

    // Fast path first — two lstats, and the overwhelmingly common answer is "nothing
    // to do". Never pay for the migration on a healthy install.
    if (!driftedSkills(projectRoot, packageRoot, "skills").length) return "";

    const version = packageVersion();
    const cfg = readConfig();
    if (version && cfg.repairedSkillsForVersion === version) return "";  // once per version

    const linker = join(packageRoot, "scripts", "link-skills.js");
    if (!existsSync(linker)) return "";

    const r = spawnSync(process.execPath, [linker], {
      cwd: projectRoot,
      env: { ...process.env, INIT_CWD: projectRoot },
      encoding: "utf8",
      timeout: 10000,
    });

    // Stamp only on success. Stamping a failure turns a transient problem — an
    // unresolvable runtime, a locked file — into a permanent one: the version is
    // marked done and the repair never runs again, even once the cause is gone.
    // A failure costs one spawn per session while genuinely drifted, and the drift
    // warning fires alongside it naming the manual fix, so nobody is stuck silently.
    const remaining = driftedSkills(projectRoot, packageRoot, "skills");
    if (remaining.length || r.status !== 0) return "";      // let driftNudge() report it

    try {
      writeFileSync(CONFIG, JSON.stringify({ ...cfg, repairedSkillsForVersion: version }, null, 2) + "\n", "utf8");
    } catch { /* config unwritable — worst case the repair is attempted again */ }

    return "[persistent-planning] repaired a stale skill directory (originals kept as .bak-*).";
  } catch {
    return "";
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

// Repair before reporting, so a successful auto-repair does not also warn.
const repaired = autoRepair();
const notice = [planNudge(), repaired, driftNudge()].filter(Boolean).join("\n\n");

const runSessionStart = await loadRunSessionStart();
const RUNTIME_OPTS = {
  packageName: "@theglitchking/persistent-planning",
  pluginName: "persistent-planning",
  configFile: "persistent-planning.json",
};

function emitNoticeOnly() {
  // No runtime, so nobody else will emit the response. Say our piece and stop.
  if (!notice) return;
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: notice },
    }) + "\n"
  );
}

if (!runSessionStart) {
  emitNoticeOnly();
} else if (!notice) {
  await runSessionStart(RUNTIME_OPTS);
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

  await runSessionStart(RUNTIME_OPTS);

  // The runtime can return without emitting (e.g. it chdir-failed). Say our piece.
  if (!merged) {
    realWrite(
      JSON.stringify({
        hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: notice },
      }) + "\n"
    );
  }
}
