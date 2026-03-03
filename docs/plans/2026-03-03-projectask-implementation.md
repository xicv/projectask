# `projectask` Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a dual-mode Claude Code skill (slash command + auto-triggered) that transforms rough ideas into professional, engineering-level task markdown files.

**Architecture:** Two markdown files — a slash command at `~/.claude/commands/projectask.md` using `$ARGUMENTS` for user input, and an auto-triggered skill at `~/.claude/skills/projectask/SKILL.md`. Both contain Claude instructions for argument parsing, context gathering, task refinement, and file writing. No scripts or external dependencies.

**Tech Stack:** Claude Code skills system (SKILL.md frontmatter + markdown body), Claude Code commands system (`$ARGUMENTS`)

---

### Task 1: Create the Slash Command

**Files:**
- Create: `~/.claude/commands/projectask.md`

**Step 1: Create the command file**

Write `~/.claude/commands/projectask.md` with the following exact content:

```markdown
---
description: "Generate professional task files from rough ideas. Accepts optional path and task description."
---

# /projectask - Generate Professional Task Files

Transform rough ideas, descriptions, or feature requests into professional, engineering-level task markdown files ready for implementation.

## Usage

```
/projectask "task description"
/projectask path/to/dir "task description"
/projectask path/to/file.md "task description"
```

**Input:** $ARGUMENTS

---

## Step 1: Parse Arguments

Analyze `$ARGUMENTS` to extract two components:

1. **Output path** (optional): A file path or directory path
2. **Task description** (required): Everything else is the raw task idea

### Path Detection Rules

- If an argument looks like a file path ending in `.md` → use as the **exact output file path**
- If an argument looks like a directory path (contains `/`, no `.md` extension, looks like a path not prose) → use as the **output directory** with auto-increment naming
- If no path is detected → default output directory is `.vendor/`
- Quoted strings and remaining text = the **task description**

### Auto-Increment Naming

When using a directory (including the `.vendor/` default):

1. Run `ls` on the target directory to find existing `task*.md` files
2. Extract the highest number N from filenames like `task1.md`, `task2.md`, etc.
3. The new file is `task{N+1}.md`
4. If no `task*.md` files exist, start with `task1.md`
5. Create the directory if it does not exist (use `mkdir -p`)

## Step 2: Gather Project Context

Collect minimal project context to ground the task:

1. **Current working directory**: Note the full path from `pwd`
2. **Project name**: Read `package.json` (field `name`), `Cargo.toml` (field `name`), or fall back to the current directory basename
3. **CLAUDE.md**: If `./CLAUDE.md` exists in the project root, read it for project conventions and architecture notes. Do NOT include the full contents in the output — summarize relevant parts only.

## Step 3: Refine and Generate the Task File

Using the user's raw input and the gathered project context, generate a professional task file. Apply these refinement rules:

- Fix grammar and spelling in the user's description
- Expand vague ideas into specific, actionable requirements
- Add technical detail, edge cases, and implementation guidance
- Infer acceptance criteria from the requirements
- Add debugging hints and technical notes that would help another engineer or LLM execute this task without ambiguity
- Keep the tone professional and engineering-focused
- Do NOT pad with generic filler — every line should add value

### Output Template

Write the file using this exact structure:

```markdown
# Task: [Concise, Descriptive Title]

## Objective

