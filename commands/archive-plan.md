---
name: archive-plan
description: "Retire a completed plan into the gitignored .planning/.archive/ directory. Refuses to archive a plan that still has unchecked boxes unless --force is passed. Works in both sm and lg mode."
---

# /archive-plan

Move a finished plan out of the active tree so `.planning/` only ever shows work
that is still live. Nothing is deleted — archiving is a move plus a status stamp,
and is reversed by moving the directory back.

---

## Usage

```
/archive-plan <plan-slug>
/archive-plan --all-complete
/archive-plan <plan-slug> --force      # archive a plan that is not finished
/archive-plan <plan-slug> --dry-run
```

## What To Do

When the user runs `/archive-plan`:

1. Run the script:

```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/../scripts"
bash "${SCRIPT_DIR}/archive-plan.sh" "<plan-slug>"
```

If the script isn't found at that path, try in order:

```bash
bash scripts/archive-plan.sh "<plan-slug>"
bash ~/.claude/skills/persistent-planning/scripts/archive-plan.sh "<plan-slug>"
```

2. If the script refuses because the plan is incomplete, **do not reach for
   `--force` on your own.** Run `/plan-status`, tell the user what is still
   unchecked, and let them decide.

## What it does

1. Verifies the plan is complete (every checkbox checked, or `status: done`).
2. Ensures `.planning/.archive/` exists and is listed in `.gitignore` — completed
   plans are local history, not something every clone carries.
3. Moves `.planning/<slug>/` to `.planning/.archive/<slug>/`, using `git mv` when
   the plan is tracked so history follows it.
4. Stamps the plan's top-level artifact: `status: archived` plus `archived_on`
   (frontmatter), or a dated footer for sm plans that have no frontmatter.

## Restoring

```bash
mv .planning/.archive/<slug> .planning/<slug>
```

Then set `status:` back to `active` and drop the `archived_on` stamp.

## See also

- `/plan-status` — see which plans are complete
- `.documentation/procedures/plan-completion-and-archive.md` — the full completion protocol
