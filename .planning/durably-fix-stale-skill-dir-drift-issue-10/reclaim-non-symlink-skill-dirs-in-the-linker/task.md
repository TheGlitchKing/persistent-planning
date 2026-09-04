---
title: Reclaim non-symlink skill dirs in the linker
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: []
parallelizable: false
---

# Task: Reclaim non-symlink skill dirs in the linker

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
`linkSkills()` reclaims a pre-existing real directory instead of skipping it forever, so v1 debris self-heals on the next run rather than persisting silently.

## Atoms

- [x] Reproduce the stalemate: real dir at `.claude/skills/persistent-planning/`, linker warns and leaves it untouched
- [x] Reclaim before delegating: `scripts/lib/skill-link.js` renames a real dir to `<name>.bak-<ISO8601>`, leaving a clean destination the runtime's linker then symlinks normally
- [x] Never `rm -rf`: a failed rename falls through to the old skip and warns loudly with the exact `relink` command
- [x] Report the reclaim count separately from the link count
- [x] Escape hatches: honour `PERSISTENT_PLANNING_SKIP_LINK=1`, add `PERSISTENT_PLANNING_NO_RECLAIM=1`
- [x] Idempotent: a healthy symlink is left alone, so a second run creates no second backup
- [x] Verified by smoke test: sentinel file survives in the `.bak-*` copy; second run reclaims 0

## Decisions Made

**Implemented here, not upstream in `claude-plugin-runtime`** (supersedes the phase's
original "two repos" decision): reclaiming the real directory *before* `runPostinstall`
leaves the runtime's `linkSkills` a clean destination, which it then symlinks normally.
That needs no upstream change, so the fix ships in one repo, one PR, one release —
instead of a runtime publish, a dependency bump, and a coordinated rollout. The runtime's
`src/index.ts:234` skip is still wrong and worth fixing upstream eventually; doing so
would make this shim redundant, and it is written to be harmless if that lands.

**Rename, never delete**: the directory may contain hand edits. `<name>.bak-<timestamp>` is
recoverable and self-documenting; `rm -rf` is not.

**Reclaim is silent-success, failure is loud**: the current bug is a warning nobody reads.
A successful reclaim needs no ceremony; a *failed* one must name the fix.

## Status
**Currently done** -- implemented in `scripts/lib/skill-link.js` + `scripts/link-skills.js`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true` -- safe for a subagent to pick up concurrently.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
