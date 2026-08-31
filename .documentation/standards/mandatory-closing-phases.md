---
title: Mandatory Closing Phases
tier: standard
domains:
  - standards
audience:
  - developers
tags:
  - testing
status: active
last_updated: '2026-08-31'
version: 1.0.0
purpose: The two phases every persistent-planning plan must end with — validate
  success through comprehensive testing, then a documentation pass — why they
  exist, how they are seeded, and how to keep them last.
estimated_read_time: 4 minutes
word_count: 770
last_validated: '2026-08-31'
backlinks: []
---

# Mandatory Closing Phases

Every plan this plugin creates ends with the same two units of work, in the same
order, no exceptions:

1. **Validate success through comprehensive testing**
2. **Documentation pass — create / update / deprecate docs**

They are seeded into the templates so an agent never has to remember them, and
they are marked `MANDATORY` in the artifact itself so an agent re-reading the
plan mid-run can see they are not optional filler.

## Why they exist

A plan that stops at "execute/build" produces work nobody has proven and nobody
can operate. Both failures are invisible at the moment they happen and expensive
later:

- **Without the validation phase**, "done" means "the agent believes it works."
  The next change silently breaks it, because nothing fails when it does.
- **Without the documentation phase**, the knowledge of what changed lives only
  in a chat transcript that is discarded at the end of the session. The next
  contributor — human or agent — re-derives it from source, or gets it wrong.

Putting them *in the template* rather than in a style guide is the whole point.
Guidance in a style guide is read once; a checkbox in the plan the agent re-reads
before every decision stays in the attention window. This is the same
filesystem-as-working-memory reasoning behind the plan artifacts themselves — see
[Manus Context Engineering Principles](../architecture/context-engineering-principles.md).

## Where they live

| Mode | Artifact | Section | Seeded as |
|---|---|---|---|
| sm | `.planning/<slug>/task_plan.md` | `## Phases` | Phase 5 and Phase 6 of 6 |
| lg | `.planning/<phase-slug>/phase.md` | `## Tasks` | The last two task checkboxes |

In **sm mode** the plan is a single file, so the two phases are literally the
last two checkboxes under `## Phases`.

In **lg mode** the plan is a tree (phase → task → atom, see
[Lg-Mode Layered Planning Guide](../architecture/lg-mode.md)). The closing pair is seeded at the
**phase** level, because a phase is the strategic unit that actually ships. Every
phase validates its own work and documents its own work; a phase cannot be marked
`done` until both closing tasks are `done`. Individual tasks and atoms do **not**
each carry the pair — that would produce a documentation pass per atom, which is
noise.

Neither closing task may be marked `parallelizable: true`. They gate on
everything before them by definition.

## The ordering rule

> New work is inserted **above** the closing pair, never after it.

An agent adding phases to an sm plan renumbers the closing pair so they remain
last (Phase 5/6 becomes Phase 7/8, and so on). An agent adding tasks to an lg
phase appends them above the two closing checkboxes. The template states this
rule inline, directly beneath the checkboxes, so it survives the plan being read
in isolation without this document.

The rule is mechanical rather than a judgment call precisely so that it is
enforceable — see [how it is tested](../testing/test-suite.md).

## What each phase actually requires

**Validate success through comprehensive testing.** Prove the work with a check
that *fails if the change breaks*. A test that passes both before and after the
change validates nothing. For this repository that means adding assertions to
`tests/run.sh`; for a consuming project it means whatever that project's test
command is. Mutation-check the assertion at least once: break the thing on
purpose, confirm the test goes red, put it back.

**Documentation pass.** Create, update, or deprecate every doc the change
touches, answering: what it is, where it lives, how to fix it, how to operate it,
and why it matters. Deprecation counts — a doc made wrong by the change is worse
than a missing one. If [hit-em-with-the-docs](https://github.com/TheGlitchKing/hit-em-with-the-docs)
is installed, this pass **must** go through it (`hewtd integrate`, `hewtd
archive`, `hewtd maintain`) rather than hand-managed markdown, so the doc lands
in a domain and the indexes stay honest.

## How to operate it

Nothing to run — the phases arrive with the plan:

```bash
/start-planning "Refactor auth"          # sm: task_plan.md seeded with 6 phases
/start-planning "Foundation" --mode lg   # lg: phase.md seeded with 2 closing tasks
```

To confirm the templates still seed them correctly after editing:

```bash
npm test
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| A new plan has only 4 phases | Plan created by persistent-planning < 3.1.0 | Append the two closing phases by hand; upgrade the plugin |
| Closing phases are no longer last | Work appended below them | Move the new phases above the pair and renumber |
| `npm test` fails on "documentation phase is last" | A template edit added a checkbox after the pair, or reworded the pair | Restore the ordering in `scripts/init-planning.sh` / `templates/lg/phase.md` |
| Phase marked `done` with closing tasks unchecked | Skipped the gate | Not done — finish both, then mark the phase |
