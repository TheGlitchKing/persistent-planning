---
title: ATOM_TITLE_PLACEHOLDER
tier: plan
domains:
  - planning
status: ready
last_updated: "ATOM_DATE_PLACEHOLDER"
plan_kind: atom
parent: TASK_SLUG_PLACEHOLDER
sequence: ATOM_SEQUENCE_PLACEHOLDER
---

# Atom: ATOM_TITLE_PLACEHOLDER

**Task**: `TASK_SLUG_PLACEHOLDER`
**Sequence**: `ATOM_SEQUENCE_PLACEHOLDER` (atoms within a task are processed sequentially)

## What to do
[Describe the atomic action a subagent should take. Single focused step. If the work
spans more than one logical operation, split into multiple atoms with sequential ordering.

This file IS the contract a subagent reads to know exactly what to do. Be specific.]

## Inputs
[Files, data, or prior atom outputs this atom depends on.]

## Expected outputs
[Files modified, files created, commands run, or state changed.]

## Acceptance criteria
[How a subagent (or human reviewer) confirms this atom is done. Should be concrete
and verifiable.]

## Status
**Currently ready** — waiting for a subagent to claim it.

Status enum: `ready | in_progress | done | blocked`

Status transitions:
- `ready → in_progress`: a subagent claims this atom
- `in_progress → done`: the subagent completes the work and verifies acceptance criteria
- `in_progress → blocked`: the subagent hits an obstacle (add a note explaining why
  in a `## Blocker` section)
- `done → in_progress` (reopen): allowed when a follow-up correction is needed; adds
  `reopened_at: <iso-timestamp>` field to frontmatter for audit
