---
title: A plan won't read COMPLETE
tier: guide
domains:
  - troubleshooting
audience:
  - developers
tags: []
status: active
last_updated: '2026-09-04'
version: 1.0.0
purpose: >-
  Three reasons a plan will not read COMPLETE — an unfinished mandatory closer, a
  placeholder counted as work, or a blocked artifact — and the fix for each.
estimated_read_time: 2 minutes
word_count: 264
last_validated: '2026-09-04'
backlinks: []
---

# A plan won't read COMPLETE

`/plan-status` shows a plan stuck below 100%, or at `100%` but still `in progress`,
and it is not obvious what is outstanding. There are three causes with three
different fixes.

## 1. Every box is ticked but it still says `in progress`

```
my-phase        in progress   13/13 boxes
```

A **mandatory closing task is not done.** Ticking its checkbox in `phase.md` is not
enough — the closer's own `task.md` must carry `status: done`.

```bash
grep -l '^mandatory: true' .planning/my-phase/*/task.md | xargs grep -H '^status:'
```

Anything not `done` or `archived` is what is holding the plan open. Finish the work,
then set `status: done` in that task's frontmatter.

This is deliberate. A closer that was ticked but never performed is precisely the
failure the gate exists to catch — see
[`mandatory:` frontmatter](../reference/mandatory-frontmatter.md).

## 2. The count includes a box that isn't work

```
my-phase        in progress   0/5 boxes     # but only 2 real tasks exist
```

Older plans carry the placeholder lines as **checkboxes**:

```markdown
- [ ] (no tasks yet — run `/start-task …`)
- [ ] (no atoms yet — add inline checkboxes here for simple atoms,
      or run `/start-atom …` for complex ones)
```

`plan-status.sh` counts every `- [ ]` under a plan, so those inflate the total and the
plan cannot finish until someone ticks a line that says nothing exists.

**Fix:** delete the placeholder line, or add a real task/atom — from 3.3.0 the init
scripts remove it automatically on first insert. New plans ship the placeholders as
italic text, which is not counted.

## 2b. Quoted markdown used to count (fixed in 3.3.1)

Before 3.3.1, three readers scanned whole files: the checkbox counter, the mandatory
gate, and blocked detection. A `notes.md` that merely *documented* the contract tripped
all three — a fenced `- [ ]` example inflated the denominator, a fenced `mandatory: true`
held the plan open with the box count reading a perfect `n/n`, and a fenced
`status: blocked` produced a false `blocked` verdict.

Frontmatter fields are now read from frontmatter only, and checkbox counting skips fenced
code blocks. If you are on an older version, move the example out of the plan or upgrade.

## 3. Something under the plan is `status: blocked`

```
my-phase        blocked       7/20 boxes
```

`plan-status.sh` reports `blocked` when any artifact under the plan has
`status: blocked`. Find it:

```bash
grep -rl '^status: blocked' .planning/my-phase/
```

That is a report, not a defect — the plan is telling you what it is waiting on.

## Checking the whole picture

```bash
bash scripts/plan-status.sh            # table: in progress / blocked / COMPLETE / empty
bash scripts/plan-status.sh --complete # one complete slug per line, for scripts
```

`archive-plan.sh` refuses an incomplete plan using the same check, so anything above
that blocks COMPLETE also blocks archiving. `--force` overrides it; nothing is ever
deleted either way.

## Related

- [Plan completion and archive](../procedures/plan-completion-and-archive.md)
- [lg plan artifact lifecycle](../architecture/lg-plan-artifact-lifecycle.md)
- [Mandatory closing phases](../standards/mandatory-closing-phases.md)
