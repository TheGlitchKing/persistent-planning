---
title: Deliver the fix on update not just on install
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: [reclaim-non-symlink-skill-dirs-in-the-linker, version-the-executing-skill-artifact, warn-on-skill-drift-at-sessionstart]
parallelizable: false
---

# Task: Deliver the fix on update not just on install

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
The reclaim migration reaches existing broken installs through a path that actually executes on a plugin update -- the SessionStart hook -- because a marketplace install never runs npm postinstall.

## Atoms

- [x] Delivery constraint confirmed: the marketplace plugin cache has no `node_modules` and never triggers `runPostinstall`; the hook resolves the runtime from `~/.claude/plugins/npm-cache/`
- [x] `autoRepair()` in `hooks/session-start.js` spawns the package's own linker (reclaim + symlink + marker in one), in a child process so a failure cannot take the hook down
- [x] Once per plugin version — stamped as `repairedSkillsForVersion` in `.claude/persistent-planning.json`; stamped regardless of outcome so a repair that cannot succeed does not retry every session, and a later release gets one fresh attempt
- [x] Policy-gated: `auto` repairs, `nudge` warns only, `off` does nothing — verified all three, with the filesystem asserted untouched for `nudge` and `off`
- [x] Fails open and stays fast: two `lstat`s decide the common "nothing to do" case before any work; 10s timeout on the child
- [x] Repair runs before reporting, so a successful repair does not also warn
- [x] End-to-end verified with **no `npm install` anywhere in the path**: stale real dir -> session -> symlink created, `.version` stamped 3.1.0, original preserved as `.bak-*`, second session silent
- [x] Version bumped to 3.2.0 across all three sites: `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both `metadata.version` and the plugin entry)
- [x] `npm pack --dry-run` confirms `scripts/lib/skill-link.js` ships — the `files` array's `scripts/` covers it, avoiding the v3.0.0 regression
- [x] CHANGELOG entry for 3.2.0

## Decisions Made

**No runtime bump needed after all** (supersedes the original release-coupling atom):
because task 1 reclaims *before* delegating, `@theglitchking/claude-plugin-runtime` is
unchanged and the `^0.1.0` range stays as it is. The fix ships as one release of this
package through both distribution paths.

**SessionStart is the only universal execution point.** postinstall covers npm consumers
only, and the broken population is precisely the marketplace consumers. Verified: the
plugin cache carries no `node_modules`; the hook resolves the runtime from the shared
`~/.claude/plugins/npm-cache/`.

**Once per version, not once per session**: stamping the migration against the plugin
version keeps it idempotent and lets a later release re-run it.

**Respect `updatePolicy: off` even for repair.** A user who turned updates off did not
consent to filesystem mutation.

## Status
**Currently done** -- `hooks/session-start.js` `autoRepair()`, released as 3.2.0.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
