# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-02-12

### Added
- Core skill definition (`skills/SKILL.md`) with persistent markdown-based planning
- `/start-planning` slash command for one-command setup
- `init-planning.sh` script for automated `.planning/` directory creation
- Task-specific subdirectories (`.planning/[task-slug]/`)
- `task_plan.md` and `notes.md` templates
- Multiple concurrent task support
- Reference documentation on Manus context engineering principles
- Worked examples for research, bug fix, and feature development workflows
- `install.sh` installer with user/project scope support
- `uninstall.sh` for clean removal
- Plugin manifest files for marketplace compatibility

### Based On
- Context engineering principles from [Manus AI](https://manus.im/de/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- Original [planning-with-files](https://github.com/OthmanAdi/planning-with-files) skill by Ahmad Othman Ammar Adi
