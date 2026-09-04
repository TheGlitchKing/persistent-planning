---
title: '`mandatory:` task frontmatter'
tier: reference
domains:
  - reference
audience:
  - developers
tags: []
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: >-
  Contract for the mandatory: task frontmatter field — who sets it, what reads it, and
  why absent must mean no enforcement for legacy plans.
estimated_read_time: 2 minutes
word_count: 270
last_validated: '2026-09-04'
backlinks: []
---

# `mandatory:` task frontmatter

A boolean in an lg task's frontmatter marking it as one of the phase's mandatory
closing tasks. It is what turns "a phase cannot be done until both closers are done"
from a sentence in a template into something `plan-status.sh` enforces.

```yaml
---
title: Validate success through comprehensive testing
plan_kind: task
status: draft
depends_on: []
parallelizable: false
mandatory: true
---
```

## Contract

| | |
|---|---|
| **Lives in** | `<phase>/<task>/task.md` frontmatter |
| **Default** | `false` — `templates/lg/task.md` ships it explicitly |
| **Set to `true` by** | `init-phase.sh`, on the two scaffolded closers only |
| **Read by** | `scripts/plan-status.sh` (`unfinished_mandatory()`) |
| **Effect** | a plan with any `mandatory: true` task whose `status` is neither `done` nor `archived` cannot read `COMPLETE`, however the checkboxes add up |
| **Absent means** | no enforcement — legacy behavior, exactly as before |

## Why absent must mean "no enforcement"

Plans created before 3.3.0 have no closer directories and no `mandatory:` frontmatter.
Treating absence as `true`, or inferring closers by title, would retroactively reopen
finished plans — worse than the bug this field fixes. The gate is strictly additive and
the test suite asserts a legacy plan still reads `COMPLETE`.

## Where it is enforced — once

`plan-status.sh` is the single implementation of "is this plan done?" per `CLAUDE.md`.
`archive-plan.sh` inherits the gate through its existing pre-flight call rather than
carrying a second copy of the rule, and `--complete` / `--nudge` — which the
SessionStart hook and `archive-plan.sh` consume — honour it too.

Ticking a checkbox is **not** sufficient for a mandatory task. The task's own `status:`
must be `done`. That distinction is the whole point: a closer that was ticked but never
performed is exactly the failure this guards.

## Related

- [lg plan artifact lifecycle](../architecture/lg-plan-artifact-lifecycle.md)
- [Plan completion and archive](../procedures/plan-completion-and-archive.md)
- [Plan never reads complete](../troubleshooting/plan-never-reads-complete.md)