[1-2 paragraphs describing what needs to be done and why. This should be a refined,
expanded version of the user's raw input. Include the business or technical motivation.]

## Context

- **Project:** [project name]
- **Working Directory:** [cwd]
- **Related Files:** [any files or paths mentioned by the user, or "N/A"]

## Requirements

- [ ] [Specific, actionable requirement 1]
- [ ] [Specific, actionable requirement 2]
- [ ] [Continue as needed — be thorough but not redundant]

## Acceptance Criteria

- [ ] [Measurable, verifiable criterion 1]
- [ ] [Measurable, verifiable criterion 2]
- [ ] [Continue as needed]

## Technical Notes

[Implementation hints, edge cases, constraints, architectural considerations,
or debugging guidance that would help execute this task accurately.
Reference specific files, APIs, or patterns from the project context if relevant.]
```

## Step 4: Write the File

1. Create the target directory if it does not exist (`mkdir -p`)
2. Write the generated content to the resolved file path using the Write tool
3. Report the file path to the user: "Task file created: `<path>`"
4. Show a brief summary of what was generated (title + number of requirements)
```

**Step 2: Verify the file was created**

Run: `cat ~/.claude/commands/projectask.md | head -5`
Expected: The frontmatter with `description:` field visible

**Step 3: Commit**

```bash
git add ~/.claude/commands/projectask.md
git commit -m "feat: add /projectask slash command for task file generation"
```

---

### Task 2: Create the Auto-Triggered Skill

**Files:**
- Create: `~/.claude/skills/projectask/SKILL.md`

**Step 1: Create the skill directory and file**

Create `~/.claude/skills/projectask/SKILL.md`. The SKILL.md shares the same core logic as the command but is formatted as a skill with proper frontmatter for auto-triggering:

```markdown
---
name: projectask
description: Generate professional, engineering-level task markdown files from rough ideas or descriptions. Use this skill when the user wants to create a task file, write a task specification, generate a requirements document, turn an idea into an actionable task, or asks to "write a task", "create a task file", "make a task spec", or "document this as a task". Also triggers when user says "projectask" or mentions generating implementation-ready task documentation.
---

# projectask — Professional Task File Generator

Transform rough ideas, descriptions, or feature requests into professional, engineering-level task markdown files ready for implementation by another engineer or LLM.

## When to Activate

- User wants to create a task file or specification
- User has a rough idea they want documented as an actionable task
- User says "write a task", "create a task file", "turn this into a task"
- User mentions "projectask" or task generation
- User provides a description and wants it saved as a structured task document

## Process

### 1. Identify Input

The user provides:
- A rough idea, description, or feature request (required)
- Optionally: a target file path (`.md`) or directory for the output

If no output path is specified, default to `.vendor/` with auto-increment naming (`task1.md`, `task2.md`, etc.).

If a directory is specified without a filename, auto-increment within that directory.

If an explicit `.md` path is provided, write to that exact location.

### 2. Auto-Increment File Naming

When writing to a directory (including `.vendor/` default):

1. List existing `task*.md` files in the target directory
2. Find the highest number N
3. Create `task{N+1}.md` (start at `task1.md` if none exist)
4. Create the directory with `mkdir -p` if it does not exist

### 3. Gather Project Context

Collect minimal context:

1. **Current working directory** (`pwd`)
2. **Project name** from `package.json`, `Cargo.toml`, or directory basename
3. **CLAUDE.md** contents if present (summarize, do not dump verbatim)

### 4. Refine and Generate

Transform the raw input into a professional task file:

- Fix grammar and spelling
- Expand vague ideas into specific, actionable requirements
- Add technical detail, edge cases, and implementation guidance
- Infer acceptance criteria
- Add debugging hints and technical notes
- Keep it professional — no filler, every line adds value

### 5. Output Template

Write the file with this structure:

```markdown
# Task: [Concise, Descriptive Title]

## Objective

[1-2 paragraphs: what needs to be done and why, refined from user input]

## Context

- **Project:** [project name]
- **Working Directory:** [cwd]
- **Related Files:** [mentioned files or "N/A"]

## Requirements

- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]

## Acceptance Criteria

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]

## Technical Notes

[Implementation hints, edge cases, constraints, debugging guidance]
```

### 6. Write and Report

1. Create target directory if needed (`mkdir -p`)
2. Write the content to the resolved path
3. Report: "Task file created: `<path>`"
4. Show brief summary (title + requirement count)
```

**Step 2: Verify the file was created**

Run: `ls ~/.claude/skills/projectask/SKILL.md`
Expected: File exists

**Step 3: Commit**

```bash
git add ~/.claude/skills/projectask/SKILL.md
git commit -m "feat: add projectask auto-triggered skill"
```

---

### Task 3: Test with Various Parameter Combinations

**Files:**
- None modified — testing only

**Step 1: Test default path (no path argument)**

Invoke: `/projectask "Create a new login page component with email and password fields"`

Expected:
- `.vendor/task1.md` created (or next auto-increment number)
- File contains structured template with all 5 sections
- Title is concise and descriptive
- Requirements are specific and actionable

**Step 2: Test with explicit directory**

Invoke: `/projectask src/frontend/auth "Implement JWT token refresh logic"`

Expected:
- `src/frontend/auth/task1.md` created
- Directory created if it didn't exist
- Context section references the project

**Step 3: Test with explicit filename**

Invoke: `/projectask docs/tasks/login-page.md "Create login component with OAuth integration"`

Expected:
- `docs/tasks/login-page.md` created at exact path
- No auto-increment — exact filename used

**Step 4: Test auto-increment**

Invoke: `/projectask "Second task in vendor"`

Expected:
- `.vendor/task2.md` created (since task1.md exists from Step 1)
- Number correctly incremented

**Step 5: Verify content quality**

Read the generated files and verify:
- [ ] Grammar and spelling are correct
- [ ] Requirements are specific, not vague
- [ ] Acceptance criteria are measurable
- [ ] Technical notes provide useful guidance
- [ ] Context section has correct project info
- [ ] No generic filler content

**Step 6: Commit test results (if any fixes were needed)**

```bash
git add -A
git commit -m "fix: adjust projectask skill based on test results"
```
