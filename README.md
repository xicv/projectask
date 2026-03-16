# projectask

A Claude Code plugin that transforms rough ideas into professional, engineering-level task markdown files with category organization, metadata tracking, and lifecycle management.

## Features

- **5-phase pipeline:** Parse → Analyze → Gather Context → Think & Generate → Verify & Write
- **Category support:** Organize tasks into category subdirectories (`feature/`, `bugfix/`, `refactor/`, etc.) with smart keyword detection and inference
- **YAML metadata:** Status, priority, category, timestamps, due dates, branch, and tags in every task file
- **Smart file naming:** `task<NNN>-<kebab-slug>.md` with auto-increment and title-derived slugs
- **Project-aware:** Gathers context from `CLAUDE.md`, `package.json`, tech stack detection, and relevant source files
- **Rich output:** Objective, Context, Assumptions, Requirements, Acceptance Criteria, Out of Scope, Dependencies, Testing Strategy, and Technical Notes
- **Task lifecycle:** Create → Start → Done (with git branch tracking)
- **Task listing:** Query, filter by status/priority/category/tag, sort, and summarize tasks
- **Auto-triggered:** Skill activates automatically when Claude detects task creation intent

## Commands

| Command | Description |
|---------|-------------|
| `/projectask:create` | Generate a new task file from a rough idea |
| `/projectask:list` | List, filter, sort, and summarize task files |
| `/projectask:start` | Mark a task as in-progress (sets `started` timestamp and git branch) |
| `/projectask:done` | Mark a task as done or update its status |

## Usage

### Creating tasks

```bash
# Create a task (default output to .projectasks/<category>/task001-<slug>.md)
/projectask:create "Create a new login page component"

# Specify category explicitly
/projectask:create --category feature "Add user authentication with OAuth"
/projectask:create -c bugfix "Fix the login redirect loop"

# Use category keyword as first word (smart detection)
/projectask:create feature "add login page with OAuth"
/projectask:create bugfix "fix the redirect loop on logout"
/projectask:create refactor "clean up the database layer"

# Category is inferred from description when not specified
/projectask:create "Fix the broken password reset flow"  # → bugfix/
/projectask:create "Add dark mode support"                # → feature/

# Specify a directory
/projectask:create src/tasks "Implement JWT token refresh logic"

# Specify an exact file path
/projectask:create docs/tasks/login-page.md "Create login component with OAuth"
```

### Listing tasks

```bash
# List all tasks (scans top-level and category subdirectories)
/projectask:list

# Filter by status
/projectask:list --status todo
/projectask:list --status in-progress

# Filter by category
/projectask:list --category feature
/projectask:list --category bugfix

# Filter by priority or tag
/projectask:list --priority high
/projectask:list --tag auth

# Combine filters
/projectask:list --status todo --category feature --priority high

# Show only the N most recent tasks
/projectask:list --latest 5

# Sort by different fields
/projectask:list --sort priority --order asc
/projectask:list --sort category
/projectask:list --sort due

# Scan a different directory
/projectask:list --dir src/tasks

# Show summary overview
/projectask:list --summary
```

### Starting tasks

```bash
# Start a specific task
/projectask:start .projectasks/feature/task001-login-page.md

# Auto-pick the latest todo task
/projectask:start --latest

# Interactive — lists todo tasks if multiple exist
/projectask:start
```

### Completing tasks

```bash
# Mark a task as done
/projectask:done .projectasks/feature/task001-login-page.md

# Auto-pick the latest in-progress task
/projectask:done --latest

# Set a specific status
/projectask:done .projectasks/bugfix/task002-redirect.md --status blocked
/projectask:done .projectasks/bugfix/task002-redirect.md --status cancelled

# Interactive — lists in-progress tasks if multiple exist
/projectask:done
```

## Installation

### Plugin (recommended)

Gives `/projectask:create`, `/projectask:list`, `/projectask:start`, `/projectask:done`:

```
/plugin marketplace add xicv/projectask
/plugin install projectask@xicv-projectask
```

### Symlink (alternative)

Also gives `/projectask:create`, `/projectask:list`, `/projectask:start`, `/projectask:done`:

```bash
git clone https://github.com/xicv/projectask.git ~/Projects/projectask
~/Projects/projectask/install.sh
```

To uninstall symlinks:

```bash
~/Projects/projectask/install.sh uninstall
```

## How It Works

The create command runs a 5-phase pipeline:

