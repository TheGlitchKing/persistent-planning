---
title: Eliminate silent no-op exits in relink and update
tier: plan
domains:
  - planning
status: ready
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: []
parallelizable: true
---

# Task: Eliminate silent no-op exits in relink and update

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
No command in this plugin exits 0 after doing nothing; every no-op says what it looked for and where.

## Atoms

- [ ] `update` on a `(not installed)` resolution: print the paths checked and exit non-zero (issue #10 fix #4). Today it prints `Current: (not installed) / Now: (not installed)` and exits 0
- [ ] `runRelink()` (`bin/persistent-planning.js:16-27`): it probes `node_modules/@theglitchking/persistent-planning/scripts/link-skills.js`, falls back to `cwd/scripts/link-skills.js`, and in a marketplace-only consumer neither exists -- it prints "link-skills.js not found" and returns, and the caller exits 0
- [ ] Add `CLAUDE_PLUGIN_ROOT/scripts/link-skills.js` as a third probe so relink works in a marketplace install at all
- [ ] Make the failure message name every path probed, not just the conclusion
- [ ] Audit `registerUpdateCommands` for any other success-shaped no-op on this install shape

## Decisions Made

**A clean exit 0 for a no-op is how this stayed invisible for five months.** That is the
common thread across issue #10's fix #4 and the `runRelink` gap found during triage;
they are the same defect in two places and are fixed together.

**Third probe is the real repair**: relink cannot currently function in the exact install
shape that needs it most.

## Status
**Currently ready** -- independent; touches only this repo's `bin/` and the runtime's CLI registration.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true` -- safe for a subagent to pick up concurrently.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
