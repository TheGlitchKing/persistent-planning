---
title: lg plan artifact lifecycle — who writes what
tier: reference
domains:
  - architecture
audience:
  - developers
tags: []
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: >-
  Which script writes which lg plan artifact, the rule that creating a child writes it
  into its parent's list, and how insertion keeps the mandatory closers last.
estimated_read_time: 3 minutes
word_count: 438
last_validated: '2026-09-04'
backlinks: []
---

# lg plan artifact lifecycle — who writes what

In lg mode a plan is a tree of markdown artifacts, and more than one thing writes
into them. This page states the ownership, because for a long time nothing did —
and the gap it left is [issue #12](https://github.com/the-glitch-kingdom/persistent-planning/issues/12).

## Ownership

| Artifact | Created by | Its list is written by |
|---|---|---|
| `<phase>/phase.md` | `init-phase.sh` | `init-task.sh`, on every new task |
| `<phase>/notes.md` | `init-phase.sh` | humans |
| `<phase>/<task>/task.md` | `init-task.sh` (closers: `init-phase.sh`) | `init-atom.sh`, on every new atom |
| `<phase>/<task>/notes.md` | `init-task.sh` | humans |
| `<phase>/<task>/atoms/<atom>.md` | `init-atom.sh` | humans |

The rule worth remembering: **creating a child writes it into its parent's list.**
Before 3.3.0, `init-task.sh` referenced `phase.md` only in an existence check and
`init-atom.sh` never touched `task.md`, so every list was maintained by hand — and a
phase could report "no tasks yet" with six task directories on disk.

## The insertion rule

`planning_insert_list_item <file> <section> <line>` in `scripts/lib/planning.sh`:

- inserts **above the first item marked MANDATORY**, so the closers stay last by
  construction rather than by anyone remembering the rule;
- appends after the last item when the section has no MANDATORY entries (atom lists);
- drops the `(no … yet)` placeholder, including indented continuation lines, the
  first time a real item lands;
- is idempotent — an identical line already present is left alone, so re-running
  under `PLANNING_FORCE=1` cannot double-insert;
- is section-scoped (`## Heading` to the next `## `), so it cannot wander into a
  neighbouring list.

It **anchors on the MANDATORY marker, never on line numbers.** The list is a
human-editable surface; positions do not survive contact with editing. This is tested
against a hand-reordered, partially-checked, annotated list.

## The two closers

Every phase is scaffolded with both closing tasks as real directories:

```
<phase>/validate-success-through-comprehensive-testing/
<phase>/documentation-pass-create-update-deprecate-docs/
```

Each gets `task.md` (with `mandatory: true`, `parallelizable: false`), `notes.md`,
`atoms/`, and seeded atoms — not empty placeholders. They were previously two lines
of prose in `phase.md`, which made the most important tasks in every plan the only
ones with no artifact a subagent could read and nowhere to record decisions.

See [Mandatory frontmatter](../reference/mandatory-frontmatter.md) for what
`mandatory: true` does, and
[Mandatory closing phases](../standards/mandatory-closing-phases.md) for why they exist.

## Placeholders are not work

`(no tasks yet …)` and `(no atoms yet …)` are **italic text, not checkboxes**. They
used to ship as `- [ ]`, and `plan-status.sh` counts every checkbox under a plan — so
a fresh phase with two tasks reported `0/5 boxes` and a plan could reach 100% by
ticking lines asserting that nothing existed. See
[Plan never reads complete](../troubleshooting/plan-never-reads-complete.md).

## sm mode is different, on purpose

`scripts/init-planning.sh` writes a single flat `task_plan.md` where phases-as-checkboxes
*is* the entire artifact. None of the above applies, and per `CLAUDE.md` its v2 behavior
is preserved bit-for-bit — the test suite diffs its output against the pre-change render.