1. **Parse** — Extract output path, category, and task description from arguments
2. **Analyze** — Identify task type, infer category if not explicit, check for ambiguity, assess scope
3. **Gather Context** — Read project config, CLAUDE.md, tech stack, relevant source files
4. **Think & Generate** — Use extended thinking to produce a self-contained, professional task spec
5. **Verify & Write** — Self-review for traceability, measurability, self-containment, and consistency before writing

### Category System

Tasks are organized into category subdirectories for better organization:

```
.projectasks/
├── feature/
│   ├── task001-add-login-page.md
│   └── task002-add-dark-mode.md
├── bugfix/
│   ├── task001-fix-redirect-loop.md
│   └── task002-fix-password-reset.md
├── refactor/
│   └── task001-clean-database-layer.md
└── docs/
    └── task001-update-api-docs.md
```

Categories can be specified three ways (in priority order):
1. **Explicit flag**: `--category feature` or `-c feature`
2. **Keyword match**: First word of description matches a known category (e.g., `feature`, `bugfix`, `fix`, `refactor`)
3. **Inferred**: Automatically determined from the task description during analysis

#### Known Category Keywords

| Keywords | Canonical Category |
|----------|-------------------|
| `feature`, `feat` | `feature` |
| `bugfix`, `bug`, `fix` | `bugfix` |
| `refactor`, `refac` | `refactor` |
| `docs`, `doc`, `documentation` | `docs` |
| `test`, `testing` | `test` |
| `chore` | `chore` |
| `infra`, `infrastructure` | `infrastructure` |
| `perf`, `performance` | `performance` |
| `security`, `sec` | `security` |
| `style`, `ui`, `design` | `ui` |
| `ci`, `cd`, `devops` | `devops` |
| `spike`, `research` | `research` |

## Structure

```
projectask/
├── .claude-plugin/
│   ├── plugin.json                # Plugin manifest
│   └── marketplace.json           # Marketplace distribution
├── install.sh                     # Installer (symlinks skills)
├── skills/
│   ├── create/
│   │   └── SKILL.md               # Create task files (auto-triggered)
│   ├── list/
│   │   └── SKILL.md               # List and query tasks
│   ├── start/
│   │   └── SKILL.md               # Start a task
│   └── done/
│       └── SKILL.md               # Complete a task
├── commands/                      # Legacy command files
│   ├── create.md
│   ├── list.md
│   ├── start.md
│   └── done.md
└── docs/
    └── plans/                     # Design and implementation docs
```

## Output Format

Generated task files include YAML frontmatter metadata and a rich template:

```markdown
---
status: todo
priority: medium
category: feature
created: 2026-03-04T10:30:00
started:
completed:
due:
branch:
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
- **Integration tests:** [if applicable]
- **Verification command:** `[exact command]`

## Technical Notes
[Implementation hints, edge cases, architectural guidance]
```

### Metadata Fields

| Field | Type | Description | Filterable |
|-------|------|-------------|------------|
| `status` | string | `todo`, `in-progress`, `blocked`, `done`, `cancelled` | `--status` |
| `priority` | string | `critical`, `high`, `medium`, `low` | `--priority` |
| `category` | string | Task category (e.g., `feature`, `bugfix`, `refactor`) | `--category` |
| `created` | ISO 8601 | When the task was created | `--sort created` |
| `started` | ISO 8601 | When work began (set by start command) | — |
| `completed` | ISO 8601 | When work finished (set by done command) | — |
| `due` | ISO 8601 | Deadline, if specified | `--sort due` |
| `branch` | string | Git branch name (set by start command) | — |
| `tags` | list | Categorization labels | `--tag` |

### List Flags

| Flag | Short | Values | Default | Description |
|------|-------|--------|---------|-------------|
| `--status` | `-s` | `todo`, `in-progress`, `blocked`, `done`, `cancelled` | all | Filter by status |
| `--priority` | `-p` | `critical`, `high`, `medium`, `low` | all | Filter by priority |
| `--category` | `-c` | any category name | all | Filter by category |
| `--tag` | `-t` | any string | all | Filter by tag |
| `--latest` | `-l` | integer N | all | Show only N most recent tasks |
| `--sort` | | `created`, `priority`, `status`, `due`, `category` | `created` | Sort field |
| `--order` | | `asc`, `desc` | `desc` | Sort direction |
| `--dir` | `-d` | directory path | `.projectasks/` | Base directory to scan |
| `--summary` | | flag | off | Show high-level summary |

### Done Statuses

| Status | Effect |
|--------|--------|
| `done` (default) | Sets `completed` timestamp |
| `in-progress` | Sets `started` timestamp and `branch` |
| `blocked` | Marks as blocked |
| `cancelled` | Sets `completed` timestamp |
| `todo` | Resets to todo, clears timestamps and branch |

## License

MIT
