---
title: Warn on skill drift at SessionStart
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: [version-the-executing-skill-artifact]
parallelizable: false
---

# Task: Warn on skill drift at SessionStart

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
When the linked skill version differs from the plugin version, SessionStart says so and names the exact command to fix it.

## Atoms

- [x] `driftNudge()` compares the linked skill against the installed package via `driftedSkills()`
- [x] On drift, the nudge names the path, why it is drifted, the running version vs the installed version, the user-visible consequence, and `npx persistent-planning relink`
- [x] Merged into the existing single `SessionStart` JSON response — `notice` is now `[planNudge(), driftNudge()]` joined, so the one stdout-intercept covers both
- [x] Fails open: the whole check is wrapped, and any error yields an empty string
- [x] Suppressed under `updatePolicy: off` — verified silent with the policy set, warning with it at `nudge`
- [x] Verified the output parses as one valid JSON payload, not a second response line

## Decisions Made

**Nudge, do not auto-repair, in this task**: repair belongs to task 6 where it is gated by
policy. Task 3 is pure detection, so it stays useful even if auto-repair is later
disabled.

**One stdout write**: `hooks/session-start.js` already merges its plan nudge into the
runtime's single response. The drift warning uses the same seam.

## Status
**Currently done** -- `hooks/session-start.js`.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
