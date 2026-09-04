#!/usr/bin/env node
// Postinstall — delegates to @theglitchking/claude-plugin-runtime.
// See https://github.com/TheGlitchKing/claude-plugin-runtime/blob/main/docs/PLUGIN_AUTHORING_SCAFFOLD.md
//
// One thing runs before the delegation: reclaimStaleSkillDirs(). The runtime's linker
// skips a destination that is a real directory rather than a symlink, and skips it
// forever — so v1 leftovers never heal. Renaming the real dir aside first leaves a
// clean destination the runtime then links normally.

import { runPostinstall } from "@theglitchking/claude-plugin-runtime";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { reclaimStaleSkillDirs, writeVersionMarkers, ENV_PREFIX } from "./lib/skill-link.js";
import { createRequire } from "node:module";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const consumerRoot = process.env.INIT_CWD || process.cwd();

try {
  // Skip when the runtime itself would skip: dev-in-place, or linking disabled.
  const devInPlace = resolve(consumerRoot) === resolve(packageRoot);
  if (!devInPlace && process.env[`${ENV_PREFIX}_SKIP_LINK`] !== "1") {
    const r = reclaimStaleSkillDirs(consumerRoot, packageRoot, {
      skillsSubdir: "skills",
      log: (m) => console.log(m),
    });
    if (r.reclaimed.length) {
      console.log(
        `[persistent-planning] reclaimed ${r.reclaimed.length} stale skill dir(s); ` +
        `originals kept alongside as .bak-* — delete them once you are satisfied.`
      );
    }
  }
} catch (err) {
  // Reclaim is best-effort. A failure here must never block the install.
  console.warn(`[persistent-planning] skill reclaim skipped: ${err?.message || err}`);
}

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

try {
  // Stamp the artifact that actually executes, so drift is detectable at all.
  // Only healthy symlinks are stamped — never a real dir, which would mark stale
  // code as current.
  const { version } = createRequire(import.meta.url)("../package.json");
  writeVersionMarkers(consumerRoot, packageRoot, version, { skillsSubdir: "skills" });
} catch {
  // Marker is a diagnostic aid, not a dependency. Absent is a valid state.
}
