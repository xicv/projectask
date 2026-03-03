# projectasks

A Claude Code skill that transforms rough ideas into professional, engineering-level task markdown files.

## Features

- **Dual-mode:** Available as a slash command (`/projectask`) and as an auto-triggered skill
- **Flexible output paths:** Specify an exact file, a directory, or let it default to `.vendor/`
- **Auto-increment naming:** Automatically names files `task1.md`, `task2.md`, etc.
- **Project-aware:** Gathers context from `CLAUDE.md`, `package.json`, and `Cargo.toml`
- **Structured output:** Generates task files with Objective, Context, Requirements, Acceptance Criteria, and Technical Notes

## Usage

```bash
# Default output to .vendor/task1.md (auto-increments)
/projectask "Create a new login page component"

# Specify a directory (auto-increments within it)
/projectask src/frontend/auth "Implement JWT token refresh logic"

# Specify an exact file path
/projectask docs/tasks/login-page.md "Create login component with OAuth"
```

## Installation

Clone the repo and symlink into your `~/.claude` directory:

```bash
git clone https://github.com/xicv/projectasks.git ~/Projects/projectasks

# Symlink the slash command
ln -s ~/Projects/projectasks/commands/projectask.md ~/.claude/commands/projectask.md

# Symlink the auto-triggered skill
ln -s ~/Projects/projectasks/skills/projectask ~/.claude/skills/projectask
```

## Structure

```
projectasks/
├── commands/
│   └── projectask.md              # Slash command (/projectask)
├── skills/
│   └── projectask/
│       └── SKILL.md               # Auto-triggered skill
└── docs/
    └── plans/                     # Design and implementation docs
```

## Output Format

Generated task files follow this template:

```markdown
# Task: [Title]

## Objective
[Refined description of what needs to be done and why]

## Context
- **Project:** [project name]
- **Working Directory:** [cwd]
- **Related Files:** [referenced files or N/A]

## Requirements
- [ ] [Actionable requirement]

## Acceptance Criteria
- [ ] [Measurable criterion]

## Technical Notes
[Implementation hints, edge cases, debugging guidance]
```

## License

MIT
