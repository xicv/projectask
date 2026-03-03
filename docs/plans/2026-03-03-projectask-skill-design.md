# Design: `projectask` Claude Code Skill

**Date:** 2026-03-03
**Status:** Approved

## Overview

A dual-mode Claude Code skill that accepts rough ideas/descriptions from the user and generates professional, engineering-level task markdown files. Available both as a slash command (`/projectask`) and as an auto-triggered skill.

## File Structure

```
~/.claude/commands/projectask.md      # Slash command (user-invoked)
~/.claude/skills/projectask/SKILL.md  # Auto-triggered skill
```

## Architecture: Pure Markdown (No Scripts)

All logic is expressed as Claude instructions in markdown. Claude handles:
- Argument parsing (natural language extraction)
- Path resolution and auto-increment file naming
- Context gathering (cwd, CLAUDE.md)
- Task refinement (inline LLM processing)
- File writing (via Write tool)

## Argument Parsing

**Input format:** `/projectask [optional-path] "task description"`

### Rules

1. If `$ARGUMENTS` contains a path ending in `.md` — explicit output file path
2. If `$ARGUMENTS` contains a directory path (no `.md`) — use that directory with auto-increment naming
3. If no path detected — default to `.vendor/` directory with auto-increment
4. Everything else = task description/context

### Auto-Increment Logic

- List files in target directory matching `task*.md`
- Find highest number N
- Create `task{N+1}.md`

### Examples

```
/projectask "Create login page"
→ .vendor/task1.md (or task2.md if task1 exists)

/projectask src/frontend/auth "Implement JWT refresh"
→ src/frontend/auth/task1.md

/projectask custom-task.md "Fix failing tests"
→ custom-task.md

/projectask docs/tasks/login-page.md "Create login component"
→ docs/tasks/login-page.md
```

## Context Gathering (Minimal)

1. **Current working directory** — `pwd`
2. **CLAUDE.md** — Read `./CLAUDE.md` if present
3. **Project name** — From directory name or package.json/Cargo.toml

## Task Refinement

Claude processes the raw input with this guidance:

> Take the user's rough idea and project context. Fix grammar and spelling. Expand the description with additional technical detail, acceptance criteria, and implementation guidance. Output a highly professional, engineering-level task file that another engineer or LLM can execute without ambiguity.

## Output Template

```markdown
# Task: [Concise Title]

## Objective
[1-2 paragraph refined description of what needs to be done and why]

## Context
- **Project:** [project name]
- **Working Directory:** [cwd]
- **Related Files:** [if mentioned by user]

## Requirements
- [ ] Specific, actionable requirement 1
- [ ] Specific, actionable requirement 2

## Acceptance Criteria
- [ ] Measurable criterion 1
- [ ] Measurable criterion 2

## Technical Notes
[Implementation hints, edge cases, constraints, or debugging guidance]
```

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skill type | Both command + skill | Explicit invocation + auto-detection |
| LLM engine | Current Claude session | No external API, simpler, keeps context |
| Context level | Minimal (cwd + CLAUDE.md) | Fast, low noise |
| Output format | Structured template | Consistent, actionable |
| Implementation | Pure markdown, no scripts | Matches existing patterns |
