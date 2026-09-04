---
title: Durably fix stale skill-dir drift (issue #10)
tier: plan
domains:
  - planning
status: active
last_updated: "2026-09-04"
plan_kind: phase
parent: null
---

# Phase: Durably fix stale skill-dir drift (issue #10)

## Goal
Make it structurally impossible for a consumer repo to execute a stale copy of
`skills/persistent-planning/` while the update check reports a different, current
artifact -- and reclaim the v1 leftovers that are already in that state.

## Tasks
[Tasks created with `/start-task --parent durably-fix-stale-skill-dir-drift-issue-10` will be tracked here.
Each task is a bounded deliverable. Tasks default to dependencies-first scheduling.
Tasks with no inter-dependencies can be marked `parallelizable: true` in their frontmatter
so subagent teams can pick them up concurrently.]

- [ ] **Reclaim non-symlink skill dirs in the linker** (`reclaim-non-symlink-skill-dirs-in-the-linker`) -- upstream, unblocks remediation
- [ ] **Version the executing skill artifact** (`version-the-executing-skill-artifact`) -- parallelizable
- [ ] **Warn on skill drift at SessionStart** (`warn-on-skill-drift-at-sessionstart`) -- depends on versioning
- [ ] **Eliminate silent no-op exits in relink and update** (`eliminate-silent-no-op-exits-in-relink-and-update`) -- parallelizable
- [ ] **Deliver the fix on update not just on install** (`deliver-the-fix-on-update-not-just-on-install`) -- depends on tasks 1-3; the durable upgrade path
- [ ] **Remediate already-stale consumer repos** (`remediate-already-stale-consumer-repos`) -- depends on the linker fix and the delivery path
- [ ] **Validate success through comprehensive testing** (`validate-success-through-comprehensive-testing`) (MANDATORY — second-to-last)
- [ ] **Documentation pass — create/update/deprecate docs** (`documentation-pass-create-update-deprecate-docs`) (MANDATORY — last)

> The two mandatory closing tasks above MUST remain the last two tasks of this phase.
> Add new tasks above them; never after. A phase cannot be marked `done` until both are
> `done`, and neither may be `parallelizable` — they gate on everything before them.
>
> - **Validate success**: prove the phase's work with tests that fail if it breaks.
> - **Documentation pass**: create/update/deprecate every doc this phase touches —
>   what it is, where it lives, how to fix it, how to operate it, why it matters.
>   If hit-em-with-the-docs is installed, use it for this pass.

## Decisions Made

**Issue #10's stated root cause is wrong; the plan supersedes it**: the issue is titled
"Linker copies the skill dir instead of symlinking it." It does not. There is no
`cpSync`/`copyFileSync`/`copySync` anywhere in `claude-plugin-runtime` -- `src/index.ts`
or the shipped `dist/`. `linkSkills()` only ever calls `symlinkSync`. Issue fix #1
("symlink instead of copy") is a no-op against current code.

**The real defect is refusal-to-reclaim, not copying**: `claude-plugin-runtime`
`src/index.ts:234` -- when a non-symlink exists at the destination it emits
`console.warn` and `continue`s. Permanently. Nothing ever replaces it, and the warning
drowns in npm postinstall output.

**`relink` does NOT remedy this, contrary to the issue text**: `relink` ->
`onAfterUpdate` -> `runRelink()` (`bin/persistent-planning.js:16`) -> spawns
`scripts/link-skills.js` -> `runPostinstall` -> the same `linkSkills` -> the same skip
at :234. Any prior report of relink "working" involved deleting the directory first.
Task 1 is therefore a prerequisite for Task 5, not an alternative to it.

**Origin is a v1 migration, not a v2+ regression**: the stale dirs date to April, and
`bin/persistent-planning.js` still carries the deprecation stub for
`persistent-planning install`, removed in v2.0.0. v1's installer copied. This is v1
debris that the v2+ linker is structurally incapable of reclaiming -- which is why the
fix must be a migration path, not just a link path.

**Reclaim non-destructively**: rename an existing real dir to `<name>.bak-<timestamp>`
and symlink over it. Never `rm -rf` a directory the user may have hand-edited.

**Detection is a separate guarantee from repair**: even with reclaim shipped, install
shapes exist where a symlink is impossible (Windows without developer mode, some CI
checkouts). Tasks 2 and 3 -- version the artifact that actually executes, then warn on
drift -- are the guard for those, and they are not optional follow-ups.

**A fix that only runs at `npm install` never reaches the affected population**: the
broken shape *is* the marketplace install, and a marketplace install has no npm
postinstall -- so `runPostinstall` -> `linkSkills` never executes on update. Verified
2026-09-04: the plugin cache at
`~/.claude/plugins/cache/persistent-planning-marketplace/persistent-planning/3.1.0/`
contains **no `node_modules` at all**; `hooks/session-start.js` resolves the runtime out
of the shared `~/.claude/plugins/npm-cache/node_modules/@theglitchking/claude-plugin-runtime/`.
The only thing that runs every session in that shape is the SessionStart hook. The hook
is therefore the delivery vehicle for the reclaim migration, not merely the place that
warns about drift. Task 6 owns this and gates the phase's actual value.

**Bumping the runtime does not by itself ship anything**: `package.json` pins
`@theglitchking/claude-plugin-runtime: ^0.1.0`, and marketplace consumers resolve it
from the shared npm-cache rather than a vendored copy. The release must move the runtime
version, this package's dependency range, and all three version sites in the release
checklist together, then be verified from a marketplace-shaped install -- not just from
`npm install`.

**Two repos, one phase**: Task 1 lands in `claude-plugin-runtime`; Tasks 2-4 land in
`persistent-planning`; Task 5 is operational cleanup across sibling repos. The phase is
tracked here because this repo is where the damage was observed.

## Status
**Currently active** -- 6 implementation tasks plus the two mandatory closers, all
backed by real task directories with atoms (not bare checkboxes).

Blast radius confirmed on 2026-09-04:

| Repo | `.claude/skills/persistent-planning` | Drift |
|------|--------------------------------------|-------|
| `semantic-pages` | real dir, Apr 12 | 23 lines behind 3.1.0 |
| `semantic-memory` | real dir, Apr 21 | 23 lines behind 3.1.0 |
| `antagonist-ai` | symlink -> node_modules | none |
| `persistent-planning` | absent (dev-in-place; `runPostinstall` returns null) | n/a |

Both stale copies are missing the Phase 5/6 mandatory closers *and* the entire
`## On Completion` archive block -- so `/start-planning` there emits plans with no
archive path, not merely no closers.

Status enum: `draft | active | paused | done | archived`

When all tasks are `done`, mark this phase `done`. Checking every box in this phase
IS the completion signal — `/plan-status` reads it straight off the artifacts.

When complete, retire it with `/archive-plan durably-fix-stale-skill-dir-drift-issue-10`: the whole
directory (tasks and atoms with it) moves to the gitignored
`.planning/.archive/durably-fix-stale-skill-dir-drift-issue-10/` and the frontmatter above is stamped
`status: archived` + `archived_on`. Nothing is destroyed.

---

## Layer reference (lg mode)
- **Phase** (this file): strategic grouping of related tasks
- **Task** (`.planning/durably-fix-stale-skill-dir-drift-issue-10/<task-slug>/task.md`): bounded deliverable
- **Atom** (`.planning/durably-fix-stale-skill-dir-drift-issue-10/<task-slug>/atoms/<atom-slug>.md`): subagent hand-off unit
- **Notes** (`.planning/durably-fix-stale-skill-dir-drift-issue-10/notes.md` or per-task `notes.md`): cross-cutting references
