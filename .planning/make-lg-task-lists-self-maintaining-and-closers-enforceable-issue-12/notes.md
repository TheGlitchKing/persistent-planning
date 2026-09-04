---
title: Notes — Make lg task lists self-maintaining and closers enforceable (issue #12)
tier: plan
domains:
  - planning
status: active
last_updated: "2026-09-04"
plan_kind: phase
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
---

# Notes: Make lg task lists self-maintaining (issue #12)

Investigation run 2026-09-04 on `fix/lg-mandatory-closer-tasks`, branched from the
merged #10 work (`d3b3200`). Everything below was verified against the scripts, not
inferred from the issue text.

## Correction to the original diagnosis

Issue #12's body claims `init-task.sh` "appends new tasks to the end of the phase's
task list". **It never writes to `phase.md` at all.** The file appears exactly twice
in the script, both inside one existence check:

```bash
if [[ ! -f "${PHASE_DIR}/phase.md" ]]; then
  planning_err "Parent phase not found: .planning/${PARENT_PHASE}/phase.md"
```

It then renders `task.md` + `notes.md` and exits. `init-atom.sh` has the same gap —
it reads the parent `task.md` to resolve the phase and compute `sequence:`, and never
writes the atom into that task's list.

Correction posted: issue #12, comment 5545135897.

## Reproduction (current main)

```bash
init-phase.sh "Ship Widget"
init-task.sh  "Build the widget" --parent ship-widget
init-task.sh  "Wire the API"     --parent ship-widget
```

`ship-widget/phase.md`:

```markdown
- [ ] (no tasks yet — run `/start-task "Task name" --parent ship-widget`)
- [ ] **Validate success through comprehensive testing** (MANDATORY — second-to-last)
- [ ] **Documentation pass — …** (MANDATORY — last)
```

Two task directories on disk. The phase says *no tasks yet*, permanently.

## This plan is its own evidence

The six task directories in this phase were created by `init-task.sh`. None of them
appeared in `phase.md`. The list was typed by hand and the `(no tasks yet)`
placeholder deleted manually — the same hand-assembly the #10 plan needed, before
anyone knew it was a defect rather than a step.

## Second defect: placeholders count as work

Both placeholders ship as real checkboxes:

- `templates/lg/phase.md:23` — `- [ ] (no tasks yet — run …)`
- `templates/lg/task.md:32` — `- [ ] (no atoms yet — …)`

`plan-status.sh:59-60` counts every `- [ ]` under a plan directory, no exclusions:

```bash
total=$(grep -rhoE '^[[:space:]]*- \[[ xX]\] ' --include='*.md' "$1" | wc -l)
checked=$(grep -rhoE '^[[:space:]]*- \[[xX]\] ' --include='*.md' "$1" | wc -l)
```

The fixture above reports `0/5 boxes` — one "no tasks yet", two closers, one "no atoms
yet" per task.

Verified consequences:

1. Checking every box, placeholders included, flips it to `COMPLETE 5/5 boxes` and it
   offers to archive. **A plan can be completed by ticking lines that say nothing
   exists.**
2. A phase whose real work is finished stays incomplete until someone ticks
   "no tasks yet".

`archive-plan.sh` shells out to `plan-status.sh` for its pre-flight, so both reach
archiving.

## Why the tests never caught it

`tests/run.sh:65-75` (sm) and `:103-112` (lg) assert the ordering of the two closer
lines in a **freshly rendered template**. That can never be wrong. Nothing mutates the
plan and re-checks, which is exactly where the invariant breaks. Task 5 fixes the
testing posture, not just the coverage.

## Design note: derive vs. maintain

The task list duplicates state already on disk — the task directories and their
frontmatter. Deriving it at read time would delete this whole bug class. Rejected for
now because `plan-status.sh` counts checkboxes in markdown and the list doubles as the
human-editable plan surface; the list stays stored and the init scripts become
responsible for writing it. Worth revisiting if the duplication bites again.

## Constraints

- **sm mode is untouchable.** `scripts/init-planning.sh` is v2 behavior preserved
  bit-for-bit per `CLAUDE.md`, and its flat `task_plan.md` makes phases-as-checkboxes
  correct. Task 5 asserts its output is byte-identical.
- **One implementation of completion.** `CLAUDE.md` requires `plan-status.sh` be the
  only answer to "is this plan done?"; the mandatory gate goes there and
  `archive-plan.sh` keeps shelling out.
- **Legacy plans must not regress.** Absent `mandatory:` means absent enforcement.
  Retroactively marking finished plans incomplete would be worse than the bug.

## Prior art in this repo

The #10 phase (merged, `d3b3200`) is the reference for the closers-as-real-tasks shape:
`.planning/durably-fix-stale-skill-dir-drift-issue-10/` has both closers as directories
with seeded atoms and `depends_on` covering every preceding task. Task 3 automates what
was done by hand there.
