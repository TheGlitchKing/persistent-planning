---
title: Remediate already-stale consumer repos
tier: plan
domains:
  - planning
status: blocked
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

- [x] Full sweep of `~/workspace/the-glitch-kingdom/*` plus `kentro/ts-rnd-faa-dev-workspace`
- [x] Verified by **diff**, not feature-grep: all three affected repos are exactly 23 lines behind 3.1.0
- [x] Established the copies are accidental, not deliberate vendoring — committed 2026-04-05 in `0a7f534 "feat: scaffold semantic-pages MCP server..."`, swept in by v1's installer
- [x] Established the blocker (below): none of the three has `node_modules/@theglitchking/persistent-planning`, so there is nothing local to symlink to
- [ ] `semantic-pages` — reclaim and verify **(blocked on 3.2.0 release)**
- [ ] `semantic-memory` — reclaim and verify **(blocked on 3.2.0 release)**
- [ ] `kentro/ts-rnd-faa-dev-workspace` — reclaim and verify **(blocked on 3.2.0 release)**
- [ ] Per repo: the 4 stale files are **git-tracked**, so remediation is a commit in that repo, not a silent cleanup — needs each repo's owner to take it
- [ ] Check each repo's existing `.planning/` for plans generated from the old template and decide whether to backfill
- [x] `antagonist-ai`, `company-websites`, `glitch-stock-trading-rig`, `tiny-the-datastorm` confirmed healthy symlinks — regression check on the good case

### Survey (2026-09-04)

| Repo | State | Drift | Skill dir git-tracked |
|---|---|---|---|
| `semantic-pages` | real dir | 23 lines | yes (4 files) |
| `semantic-memory` | real dir | 23 lines | yes (4 files) |
| `kentro/ts-rnd-faa-dev-workspace` | real dir | 23 lines | not checked |
| `antagonist-ai` | symlink | — | no |
| `company-websites` | symlink | — | yes (the symlink itself) |
| `glitch-stock-trading-rig` | symlink | — | yes (the symlink itself) |
| `tiny-the-datastorm` | symlink | — | no |

## Decisions Made

**BLOCKED on the 3.2.0 release — deliberately not forced.** Two things make
remediating these repos now the wrong move:

1. **Nothing local to symlink to.** None of the three affected repos has
   `node_modules/@theglitchking/persistent-planning`. Running the linker there would
   point `.claude/skills/persistent-planning` at *this dev checkout* — a path that exists
   on one machine and breaks for anyone else who clones those repos. Worse than the stale
   copy it replaced.
2. **The stale files are git-tracked in those repos.** Reclaiming deletes 4 tracked files
   and adds a symlink — a commit in someone else's repo, and a decision about whether a
   skill dir should be tracked at all. That is their owner's call, not a side effect of
   this PR.

The correct remediation is the one this phase built: install 3.2.0 in each repo
(marketplace plugin or npm dep) and let `autoRepair()` do it on the next session. That
needs the release to actually ship, which is why this task stays open behind it.

**Verify by diff, not by feature-grep**: an early triage grep counted 6 phase mentions in
both stale copies and read as healthy. Only `diff` against the source exposed the 23-line
gap, including the missing `## On Completion` block.

**Do this after the fix, not before**: hand-repairing first would erase the evidence that
proves task 6's delivery path works end to end.

## Status
**Currently blocked** -- survey and diagnosis complete; repair waits on the 3.2.0 release. The mechanism is already proven end-to-end against a fixture (see the delivery task).

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
