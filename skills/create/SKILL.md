---
name: create
description: Generate professional, LLM-executable task markdown files from rough ideas or descriptions. Use this skill when the user wants to create a task file, write a task specification, generate a requirements document, turn an idea into an actionable task, or asks to "write a task", "create a task file", "make a task spec", "document this as a task", or "turn this into an implementation spec". Also triggers when user says "projectask" or mentions generating implementation-ready task documentation. Do NOT use for general conversation about tasks or project management — only when the user wants a task file written to disk.
argument-hint: [path] [--category <cat>] "task description"
allowed-tools: Read, Grep, Glob, Bash(mkdir *), Bash(ls *), Bash(pwd), Write
---

# projectask — Professional Task File Generator

Transform rough ideas, descriptions, or feature requests into professional, engineering-level task markdown files that another engineer or LLM can execute without ambiguity.

## When to Activate

- User wants to create a task file or specification
- User has a rough idea they want documented as an actionable task
- User says "write a task", "create a task file", "turn this into a task"
- User mentions "projectask" or task generation
- User provides a description and wants it saved as a structured task document
- User asks to "document this as an implementation spec"

## Process

### 1. Parse Arguments and Detect Category

The user provides:
- A rough idea, description, or feature request (required)
- Optionally: a target file path (`.md`) or directory for the output
- Optionally: a category via `--category <cat>`, `-c <cat>`, or as a leading keyword

#### Category Extraction (in priority order)

1. **Explicit flag**: `--category <value>` or `-c <value>` → extract as category, remove from arguments
2. **Keyword match**: If the first word of the description (after path extraction) matches a known category keyword, extract it as the category:

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

3. **Inferred**: If no category found above, infer during Step 2 from task type analysis

#### Path Detection Rules

If the user specifies a path:
- Ending in `.md` → use as the **exact output file path**
- A directory path (starts with `/`, `./`, `../`, or contains `/` with no whitespace) → use as the **output directory** with auto-increment naming

If no path is specified, default to `.projectasks/` with auto-increment naming.

**Ask the user** if the output path is unclear from context.

#### Directory Resolution

- **With category**: `<base-dir>/<category>/task<NNN>-<slug>.md`
- **Without category**: `<base-dir>/task<NNN>-<slug>.md` (backward compatible)

#### Auto-Increment File Naming

When writing to a directory (including `.projectasks/` default, with or without category subdirectory):

1. Create the directory if it does not exist: `mkdir -p <target-dir>`
2. Run: `ls <target-dir>/task*.md 2>/dev/null`
3. For each matching filename, extract the integer N from the pattern `taskNNN` (with or without leading zeros)
4. Take the maximum integer found. If no files matched, set N = 0
5. The new file number is `N+1`, zero-padded to 3 digits (e.g., `001`, `012`, `123`)
6. Generate a **slug** from the task title: lowercase, remove stop words (a, an, the, is, to, for, and, or, in, on, with, of), replace spaces/special chars with hyphens, collapse multiple hyphens, trim hyphens from ends, truncate to 50 chars
7. Final filename: `task<NNN>-<slug>.md` (e.g., `task003-add-user-authentication.md`)

### 2. Analyze the Input

Think hard about the user's input before generating anything. Identify:

1. **Task type**: API feature, UI component, CLI tool, database migration, refactor, bugfix, infrastructure, or documentation?
2. **Category inference** (if not already determined): Map the task type to a category. Always assign a category — if uncertain, default to `feature`.
3. **Ambiguity check**: Are there open design decisions? If critical, ask the user. If minor, document as an assumption.
4. **Scope assessment**: Single-session or multi-task? If >10 files affected, recommend decomposition.

### 3. Gather Project Context

Adapt depth based on what is available:

