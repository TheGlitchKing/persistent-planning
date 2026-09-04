---
title: Eliminate silent no-op exits in relink and update
tier: plan
domains:
  - planning
status: done
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

- [x] `update` on no managed install now exits **1** and lists every path probed, instead of printing `(not installed)` twice and exiting 0
- [x] Guard deliberately excludes the package the CLI itself runs from — under `npx --no ... update` that copy always exists, which is exactly what made the original report look like a clean success
- [x] Verified against the issue's repro: exits 1 with named paths; with `CLAUDE_PLUGIN_ROOT` set to a real marketplace install it passes through and reports `Current: 3.1.0`
- [x] `runRelink()` gained two probes — `CLAUDE_PLUGIN_ROOT/scripts/link-skills.js` and the package the CLI runs from — so relink functions in a marketplace-only install, the shape that needs it most
- [x] `runRelink()` failure now lists every path probed and sets a non-zero exit code
- [x] `runRelink()` propagates the linker's own non-zero exit instead of swallowing it
- [x] Audited the rest of `bin/` — `status` is a report, so exit 0 on "(not installed)" is correct there and was left alone

## Decisions Made

**A clean exit 0 for a no-op is how this stayed invisible for five months.** That is the
common thread across issue #10's fix #4 and the `runRelink` gap found during triage;
they are the same defect in two places and are fixed together.

**Third probe is the real repair**: relink cannot currently function in the exact install
shape that needs it most.

## Status
**Currently done** -- `bin/persistent-planning.js`. The runtime's CLI registration was not modified; a commander `preAction` hook fails before the runtime's action runs.

Status enum: `draft | active | paused | done | archived`

## Dependencies
None. Marked `parallelizable: true` -- safe for a subagent to pick up concurrently.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
