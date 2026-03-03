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

#### Path Detection Rules

Treat the first distinct token of the user's input as an output path only if it meets ANY of these criteria:
- Ends in `.md` → use as the **exact output file path**
- Starts with `/`, `./`, or `../` → use as the **output directory** with auto-increment naming
- Contains `/` and has no whitespace → use as the **output directory** with auto-increment naming

If the first token does not match any of the above, treat ALL input as the **task description** and default the output directory to `.vendor/`.

### 2. Auto-Increment File Naming

When writing to a directory (including `.vendor/` default):

1. Create the directory if it does not exist: `mkdir -p <target-dir>`
2. Run: `ls <target-dir>/task*.md 2>/dev/null`
3. For each matching filename, extract the integer N from the pattern `taskN.md`
4. Take the maximum integer found. If no files matched, set N = 0
5. The new file is `task{N+1}.md`

### 3. Gather Project Context

Collect minimal context:

1. **Current working directory** (`pwd`)
2. **Project name** from `package.json`, `Cargo.toml`, or directory basename. If the project name cannot be meaningfully determined, use `Unknown`
3. **CLAUDE.md** contents if present (summarize, do not dump verbatim)

### 4. Refine and Generate

Transform the raw input into a professional task file:

- Fix grammar and spelling
- Expand vague ideas into specific, actionable requirements
- Add technical detail, edge cases, and implementation guidance
- Infer acceptance criteria from the requirements
- Add debugging hints and technical notes that would help another engineer or LLM execute this task without ambiguity
- Keep the tone professional and engineering-focused
- Do NOT pad with generic filler — every line should add value

### 5. Output Template

Write the file with this structure:

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

### 6. Write and Report

1. Create target directory if needed (`mkdir -p`)
2. Write the content to the resolved path using the Write tool
3. Report: "Task file created: `<path>`"
4. Show brief summary (title + requirement count)