1. **Current working directory** (`pwd`)
2. **Project name** from `package.json`, `Cargo.toml`, or directory basename. If undetermined, use `Unknown`.
3. **CLAUDE.md / AGENTS.md**: Read and summarize relevant conventions if present.
4. **Tech stack detection**: Check for `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, etc. Note framework and key libraries.
5. **Relevant source files**: If the user mentions files, modules, or features — read them. Use Glob/Grep to find related files if the description implies a specific codebase area.
6. **Existing task files**: If writing to a directory with existing tasks, read one for format consistency.

### 4. Think Hard, Then Generate

Use extended thinking to produce a high-quality, self-contained task file. The reader has zero context from this conversation.

#### Refinement Rules

- Fix grammar and spelling
- Expand vague ideas into specific, actionable requirements with exact file paths when known
- Every requirement: What to do, Where to do it, Why it matters
- Acceptance criteria: independently verifiable — prefer `GIVEN/WHEN/THEN` or exact commands
- Do NOT pad with filler — every line must add value
- Do NOT duplicate requirements as acceptance criteria

#### Output Template

```markdown
---
status: todo
priority: medium
category: <category>
created: YYYY-MM-DDTHH:MM:SS
started:
completed:
due:
branch:
tags: []
---

# Task: [Concise, Descriptive Title]

## Objective

[1-2 paragraphs: what needs to be done and why. Refined from user input.
Include business or technical motivation. Reader should understand the "why"
without needing any other context.]

## Context

- **Project:** [project name]
- **Working Directory:** [cwd]
- **Tech Stack:** [detected framework, language, key libraries]
- **Related Files:** [discovered files relevant to this task, or "N/A"]

## Assumptions

[Design decisions or interpretations inferred rather than explicitly stated.
Flag each so the reader can challenge it.
If none: "None — all requirements were explicitly stated."]

## Requirements

[Each requirement includes what, where, and why.]

- [ ] **[Title]**: [Description]. File: `path/to/file`. Reason: [why]
- [ ] [Continue as needed]

## Acceptance Criteria

[Each criterion is independently verifiable.]

- [ ] GIVEN [precondition], WHEN [action], THEN [expected result]
- [ ] Run: `[exact command]` → Expected: [output or exit code]
- [ ] [Continue as needed]

## Out of Scope

[What this task does NOT cover. Prevents scope creep.
If everything is in scope: "No explicit exclusions."]

## Dependencies

[Prerequisites: other tasks, env vars, services, packages, infrastructure.
If none: "None."]

## Testing Strategy

- **Unit tests:** [what to test, where to put them]
- **Integration tests:** [if applicable]
- **Verification command:** `[exact command]`

## Technical Notes

[Implementation hints, edge cases, constraints, architecture considerations,
debugging guidance. Reference specific files, APIs, patterns, conventions.
Include known gotchas, suggested approach, performance/security concerns.]
```

#### Metadata Field Rules

- **status**: Always `todo` on creation
- **priority**: Infer from user's language — "urgent"/"ASAP"/"critical" → `high`, "when you get a chance"/"low priority" → `low`, otherwise → `medium`. Valid values: `critical`, `high`, `medium`, `low`
- **category**: The resolved category from step 1 or 2. Always lowercase, single word. Must be one of the canonical categories from the keyword table, or a custom single-word category if none fit
- **created**: Current timestamp in ISO 8601 (YYYY-MM-DDTHH:MM:SS)
- **started**: Leave empty (filled by `/projectask:start`)
- **completed**: Leave empty (filled by `/projectask:done`)
- **due**: Extract from user input if mentioned, otherwise leave empty
- **branch**: Leave empty (filled by `/projectask:start` with current git branch)
- **tags**: Extract relevant tags — task type (e.g., `feature`, `bugfix`, `refactor`), area (e.g., `auth`, `api`, `ui`), or user-specified labels. Format as YAML list.

### 5. Verify and Write

Before writing, self-review:

1. **Traceability**: Every requirement traces to user input or a documented assumption
2. **Measurability**: Every acceptance criterion is verifiable by command or observable behavior
3. **Self-containment**: Executable by someone with codebase access but zero conversation context
4. **Consistency**: Requirements and acceptance criteria align — no orphans in either direction
5. **Metadata completeness**: YAML frontmatter filled correctly, `created` set to current timestamp, `category` set

After verification:

1. Create target directory if needed (`mkdir -p`) — includes category subdirectory if applicable
2. Write the content to the resolved path using the Write tool
3. Report: "Task file created: `<path>`"
4. Show brief summary: title, category, requirement count, detected task type, priority
