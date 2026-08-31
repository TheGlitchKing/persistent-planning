---
name: plan-status
description: "Show completion status for every plan under .planning/ — which are in progress, blocked, or complete and ready to archive. Works in both sm and lg mode."
---

# /plan-status

Report where every plan stands. Completion is derived from the plan artifacts
themselves (checkbox state + frontmatter `status:`), so it cannot drift away from
what the plan actually says.

---

## Usage

```
/plan-status
```

## What To Do

Run the status script:

```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/../scripts"
bash "${SCRIPT_DIR}/plan-status.sh"
```

If the script isn't found at that path, try in order:

```bash
bash scripts/plan-status.sh
bash ~/.claude/skills/persistent-planning/scripts/plan-status.sh
```

Then read the table back to the user. If any plan is listed `COMPLETE`, offer to
archive it with `/archive-plan <slug>`.

## Verdicts

| Verdict | Meaning |
|---|---|
| `in progress` | Unchecked boxes remain |
| `blocked` | An atom in the plan carries `status: blocked` |
| `COMPLETE` | Every box checked, or the top-level artifact says `status: done` — ready to archive |
| `empty` | Plan artifact exists but has no checkboxes yet |
| `archived` | Already retired (only visible if left in the active tree) |

## Machine-readable forms

```bash
bash scripts/plan-status.sh --complete   # one complete plan slug per line
bash scripts/plan-status.sh --nudge      # one-line notice, or silence
```

`--nudge` is what the SessionStart hook uses, so a finished plan gets mentioned
at the top of the next session rather than being rediscovered later.

## See also

- `/archive-plan` — retire a completed plan into `.planning/.archive/`
- `.documentation/procedures/plan-completion-and-archive.md` — the full completion protocol
