---
title: Warn on skill drift at SessionStart
tier: plan
domains:
  - planning
status: ready
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

- [ ] In `runSessionStart`, compare the linked-skill `.version` marker against the plugin/package version
- [ ] On mismatch, emit a nudge naming both versions, the skill path, and `npx persistent-planning relink`
- [ ] Merge into the existing single `SessionStart` JSON response -- this repo already intercepts the one stdout write for its plan nudge; a second response line is invalid JSON
- [ ] Fail open: any error in the drift check must leave session start untouched (match the existing hook's posture)
- [ ] Suppress the nudge when `updatePolicy: off`
- [ ] Verify the merge against `hooks/session-start.js` in this repo, which already wraps the runtime's response

## Decisions Made

**Nudge, do not auto-repair, in this task**: repair belongs to task 6 where it is gated by
policy. Task 3 is pure detection, so it stays useful even if auto-repair is later
disabled.

**One stdout write**: `hooks/session-start.js` already merges its plan nudge into the
runtime's single response. The drift warning uses the same seam.

## Status
**Currently ready** -- blocked on the version marker from task 2.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
