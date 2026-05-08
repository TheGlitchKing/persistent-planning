---
title: workspace.json schema
tier: standard
domains:
  - planning
status: active
last_updated: 2026-05-07
version: 1.0.0
audience:
  - developers
purpose: Document the .planning/.meta/workspace.json schema introduced in v3.0 for sm/lg mode tracking
---

# `workspace.json` schema (v3.0)

Introduced in persistent-planning **3.0.0**. Tracks per-project planning mode and
detection state. Lives at `.planning/.meta/workspace.json`.

## Schema

```json
{
  "schema_version": "1.0",
  "mode": "sm" | "lg",
  "auto_detected": true | false,
  "detected_contributors": <integer>,
  "created_at": "<ISO 8601 timestamp>"
}
```

## Field reference

| Field | Type | Required | Description |
|---|---|---|---|
| `schema_version` | string | yes | Schema version of this file. Currently `"1.0"`. |
| `mode` | `"sm"` \| `"lg"` | yes | Active planning mode for this project. |
| `auto_detected` | boolean | yes | `true` if mode was determined by the heuristic, `false` if explicitly set via `--mode`. |
| `detected_contributors` | integer | yes (when `auto_detected=true`) | Distinct git author email count over the last 90 days at detection time. |
| `created_at` | string (ISO 8601) | yes | When this workspace.json was first written. |

## Mode determination

`detect-mode.sh` resolves the active mode using this precedence (first match wins):

1. **Explicit override**: if `workspace.json` exists with a `"mode"` field, that value wins.
2. **Auto-detect**: count distinct git author emails over the last 90 days. ≥ 2 → `"lg"`. Otherwise → `"sm"`.
3. **Fallback**: if neither applies (no git repo, git fails), default to `"sm"`.

The override is sticky — once written, future runs read `workspace.json` and skip
re-detection. Override the override by editing `workspace.json` directly or by passing
`--mode sm` / `--mode lg` to `/start-planning` (which rewrites the file).

## Mode behavior

### `sm` (small / solo)
- Single-task model — `.planning/<task-slug>/{task_plan.md, notes.md}`
- Identical to v2 behavior; existing v2 plans continue to work without migration
- No HEWTD frontmatter on plans (frontmatter is plain text)
- Single slash command: `/start-planning "Task name"`

### `lg` (large / team)
- Layered model: phase → task → atom + cross-cutting notes
- Directory layout: `.planning/<phase-slug>/<task-slug>/{task.md, notes.md, atoms/<atom-slug>.md}`
- HEWTD frontmatter on every layer (`tier: plan`, conditionally version-exempt per HEWTD 2.2.0)
- Three slash commands: `/start-planning` (phase), `/start-task --parent <phase>`, `/start-atom --parent <task>`
- Sequential atom hand-offs; tasks can declare `depends_on` + `parallelizable` for subagent team scheduling

## Backwards compatibility

Existing `.planning/<task-slug>/` folders without `.meta/` continue to work as `sm`.
Mode detection only writes `workspace.json` when `/start-planning` is run after v3.0
upgrade — pure read operations don't trigger writes.

## Manual editing

Safe to edit by hand. Common changes:

- Switch mode: change `"mode"`, set `"auto_detected": false`
- Reset auto-detection: delete the file; the next `/start-planning` will re-detect

## See also

- `scripts/detect-mode.sh` — the resolution logic
- `templates/lg/{phase,task,atom,notes}.md` — frontmatter shape per layer
- `~/workspace/the-glitch-kingdom/persistent-planning/.planning/layered-planning-with-mcp-and-hewtd-frontmatter/task_plan.md` — the meta-plan that drove this design
