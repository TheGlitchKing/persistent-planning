---
title: Documentation pass create update deprecate docs
tier: plan
domains:
  - planning
status: ready
last_updated: "2026-09-04"
plan_kind: task
parent: make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12
depends_on: [validate-success-through-comprehensive-testing]
parallelizable: false
---

# Task: Documentation pass create update deprecate docs

**Phase**: `make-lg-task-lists-self-maintaining-and-closers-enforceable-issue-12`

## Goal
Every behavior this phase changes is captured in `.documentation/` — what it is, where it lives, how to troubleshoot it, why it matters — through hit-em-with-the-docs, with indexes regenerated and zero audit errors.

## Atoms

### Create

- [ ] `.documentation/architecture/lg-plan-artifact-lifecycle.md` — who writes what: `init-phase.sh` scaffolds the phase and both closers, `init-task.sh` writes the task and its line in `phase.md`, `init-atom.sh` writes the atom and its line in `task.md`. The insertion rule (above MANDATORY, anchored on the marker, never on line numbers) belongs here
- [ ] `.documentation/reference/mandatory-frontmatter.md` — the `mandatory: true` field: who sets it, what reads it, what absent means for legacy plans
- [ ] `.documentation/troubleshooting/plan-never-reads-complete.md` — the symptom someone will actually hit: a plan stuck below 100% (a stale placeholder checkbox, or an unfinished mandatory closer), how to tell which, and what to do

### Update

- [ ] `.documentation/standards/mandatory-closing-phases.md` — the closers are real task directories now, and the ordering holds by construction; update the "how to operate it" section
- [ ] `.documentation/procedures/plan-completion-and-archive.md` — completion now gates on `mandatory: true`, not on box count alone
- [ ] `.documentation/architecture/lg-mode.md` — cross-link the artifact lifecycle doc
- [ ] `.documentation/testing/test-suite.md` — record the assert-after-mutation rule and why render-time assertions missed this
- [ ] `CLAUDE.md` — the init scripts now maintain their parent's list; note it beside the existing layer-vocabulary and completion paragraphs
- [ ] `CHANGELOG.md` entry

### Deprecate / retire

- [ ] Audit for any doc that describes the task list as hand-maintained, or the closers as checkbox-only, and retire it with `npx hewtd archive <file>` — never by deleting
- [ ] Check whether `.documentation/standards/atom-granularity.md` still reads correctly now that closers are real dirs

### Verify

- [ ] **hit-em-with-the-docs is installed here, so this pass MUST go through it**: `npx hewtd integrate <file> -a` to create, `npx hewtd archive <file>` to retire, `npx hewtd maintain --quick` to regenerate
- [ ] `npx hewtd audit` — resolve every error; check the frontmatter `purpose:` values are valid YAML (an unquoted colon broke the audit last phase)
- [ ] Every new doc reachable from its domain INDEX and present in REGISTRY
- [ ] Never hand-edit `INDEX.md` / `REGISTRY.md` — generated, guarded, and overwritten
- [ ] Close the loop on issue #12 with a pointer to the lifecycle doc

## Decisions Made

**The troubleshooting doc is the one someone will actually search for.** "My plan won't
read COMPLETE" is the symptom; placeholder checkboxes and unfinished mandatory closers are
two different causes with two different fixes. That page earns its place more than either
architecture doc.

**Write down who owns each artifact.** The bug existed because nothing stated that
`phase.md`'s task list was supposed to be maintained by anyone. An explicit
ownership table is the durable fix for that class of confusion.

**hewtd is mandatory here, not optional.** It is installed in this repo, so per the
phase template's own rule this pass goes through it.

## Status
**Currently ready** — MANDATORY, last. Blocked on validation.

Status enum: `draft | active | paused | done | archived`

## Dependencies
Declared in `depends_on:` above.

---

## Layer reference
- **Phase** (`../phase.md`): the strategic grouping this task belongs to
- **This task**: the bounded deliverable
- **Atoms** (`atoms/<atom-slug>.md`): subagent hand-off units (sequential within this task)
- **Notes** (`notes.md`): cross-cutting references for this task's implementation
