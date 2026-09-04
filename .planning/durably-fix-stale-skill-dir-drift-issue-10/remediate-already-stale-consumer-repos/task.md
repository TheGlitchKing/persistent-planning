---
title: Remediate already-stale consumer repos
tier: plan
domains:
  - planning
status: ready
last_updated: "2026-09-04"
plan_kind: task
parent: durably-fix-stale-skill-dir-drift-issue-10
depends_on: [reclaim-non-symlink-skill-dirs-in-the-linker, deliver-the-fix-on-update-not-just-on-install]
parallelizable: false
---

# Task: Remediate already-stale consumer repos

**Phase**: `durably-fix-stale-skill-dir-drift-issue-10`

## Goal
Every repo on this machine currently running a stale copy is reclaimed and verified against 3.1.0.

## Atoms

- [ ] `semantic-pages` -- real dir dated Apr 12, 23 lines behind: reclaim and verify
- [ ] `semantic-memory` -- real dir dated Apr 21, 23 lines behind: reclaim and verify
- [ ] Sweep the rest of `~/workspace/the-glitch-kingdom/*` plus `kentro/ts-rnd-faa-dev-workspace` named in issue #10
- [ ] Verify per repo by diffing the linked `scripts/init-planning.sh` against this repo's copy -- expect zero differences, not merely "6 phases present"
- [ ] Check each stale repo's existing `.planning/` for plans generated from the old template: they lack Phase 5/6 *and* the `## On Completion` archive block
- [ ] Decide per repo whether to backfill those plans or leave them (record the call in this task's `notes.md`)
- [ ] Confirm `antagonist-ai` stays a correct symlink after the runtime bump (regression check on the healthy case)

## Decisions Made

**Verify by diff, not by feature-grep**: an early triage grep counted 6 phase mentions in
both stale copies and read as healthy. Only `diff` against the source exposed the 23-line
gap, including the missing `## On Completion` block.

**Do this after the fix, not before**: hand-repairing first would erase the evidence that
proves task 6's delivery path works end to end.

## Status
**Currently ready** -- operational cleanup; gated on the fix shipping so it doubles as end-to-end verification.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
