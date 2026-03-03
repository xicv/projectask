# projectask

A Claude Code skill that transforms rough ideas into professional, engineering-level task markdown files with metadata tracking and lifecycle management.

## Features

- **Dual-mode:** Available as a slash command (`/projectask`) and as an auto-triggered skill
- **5-phase pipeline:** Parse → Analyze → Gather Context → Think & Generate → Verify & Write
- **YAML metadata:** Status, priority, timestamps, due dates, and tags in every task file
- **Smart file naming:** `task<NNN>-<kebab-slug>.md` with auto-increment and title-derived slugs
- **Project-aware:** Gathers context from `CLAUDE.md`, `package.json`, tech stack detection, and relevant source files
- **Rich output:** Objective, Context, Assumptions, Requirements, Acceptance Criteria, Out of Scope, Dependencies, Testing Strategy, and Technical Notes
- **Task lifecycle:** Create → Start → Done with `/projectask`, `/projectask-start`, `/projectask-done`
- **Task listing:** Query, filter, and summarize tasks with `/projectask-list`

## How It Works

The `/projectask` command runs a 5-phase pipeline:

1. **Parse** — Extract output path and task description from arguments
2. **Analyze** — Identify task type, check for ambiguity, assess scope
3. **Gather Context** — Read project config, CLAUDE.md, tech stack, relevant source files
4. **Think & Generate** — Use extended thinking to produce a self-contained, professional task spec
5. **Verify & Write** — Self-review for traceability, measurability, self-containment, and consistency before writing

## Commands

| Command | Description |
|---------|-------------|
| `/projectask` | Generate a new task file from a rough idea |
| `/projectask-list` | List, filter, sort, and summarize task files |
| `/projectask-start` | Mark a task as in-progress (sets `started` timestamp) |
| `/projectask-done` | Mark a task as done or update its status |

## Usage

```bash
# Create a task (default output to .projectasks/task001-login-page.md)
/projectask "Create a new login page component"

# Specify a directory
/projectask src/tasks "Implement JWT token refresh logic"

# Specify an exact file path
/projectask docs/tasks/login-page.md "Create login component with OAuth"

# List all tasks
/projectask-list

# List only in-progress tasks
/projectask-list --status in-progress

# Show summary overview
/projectask-list --summary

# Start working on a task
/projectask-start .projectasks/task001-login-page.md

# Mark a task as done
/projectask-done .projectasks/task001-login-page.md
```

## Installation

Clone the repo and symlink into your `~/.claude` directory:

```bash
git clone https://github.com/xicv/projectask.git ~/Projects/projectask

# Symlink the commands
ln -s ~/Projects/projectask/commands/projectask.md ~/.claude/commands/projectask.md
ln -s ~/Projects/projectask/commands/projectask-list.md ~/.claude/commands/projectask-list.md
ln -s ~/Projects/projectask/commands/projectask-start.md ~/.claude/commands/projectask-start.md
ln -s ~/Projects/projectask/commands/projectask-done.md ~/.claude/commands/projectask-done.md

# Symlink the auto-triggered skill
ln -s ~/Projects/projectask/skills/projectask ~/.claude/skills/projectask
```

## Structure

```
projectask/
├── commands/
│   ├── projectask.md              # Create task files (/projectask)
│   ├── projectask-list.md         # List and query tasks (/projectask-list)
│   ├── projectask-start.md        # Start a task (/projectask-start)
│   └── projectask-done.md         # Complete a task (/projectask-done)
├── skills/
│   └── projectask/
│       └── SKILL.md               # Auto-triggered skill
└── docs/
    └── plans/                     # Design and implementation docs
```

## Output Format

Generated task files include YAML frontmatter metadata and a rich template:

```markdown
---
status: todo
priority: medium
created: 2026-03-04T10:30:00
started:
completed:
due:
tags: [feature, auth]
---

# Task: Add User Authentication

## Objective
[Refined description of what needs to be done and why]

## Context
- **Project:** [project name]
- **Working Directory:** [cwd]
- **Tech Stack:** [detected stack]
- **Related Files:** [referenced files or N/A]

## Assumptions
[Inferred design decisions flagged for review]

## Requirements
- [ ] **[Title]**: [Description]. File: `path`. Reason: [why]

## Acceptance Criteria
- [ ] GIVEN [precondition], WHEN [action], THEN [result]

## Out of Scope
[What this task does NOT cover]

## Dependencies
[Prerequisites for starting this task]

## Testing Strategy
- **Unit tests:** [what and where]
- **Verification command:** `[exact command]`

## Technical Notes
[Implementation hints, edge cases, architectural guidance]
```

### Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | `todo`, `in-progress`, `blocked`, `done`, `cancelled` |
| `priority` | string | `critical`, `high`, `medium`, `low` |
| `created` | ISO 8601 | When the task was created |
| `started` | ISO 8601 | When work began (set by `/projectask-start`) |
| `completed` | ISO 8601 | When work finished (set by `/projectask-done`) |
| `due` | ISO 8601 | Deadline, if specified |
| `tags` | list | Categorization labels |

## License

MIT
