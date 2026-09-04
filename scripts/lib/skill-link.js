// Skill-dir reclaim + drift detection.
//
// Why this exists: v1's `persistent-planning install` (removed in v2.0.0) COPIED
// skills/persistent-planning/ into a consumer's .claude/skills/. The v2+ linker in
// claude-plugin-runtime only symlinks, and when it finds a real directory at the
// destination it warns and skips — forever. So v1 leftovers keep executing a frozen
// copy while the update check reports the (correct, current) plugin version. Two
// artifacts, nothing reconciling them.
//
// The fix is to reclaim the real directory BEFORE the runtime's linker runs: rename
// it aside, which leaves a clean destination the linker then symlinks normally. That
// needs no upstream change — see the phase notes for why this lives here for now.
//
// Nothing here ever deletes. A reclaimed directory is renamed to
// <name>.bak-<ISO8601>, and a failure to rename falls through to the old skip.

import { existsSync, lstatSync, readdirSync, readlinkSync, renameSync } from "node:fs";
import { join, relative, resolve, dirname } from "node:path";

export const ENV_PREFIX = "PERSISTENT_PLANNING";

function lstatSafe(p) {
  try { return lstatSync(p); } catch { return null; }
}

/** Skill directory names shipped by this package. Mirrors the runtime's filter. */
export function packagedSkillNames(packageRoot, skillsSubdir = "skills") {
  const dir = join(packageRoot, skillsSubdir);
  if (!existsSync(dir)) return [];
  try {
    return readdirSync(dir, { withFileTypes: true })
      .filter((d) => d.isDirectory() && !d.name.endsWith("-workspace"))
      .map((d) => d.name);
  } catch {
    return [];
  }
}

/**
 * What is actually sitting at .claude/skills/<name>, and is it ours?
 *
 * Returns one of:
 *   absent          — nothing there; the linker will create the symlink
 *   symlink-ok      — symlink pointing at this package's copy; healthy
 *   symlink-foreign — symlink pointing somewhere else; another install owns it
 *   real-dir        — a real directory; v1 debris or a hand-managed copy. This is
 *                     the drift state: nothing in the current system creates one.
 */
export function describeSkill(consumerRoot, packageRoot, name, skillsSubdir = "skills") {
  const dest = join(consumerRoot, ".claude", "skills", name);
  const src = join(packageRoot, skillsSubdir, name);
  const st = lstatSafe(dest);
  if (!st) return { name, dest, src, state: "absent" };
  if (st.isSymbolicLink()) {
    let target = null;
    try { target = readlinkSync(dest); } catch { /* unreadable link */ }
    const expected = relative(dirname(dest), src);
    if (target === expected) return { name, dest, src, state: "symlink-ok", target };
    // A different-but-equivalent path still resolves to us; treat that as healthy.
    try {
      if (target && resolve(dirname(dest), target) === resolve(src)) {
        return { name, dest, src, state: "symlink-ok", target };
      }
    } catch { /* fall through */ }
    return { name, dest, src, state: "symlink-foreign", target };
  }
  return { name, dest, src, state: "real-dir" };
}

/** Every packaged skill's current state in a consumer repo. */
export function surveySkills(consumerRoot, packageRoot, skillsSubdir = "skills") {
  return packagedSkillNames(packageRoot, skillsSubdir)
    .map((n) => describeSkill(consumerRoot, packageRoot, n, skillsSubdir));
}

function backupPath(dest) {
  // ISO8601, filesystem-safe. Collisions only within the same second on the same
  // dir, which a suffix resolves.
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  let candidate = `${dest}.bak-${stamp}`;
  let n = 1;
  while (existsSync(candidate)) candidate = `${dest}.bak-${stamp}-${n++}`;
  return candidate;
}

/**
 * Rename any real directory at .claude/skills/<name> aside so the linker can symlink.
 *
 * Idempotent: a healthy symlink is left completely alone, so a second run is a no-op
 * and produces no second backup.
 *
 * Returns { reclaimed: [{name, from, to}], failed: [{name, dest, error}], healthy: n }.
 */
export function reclaimStaleSkillDirs(consumerRoot, packageRoot, opts = {}) {
  const { skillsSubdir = "skills", log = () => {} } = opts;
  const result = { reclaimed: [], failed: [], healthy: 0 };

  if (process.env[`${ENV_PREFIX}_NO_RECLAIM`] === "1") {
    log(`[persistent-planning] ${ENV_PREFIX}_NO_RECLAIM=1 — leaving existing skill dirs alone.`);
    return result;
  }

  for (const info of surveySkills(consumerRoot, packageRoot, skillsSubdir)) {
    if (info.state !== "real-dir") {
      if (info.state === "symlink-ok") result.healthy++;
      continue;
    }
    const to = backupPath(info.dest);
    try {
      renameSync(info.dest, to);
      result.reclaimed.push({ name: info.name, from: info.dest, to });
      log(`[persistent-planning] reclaimed stale skill dir ${info.dest} -> ${to}`);
    } catch (err) {
      // ponytail: never rm -rf a directory a user may have hand-edited. If we cannot
      // move it, say so loudly and leave it — the old skip, but no longer silent.
      result.failed.push({ name: info.name, dest: info.dest, error: err?.message || String(err) });
      log(
        `[persistent-planning] WARNING: ${info.dest} is a real directory, not a symlink,\n` +
        `  so it will keep running a frozen copy of the skill. Could not move it aside:\n` +
        `  ${err?.message || err}\n` +
        `  Move or remove it, then run:  npx persistent-planning relink`
      );
    }
  }
  return result;
}

/** Skills still drifted after a reclaim attempt — what SessionStart should warn about. */
export function driftedSkills(consumerRoot, packageRoot, skillsSubdir = "skills") {
  return surveySkills(consumerRoot, packageRoot, skillsSubdir)
    .filter((s) => s.state === "real-dir" || s.state === "symlink-foreign");
}
