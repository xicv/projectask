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

The **first token** (whitespace-delimited) of `$ARGUMENTS` is treated as an output path only if it meets ANY of these criteria:
- Ends in `.md` → use as the **exact output file path**
- Starts with `/`, `./`, or `../` → use as the **output directory** with auto-increment naming
- Contains `/` and has no whitespace → use as the **output directory** with auto-increment naming

If the first token does not match any of the above, treat ALL of `$ARGUMENTS` as the **task description** and default the output directory to `.vendor/`.

### Auto-Increment Naming

When using a directory (including the `.vendor/` default):

1. Create the directory if it does not exist: `mkdir -p <target-dir>`
2. Run: `ls <target-dir>/task*.md 2>/dev/null`
3. For each matching filename, extract the integer N from the pattern `taskN.md`
4. Take the maximum integer found. If no files matched, set N = 0
5. The new file is `task{N+1}.md`

## Step 2: Gather Project Context

Collect minimal project context to ground the task:

1. **Current working directory**: Note the full path from `pwd`
2. **Project name**: Read `package.json` (field `name`), `Cargo.toml` (field `name`), or fall back to the current directory basename. If the project name cannot be meaningfully determined, use `Unknown`
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
