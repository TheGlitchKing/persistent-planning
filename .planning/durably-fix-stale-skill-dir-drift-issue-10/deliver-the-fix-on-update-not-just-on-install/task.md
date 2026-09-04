---
title: Deliver the fix on update not just on install
tier: plan
domains:
  - planning
status: ready
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

- [ ] Write down the delivery constraint as a test fixture: a marketplace-shaped install has no `node_modules` in the plugin cache and never triggers `runPostinstall`
- [ ] Add a one-shot reclaim/migration step to `runSessionStart`, run at most once per plugin version (stamp the result in `.claude/persistent-planning.json`)
- [ ] Gate it on `updatePolicy`: `auto` repairs silently, `nudge` warns and offers `relink`, `off` does nothing
- [ ] Fail open and stay fast -- the migration must never block or slow session start; skip immediately when the skill dir is already a correct symlink
- [ ] Bump `@theglitchking/claude-plugin-runtime` and this package's dependency range together; confirm marketplace consumers actually pick up the new runtime from `~/.claude/plugins/npm-cache/`
- [ ] Update all three version sites per the release checklist: `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (`metadata.version` and the plugin entry)
- [ ] Verify the published tarball with `npm pack` + inspect before release, per the v3.0.0 `files`-array regression
- [ ] End-to-end verification from a marketplace-shaped install, not an `npm install`: stale dir in place -> update -> next session -> dir reclaimed, `/start-planning` emits Phase 5/6 and the `## On Completion` block

## Decisions Made

**SessionStart is the only universal execution point.** postinstall covers npm consumers
only, and the broken population is precisely the marketplace consumers. Verified: the
plugin cache carries no `node_modules`; the hook resolves the runtime from the shared
`~/.claude/plugins/npm-cache/`.

**Once per version, not once per session**: stamping the migration against the plugin
version keeps it idempotent and lets a later release re-run it.

**Respect `updatePolicy: off` even for repair.** A user who turned updates off did not
consent to filesystem mutation.

## Status
**Currently ready** -- the durable upgrade path. Without it tasks 1-3 only help fresh installs.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
