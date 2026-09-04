---
title: Make lg task lists self-maintaining and closers enforceable (issue #12)
tier: plan
domains:
  - planning
status: done
last_updated: "2026-09-04"
plan_kind: phase
parent: null
---

# Phase: Make lg task lists self-maintaining and closers enforceable (issue #12)

## Goal
Make an lg phase's task list a product of the tooling rather than of human diligence,
and turn the two mandatory closers from prose into something `plan-status.sh` can
actually enforce.

## Tasks
[Tasks created with `/start-task --parent make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12` will be tracked here.
Each task is a bounded deliverable. Tasks default to dependencies-first scheduling.
Tasks with no inter-dependencies can be marked `parallelizable: true` in their frontmatter
so subagent teams can pick them up concurrently.]

- [x] **Init scripts maintain their parent list** (`init-scripts-maintain-their-parent-list`) — the root fix
- [x] **Placeholders stop counting as work** (`placeholders-stop-counting-as-work`) — parallelizable
- [x] **Scaffold the two closer task dirs** (`scaffold-the-two-closer-task-dirs`) — depends on the insertion logic
- [x] **Enforce mandatory closers in plan-status** (`enforce-mandatory-closers-in-plan-status`) — depends on scaffolding
- [x] **Validate success through comprehensive testing** (`validate-success-through-comprehensive-testing`) (MANDATORY — second-to-last)
- [x] **Documentation pass — create/update/deprecate as many docs as needed to capture what was done, where it lives, how to troubleshoot it, etc. etc.. etc..** (`documentation-pass-create-update-deprecate-docs`) (MANDATORY — last)

> The two mandatory closing tasks above MUST remain the last two tasks of this phase.
> Add new tasks above them; never after. A phase cannot be marked `done` until both are
> `done`, and neither may be `parallelizable` — they gate on everything before them.
>
> - **Validate success**: prove the phase's work with tests that fail if it breaks.
> - **Documentation pass**: create/update/deprecate every doc this phase touches —
>   what it is, where it lives, how to fix it, how to operate it, why it matters.
>   If hit-em-with-the-docs is installed, you MUST use it for this pass --
>   `npx hewtd integrate <file> -a` to create, `npx hewtd archive <file>` to retire,
>   `npx hewtd maintain --quick` to regenerate indexes. Never hand-edit INDEX.md or
>   REGISTRY.md; they are generated.

## Decisions Made

**This plan was itself hand-assembled, which is the bug.** `init-task.sh` created six
task directories and wrote none of them into this `phase.md`; the list above was typed by
hand, and the `(no tasks yet)` placeholder had to be deleted manually. That is the exact
defect this phase removes. Verified on main, not inferred.

**The issue's original root cause was wrong** (corrected on #12): `init-task.sh` does not
"append tasks to the end of the list". It never writes to `phase.md` at all — it
references the file only in an existence check. `init-atom.sh` has the identical gap with
its parent `task.md`. So the "closers must stay last" rule governs a list no tool
produces, and `tests/run.sh` can only ever assert the ordering of a pristine template
render.

**Placeholders are load-bearing in the completion math.** `templates/lg/phase.md:23` and
`templates/lg/task.md:32` ship as real checkboxes, and `plan-status.sh:59-60` counts every
`- [ ]` under a plan with no exclusions. A fresh phase with two tasks reports `0/5 boxes`.
Two consequences, both verified: a plan reads **COMPLETE by ticking lines that say nothing
exists**, and a phase whose real work is done stays incomplete until someone ticks
"no tasks yet". `archive-plan.sh` inherits both through its pre-flight.

**Derive vs. maintain**: the task list duplicates state that already exists on disk (task
directories and their frontmatter). Deriving it at read time would delete the whole bug
class — but `plan-status.sh` counts checkboxes in markdown, and the list doubles as the
human-editable plan surface. So the list stays stored, and the init scripts become
responsible for writing it. Revisit only if the duplication bites again.

**Ordering by construction, not by discipline**: inserting above the closers is what makes
the MANDATORY-last rule true without anyone having to remember it. That is why task 1
gates task 3.

**sm mode is out of scope.** `scripts/init-planning.sh` writes one flat `task_plan.md`
where phases-as-checkboxes *is* the whole artifact, and `CLAUDE.md` requires v2 behavior be
preserved bit-for-bit. Nothing here touches it.

## Status
**Currently done** — all 4 implementation tasks plus both mandatory closers are `status: done`. 99 assertions green, 16/16 docs, released as 3.3.0.

Investigated on `fix/lg-mandatory-closer-tasks`, branched from the merged #10 work
(`d3b3200`). Findings and the correction to the original diagnosis are on
[issue #12](https://github.com/the-glitch-kingdom/persistent-planning/issues/12).

Status enum: `draft | active | paused | done | archived`

When all tasks are `done`, mark this phase `done`. Checking every box in this phase
IS the completion signal — `/plan-status` reads it straight off the artifacts.

When complete, retire it with `/archive-plan make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`: the whole
directory (tasks and atoms with it) moves to the gitignored
`.planning/.archive/make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12/` and the frontmatter above is stamped
`status: archived` + `archived_on`. Nothing is destroyed.

---

## Layer reference (lg mode)
- **Phase** (this file): strategic grouping of related tasks
- **Task** (`.planning/make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12/<task-slug>/task.md`): bounded deliverable
- **Atom** (`.planning/make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12/<task-slug>/atoms/<atom-slug>.md`): subagent hand-off unit
- **Notes** (`.planning/make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12/notes.md` or per-task `notes.md`): cross-cutting references
