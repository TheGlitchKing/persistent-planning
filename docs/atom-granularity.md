---
title: Atom Granularity (anti-pattern guide)
tier: standard
domains:
  - planning
status: active
last_updated: 2026-05-07
version: 1.0.0
audience:
  - developers
purpose: When to spawn a standalone atom file vs. add an inline atom checkbox to task.md. The atom layer is load-bearing for subagent hand-off; this doc keeps it from being misused.
---

# Atom Granularity

This is anti-pattern guidance for **lg-mode** planning. Sm-mode users can ignore this — sm has only `task_plan.md` with inline checkboxes throughout.

## The two kinds of atoms

In lg mode, "atom" can mean two different artifacts:

1. **Inline atom checkbox** in `task.md`:
   ```markdown
   ## Atoms
   - [ ] Bump version to 3.0.0 in package.json
   - [ ] Update CHANGELOG entry
   - [ ] Run npm publish
   ```

2. **Standalone atom file** at `.planning/<phase>/<task>/atoms/<atom-slug>.md`:
   ```markdown
   ---
   title: Bump version to 3.0.0
   tier: plan
   plan_kind: atom
   parent: release-3-0-0
   sequence: 1
   status: ready
   ---

   # Atom: Bump version to 3.0.0

   ## What to do
   ...
   ## Inputs
   ...
   ## Expected outputs
   ...
   ## Acceptance criteria
   ...
   ```

Both are valid. The question is **when to use which**.

## The rule

**Inline checkbox**: simple, self-contained step that doesn't need its own context file.
The active agent handles it directly while working through the task.

**Standalone atom file**: a step that will be **handed off to a subagent**.
Subagents need explicit inputs / outputs / acceptance criteria they can read
structured rather than parse from prose. Standalone atoms exist to make the
hand-off contract explicit and machine-readable.

## Examples

### ✅ Use inline checkbox

```markdown
## Atoms
- [ ] Bump package.json to 3.0.0
- [ ] Add CHANGELOG entry under "## [3.0.0]"
- [ ] Run `npm test` and confirm all pass
```

These are mechanical, self-evident, and don't need their own files. The active
agent reads task.md, executes them, and ticks them off.

### ✅ Use standalone atom file

```markdown
## Atoms
(see atoms/ for files)
```

With:

```
atoms/
├── 01-extract-embedder-to-shared-package.md
├── 02-refactor-vault-indexer-to-registry-driven.md
└── 03-add-corpora-json-schema.md
```

Each of these is a meaty, multi-step refactor with non-obvious context (which
files to touch, what shape the resulting code should take, how to verify).
Subagents picking these up need explicit briefing — that's what the standalone
atom file provides.

## Anti-patterns

### 🚫 Standalone atom for a one-liner

If the atom file ends up being mostly empty (`## What to do` is one sentence,
`## Acceptance criteria` is "ran the command"), it's overhead. Use an inline
checkbox.

### 🚫 Inline checkboxes for multi-step subagent work

If the checkbox is `- [ ] Refactor the indexer to support multi-corpus`, you've
pushed too much into one inline checkbox. A subagent picking up "refactor the
indexer" has no idea what scope, what files, or what success looks like. Spawn
a standalone atom (or several — one per logical refactor step).

### 🚫 Mixing — inline checkboxes that are subagent hand-offs

Don't have inline checkboxes that say "subagent: do X" without an atom file.
Either it's small enough for the active agent (inline) or it's big enough for
hand-off (atom file). The line between them is "is the subagent going to need
to ask questions?"

## Heuristic

Ask: **could a fresh subagent walk into this and complete the work without
asking the user a clarifying question?**

- If yes → inline checkbox is fine
- If no → spawn an atom file with explicit Inputs / Outputs / Acceptance
  criteria

## Sequence semantics

Standalone atoms have explicit `sequence:` ordering. The planning MCP's
`next_atom(task)` verb returns the next `status: ready` atom in sequence order.

Sequential matches the single-agent reality. If you have N atoms in a task,
they hand off one at a time, in order. This eliminates filesystem race
conditions on claim and matches how agentic coding actually flows today.

If you have a genuinely parallel-atom workload (multiple subagents working
simultaneously on independent atoms within one task), that's a Phase 4.x
conversation — today, atoms hand off one at a time.

## Reopen semantics

A `done` atom can be reopened to `in_progress` if a follow-up correction is
needed. The frontmatter gets a `reopened_at: <iso-timestamp>` audit field.
Don't use this for "the work was wrong, redo it" — for that, the cleaner move
is to add a NEW atom that explains what to fix and why. Reopening is for "this
was almost done but missed a small detail."

## See also

- `/start-atom` — slash command to spawn a standalone atom file
- `templates/lg/atom.md` — the atom file template
- `templates/lg/task.md` — the task template (inline checkbox section)
