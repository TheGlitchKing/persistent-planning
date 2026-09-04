---
title: Notes — Durably fix stale skill-dir drift (issue #10)
tier: plan
domains:
  - planning
status: active
last_updated: "2026-09-04"
plan_kind: phase
parent: durably-fix-stale-skill-dir-drift-issue-10
---

# Notes: Durably fix stale skill-dir drift (issue #10)

Cross-cutting context for every task in this phase. Investigation performed
2026-09-04 against working copies, not against the issue text.

## Corrections to issue #10

The issue is well-observed but misattributes the cause. Two of its four proposed
fixes do not survive contact with the code:

| Issue claim | Reality |
|---|---|
| "Linker copies the skill dir instead of symlinking it" | It never copies. No `cpSync`/`copyFileSync`/`copySync` in `claude-plugin-runtime` `src/index.ts` **or** the shipped `dist/`. `linkSkills()` only calls `symlinkSync`. |
| Fix #1: "symlink instead of copy" | Already the behavior. A no-op. |
| "`relink` is the intended remedy and it works" | It does not. `relink` -> `onAfterUpdate` -> `runRelink()` -> `link-skills.js` -> `runPostinstall` -> the same `linkSkills` -> the same skip. It only appeared to work when the directory had been deleted first. |
| Fixes #2, #3, #4 | Valid, and #2/#3 are promoted to primary — see phase decisions. |

Retitle suggestion for the issue: *"Linker refuses to reclaim a non-symlink skill
dir, so v1 leftovers run stale forever."*

## The actual mechanism

`claude-plugin-runtime/src/index.ts:228-240`:

```js
const st = lstatSafe(dest);
if (st) {
  if (st.isSymbolicLink()) {
    if (readlinkSync(dest) === rel) { linked++; continue; }
    rmSync(dest, { force: true });
  } else {
    console.warn(`[plugin-runtime] skipping ${dest} — a non-symlink already exists there.`);
    continue;                                  // <-- permanent stalemate
  }
}
symlinkSync(rel, dest, "dir");
```

A symlink is reconciled. A real directory is skipped, forever, behind a
`console.warn` that drowns in npm postinstall output.

Meanwhile `installedVersion()` falls back to `CLAUDE_PLUGIN_ROOT` — genuinely
3.1.0 — while `/start-planning` executes `.claude/skills/persistent-planning/scripts/init-planning.sh`,
which is pre-3.1.0. **It reports the version of one artifact while running
another**, and the skill dir carries no version marker, so the drift is
undetectable in principle. That is what task 2 fixes.

## Origin: v1 debris, not a v2+ regression

The stale dirs date to April. `bin/persistent-planning.js` still carries a
deprecation stub for `persistent-planning install`, removed in v2.0.0 — v1's
installer copied. So this is a **migration** problem: v1 left real directories
behind and the v2+ linker cannot reclaim them. Fixing the link path alone will
not clear the installed base; that is why task 6 exists.

## Delivery constraint (drives task 6)

Verified 2026-09-04:

- `~/.claude/plugins/cache/persistent-planning-marketplace/persistent-planning/3.1.0/`
  contains **no `node_modules`**.
- `hooks/session-start.js` resolves `@theglitchking/claude-plugin-runtime` to
  `~/.claude/plugins/npm-cache/node_modules/@theglitchking/claude-plugin-runtime/dist/index.js`
  — a cache shared across all TheGlitchKing plugins.
- A marketplace install therefore **never runs npm postinstall**, so
  `runPostinstall` -> `linkSkills` never executes on update.
- `runPostinstall` also returns `null` when `consumerRoot === packageRoot`, which
  is why this repo itself has no `.claude/skills/persistent-planning`.

The broken population is exactly the population that npm postinstall cannot
reach. The SessionStart hook is the only code that runs every session in that
shape, so it is the delivery vehicle — not merely the place that warns.

## Blast radius (2026-09-04)

| Repo | `.claude/skills/persistent-planning` | Drift |
|------|--------------------------------------|-------|
| `semantic-pages` | real dir, Apr 12 | 23 lines behind 3.1.0 |
| `semantic-memory` | real dir, Apr 21 | 23 lines behind 3.1.0 |
| `antagonist-ai` | symlink -> `node_modules/...` | healthy |
| `persistent-planning` | absent (dev-in-place) | n/a |

Both stale copies are missing:

- `Phase 5: Validate success through comprehensive testing (MANDATORY)`
- `Phase 6: Documentation pass (MANDATORY)`
- the entire `## On Completion` block, i.e. the `/plan-status` + `/archive-plan`
  instructions

So plans generated there have **no archive path**, not merely no closers.

## Verification trap

An early triage grep counted phase mentions and closer keywords in the stale
copies and returned `phases: 6 | closers: 2` — reading as healthy. Only
`diff` against this repo's `scripts/init-planning.sh` exposed the 23-line gap.
**Verify by diff, never by feature-grep.** Applies to task 5 and to the
validation closer.

## Release coupling

`package.json` pins `@theglitchking/claude-plugin-runtime: ^0.1.0`. The linker
fix lands upstream, so shipping it requires moving the runtime version *and*
this package's dependency range, then all three version sites from the release
checklist in `CLAUDE.md`: `package.json`, `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json` (`metadata.version` **and** the plugin entry).
Verify the tarball with `npm pack` + inspect before release — v3.0.0 shipped
broken because `scripts/` and `templates/` were missing from the `files` array.

## Related upstream issues

Filed against `the-glitch-kingdom/babel-fish` the same day, unrelated to this
phase but sharing the "documented behavior with no caller" shape:

- babel-fish#6 — plugin/skill repos generate an empty project map
- babel-fish#7 — session vocabulary mining never runs
