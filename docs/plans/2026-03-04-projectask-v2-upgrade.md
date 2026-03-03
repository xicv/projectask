# Projectask V2 Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the projectask skill from a shallow template-filler to a professional-grade, multi-phase task specification generator with metadata tracking, task listing, and task completion workflows.

**Architecture:** Rewrite both files (command + skill) with a 5-phase pipeline: Parse → Analyze → Gather Context → Think & Generate → Verify & Write. Add YAML frontmatter metadata to generated task files, new file naming (`task<NNN>-<slug>.md`), default folder change to `.projectasks`, a new `/projectask-list` command for querying tasks, and a `/projectask-done` command for marking tasks complete. Keep command and skill in sync with appropriate role differentiation.

**Tech Stack:** Claude Code skills system (SKILL.md + commands), no external dependencies

---

### Task 1: Rewrite the Slash Command with V2 Pipeline

**Files:**
- Modify: `commands/projectask.md`

**Step 1: Write the updated command file**

Replace the entire contents of `commands/projectask.md` with the following:

````markdown
---
description: "Generate professional, LLM-executable task files from rough ideas. Accepts optional path and task description."
---

# /projectask - Generate Professional Task Files

Transform rough ideas, descriptions, or feature requests into professional, engineering-level task markdown files that another engineer or LLM can execute without ambiguity.

## Usage

```
/projectask "task description"
/projectask path/to/dir "task description"
/projectask path/to/file.md "task description"
```

**Input:** $ARGUMENTS

---

## Phase 1: Parse Arguments

Analyze `$ARGUMENTS` to extract two components:

1. **Output path** (optional): A file path or directory path
2. **Task description** (required): Everything else is the raw task idea

### Path Detection Rules

The **first token** (whitespace-delimited) of `$ARGUMENTS` is treated as an output path only if it meets ANY of these criteria:
- Ends in `.md` → use as the **exact output file path**
- Starts with `/`, `./`, or `../` → use as the **output directory** with auto-increment naming
- Contains `/` and has no whitespace → use as the **output directory** with auto-increment naming

If the first token does not match any of the above, treat ALL of `$ARGUMENTS` as the **task description** and default the output directory to `.projectasks/`.

### Auto-Increment File Naming

When using a directory (including the `.projectasks/` default):

1. Create the directory if it does not exist: `mkdir -p <target-dir>`
2. Run: `ls <target-dir>/task*.md 2>/dev/null`
3. For each matching filename, extract the integer N from the pattern `taskNNN` (with or without leading zeros)
4. Take the maximum integer found. If no files matched, set N = 0
5. The new file number is `N+1`, zero-padded to 3 digits (e.g., `001`, `012`, `123`)
6. Generate a **slug** from the task title: lowercase, remove stop words (a, an, the, is, to, for, and, or, in, on, with, of), replace spaces/special chars with hyphens, collapse multiple hyphens, trim hyphens from ends, truncate to 50 chars
7. Final filename: `task<NNN>-<slug>.md` (e.g., `task003-add-user-authentication.md`)

## Phase 2: Analyze the Input

Think hard about the user's raw input before generating anything. Identify:

1. **Task type**: Is this an API feature, UI component, CLI tool, database migration, refactor, bugfix, infrastructure, or documentation task? The type determines which sections need the most depth.
2. **Ambiguity check**: Are there design decisions the user has left open? If so, either:
   - Ask the user to clarify (if the ambiguity is critical and has multiple valid answers), OR
   - Document the assumption explicitly in the output's "Assumptions" section
3. **Scope assessment**: Is this a single-session task or does it need to be broken into sub-tasks? If the task would require modifying more than 10 files, recommend decomposition in the Technical Notes.

## Phase 3: Gather Project Context

Gather context to ground the task in the real project. Adapt depth based on what is available:

1. **Current working directory**: Full path from `pwd`
2. **Project name**: Read `package.json` (field `name`), `Cargo.toml` (field `name`), or fall back to the current directory basename. If undetermined, use `Unknown`.
3. **CLAUDE.md / AGENTS.md**: If present, read and summarize relevant conventions (do NOT dump verbatim).
4. **Tech stack detection**: Check for `package.json` (dependencies), `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, or similar to identify the tech stack. Note the framework and key libraries.
5. **Relevant source files**: If the user mentions specific files, modules, or features — read them to understand existing patterns, naming conventions, and architecture. Use Glob/Grep to find related files if the user's description implies a specific area of the codebase.
6. **Existing task files**: If writing to a directory with existing task files, read one to match format and style consistency.

## Phase 4: Think Hard, Then Generate

Use extended thinking to produce a high-quality task file. The output must be **self-contained** — the reader has zero context from this conversation.

### Refinement Rules

- Fix grammar and spelling in the user's description
- Expand vague ideas into specific, actionable requirements with exact file paths when known
- Every requirement must answer: What to do, Where to do it, Why it matters
- Acceptance criteria must be independently verifiable — prefer `GIVEN/WHEN/THEN` format or exact commands to run
- Do NOT pad with generic filler — every line must add value
- Do NOT duplicate requirements as acceptance criteria — they serve different purposes (what to build vs how to verify)

### Output Template

Write the file using this exact structure:

```markdown
---
status: todo
priority: medium
created: YYYY-MM-DDTHH:MM:SS
started:
completed:
due:
tags: []
---

# Task: [Concise, Descriptive Title]

## Objective

[1-2 paragraphs describing what needs to be done and why. This should be a refined,
expanded version of the user's raw input. Include the business or technical motivation.
The reader should understand the "why" without needing any other context.]

## Context

- **Project:** [project name]
- **Working Directory:** [cwd]
- **Tech Stack:** [detected framework, language, key libraries]
- **Related Files:** [discovered files relevant to this task, or "N/A"]

## Assumptions

[List any design decisions or interpretations that were inferred rather than explicitly
stated by the user. Each assumption should be flagged so the reader can challenge it.
If no assumptions were made, write "None — all requirements were explicitly stated."]

## Requirements

[Each requirement includes what to do, where to do it, and why.]

- [ ] **[Requirement title]**: [Specific description]. File: `path/to/file`. Reason: [why this is needed]
- [ ] [Continue as needed — be thorough but not redundant]

## Acceptance Criteria

[Each criterion is independently verifiable. Use GIVEN/WHEN/THEN or exact verification commands.]

- [ ] GIVEN [precondition], WHEN [action], THEN [expected result]
- [ ] Run: `[exact command]` → Expected: [specific output or exit code]
- [ ] [Continue as needed]

## Out of Scope

[Explicitly state what this task does NOT cover, to prevent scope creep.
If everything is in scope, write "No explicit exclusions."]

## Dependencies

[What must exist or be completed before this task can start.
Include: prerequisite tasks, required environment variables, external services,
required packages, or infrastructure. If none, write "None."]

## Testing Strategy

[What tests should be written and what type (unit, integration, E2E).
Reference the project's test framework and test file location conventions if known.]

- **Unit tests:** [what to test, where to put them]
- **Integration tests:** [if applicable]
- **Verification command:** `[exact command to run all relevant tests]`

## Technical Notes

[Implementation hints, edge cases, constraints, architectural considerations,
or debugging guidance. Reference specific files, APIs, patterns, or conventions
from the project context. Include:
- Known gotchas or pitfalls in this area of the codebase
- Suggested implementation approach if non-obvious
- Performance or security considerations if relevant
- Links to relevant documentation or prior art]
```

### Metadata Field Rules

- **status**: Always set to `todo` on creation
- **priority**: Infer from user's language — "urgent"/"ASAP"/"critical" → `high`, "when you get a chance"/"low priority" → `low`, otherwise → `medium`. Valid values: `critical`, `high`, `medium`, `low`
- **created**: Current timestamp in ISO 8601 format (YYYY-MM-DDTHH:MM:SS)
- **started**: Leave empty (filled when work begins)
- **completed**: Leave empty (filled when work is done)
- **due**: Extract from user input if mentioned (e.g., "by Friday", "end of sprint"), otherwise leave empty
- **tags**: Extract relevant tags from context — task type (e.g., `feature`, `bugfix`, `refactor`), area (e.g., `auth`, `api`, `ui`), or user-specified labels. Format as YAML list.

## Phase 5: Verify and Write

Before writing the file, self-review the generated content:

1. **Traceability**: Does every requirement trace back to something in the user's input or a reasonable inference? Remove anything that is pure filler.
2. **Measurability**: Is every acceptance criterion independently verifiable by running a command or checking a specific behavior? Rewrite any that say "should work correctly" or similar vague phrases.
3. **Self-containment**: Could someone with access to the codebase but zero context from this conversation execute this task? If not, add the missing context.
4. **Consistency**: Do the requirements and acceptance criteria align? Are there requirements without corresponding criteria or vice versa?
5. **Metadata completeness**: Is the YAML frontmatter filled in correctly? Is `created` set to the current timestamp?

After verification:

1. Create the target directory if it does not exist (`mkdir -p`)
2. Write the generated content to the resolved file path using the Write tool
3. Report: "Task file created: `<path>`"
4. Show a brief summary: title, requirement count, detected task type, priority
````

**Step 2: Verify the file was written correctly**

Run: `head -5 commands/projectask.md`
Expected: YAML frontmatter with updated description visible

**Step 3: Commit**

```bash
git add commands/projectask.md
git commit -m "feat: upgrade projectask command to v2 with multi-phase pipeline and metadata"
```

---

### Task 2: Rewrite the Auto-Triggered Skill with V2 Pipeline

**Files:**
- Modify: `skills/projectask/SKILL.md`

**Step 1: Write the updated skill file**

Replace the entire contents of `skills/projectask/SKILL.md` with the following:

````markdown
---
name: projectask
description: Generate professional, LLM-executable task markdown files from rough ideas or descriptions. Use this skill when the user wants to create a task file, write a task specification, generate a requirements document, turn an idea into an actionable task, or asks to "write a task", "create a task file", "make a task spec", "document this as a task", or "turn this into an implementation spec". Also triggers when user says "projectask" or mentions generating implementation-ready task documentation. Do NOT use for general conversation about tasks or project management — only when the user wants a task file written to disk.
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

### 1. Identify Input and Output Path

The user provides:
- A rough idea, description, or feature request (required)
- Optionally: a target file path (`.md`) or directory for the output

#### Path Detection Rules

If the user specifies a path:
- Ending in `.md` → use as the **exact output file path**
- A directory path (starts with `/`, `./`, `../`, or contains `/` with no whitespace) → use as the **output directory** with auto-increment naming

If no path is specified, default to `.projectasks/` with auto-increment naming.

**Ask the user** if the output path is unclear from context.

#### Auto-Increment File Naming

When writing to a directory (including `.projectasks/` default):

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
2. **Ambiguity check**: Are there open design decisions? If critical, ask the user. If minor, document as an assumption.
3. **Scope assessment**: Single-session or multi-task? If >10 files affected, recommend decomposition.

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
created: YYYY-MM-DDTHH:MM:SS
started:
completed:
due:
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
- **created**: Current timestamp in ISO 8601 (YYYY-MM-DDTHH:MM:SS)
- **started**: Leave empty
- **completed**: Leave empty
- **due**: Extract from user input if mentioned, otherwise leave empty
- **tags**: Extract relevant tags — task type (e.g., `feature`, `bugfix`, `refactor`), area (e.g., `auth`, `api`, `ui`), or user-specified labels. Format as YAML list.

### 5. Verify and Write

Before writing, self-review:

1. **Traceability**: Every requirement traces to user input or a documented assumption
2. **Measurability**: Every acceptance criterion is verifiable by command or observable behavior
3. **Self-containment**: Executable by someone with codebase access but zero conversation context
4. **Consistency**: Requirements and acceptance criteria align — no orphans in either direction
5. **Metadata completeness**: YAML frontmatter filled correctly, `created` set to current timestamp

After verification:

1. Create target directory if needed (`mkdir -p`)
2. Write the content to the resolved path using the Write tool
3. Report: "Task file created: `<path>`"
4. Show brief summary: title, requirement count, detected task type, priority
````

**Step 2: Verify the file was written correctly**

Run: `head -4 skills/projectask/SKILL.md`
Expected: YAML frontmatter with `name: projectask` and updated description

**Step 3: Commit**

```bash
git add skills/projectask/SKILL.md
git commit -m "feat: upgrade projectask skill to v2 with multi-phase pipeline and metadata"
```

---

### Task 3: Create the `/projectask-list` Command

**Files:**
- Create: `commands/projectask-list.md`

**Step 1: Write the command file**

Create `commands/projectask-list.md` with the following content:

````markdown
---
description: "List, filter, and summarize projectask task files. Supports status filtering, sorting, and summaries."
---

# /projectask-list - List and Query Task Files

List, filter, sort, and summarize task files generated by `/projectask`.

## Usage

```
/projectask-list
/projectask-list --status todo
/projectask-list --status in-progress
/projectask-list --latest 5
/projectask-list --tag feature
/projectask-list --priority high
/projectask-list --dir path/to/tasks
/projectask-list --summary
```

**Input:** $ARGUMENTS

---

## Step 1: Parse Arguments

Parse `$ARGUMENTS` for these optional flags. All flags are optional and can be combined:

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--status` or `-s` | `todo`, `in-progress`, `blocked`, `done`, `cancelled` | (all) | Filter by status |
| `--priority` or `-p` | `critical`, `high`, `medium`, `low` | (all) | Filter by priority |
| `--tag` or `-t` | any string | (all) | Filter by tag (matches any tag in the list) |
| `--latest` or `-l` | integer N | (all) | Show only the N most recently created tasks |
| `--sort` | `created`, `priority`, `status`, `due` | `created` | Sort field |
| `--order` | `asc`, `desc` | `desc` | Sort direction |
| `--dir` or `-d` | directory path | `.projectasks/` | Directory to scan |
| `--summary` | (flag, no value) | false | Show a high-level summary instead of individual tasks |

If `$ARGUMENTS` is empty, list all tasks in `.projectasks/` sorted by creation date descending.

## Step 2: Scan Task Files

1. Resolve the target directory (default: `.projectasks/`)
2. Run: `ls <target-dir>/task*.md 2>/dev/null`
3. If no files found, report "No task files found in `<dir>`" and stop
4. For each file, read the YAML frontmatter to extract metadata fields: `status`, `priority`, `created`, `started`, `completed`, `due`, `tags`
5. Also extract the title from the first `# Task: ...` heading

## Step 3: Filter

Apply filters in order:
1. **Status filter**: If `--status` specified, keep only tasks matching that status
2. **Priority filter**: If `--priority` specified, keep only tasks matching that priority
3. **Tag filter**: If `--tag` specified, keep only tasks where `tags` list contains the specified tag

## Step 4: Sort

Sort the filtered results:
- `created` (default): By `created` timestamp
- `priority`: By priority level (`critical` > `high` > `medium` > `low`)
- `status`: By status (`in-progress` > `todo` > `blocked` > `done` > `cancelled`)
- `due`: By `due` date (tasks without due dates go last)

Apply `--order` direction (default: `desc` for `created`, `asc` for `priority`/`status`/`due`).

If `--latest N` is specified, take only the first N results after sorting.

## Step 5: Display

### Default View (table)

Display a formatted table:

```
Status      | Priority | Title                          | Created    | Due        | Tags
------------|----------|--------------------------------|------------|------------|--------
🟡 todo     | high     | Add user authentication        | 2026-03-04 | 2026-03-10 | feature, auth
🔵 in-prog  | medium   | Refactor database layer        | 2026-03-03 |            | refactor
✅ done     | medium   | Fix login redirect bug         | 2026-03-01 | 2026-03-02 | bugfix
```

Status icons:
- `🟡 todo` — not started
- `🔵 in-prog` — in progress
- `🔴 blocked` — blocked
- `✅ done` — completed
- `⚫ cancel` — cancelled

After the table, show: `N tasks found (X todo, Y in-progress, Z done)`

### Summary View (`--summary`)

When `--summary` is specified, show an overview:

```
## Task Summary — .projectasks/

**Total:** 12 tasks
**By Status:** 4 todo, 3 in-progress, 1 blocked, 4 done
**By Priority:** 1 critical, 3 high, 6 medium, 2 low
**Overdue:** 2 tasks past due date

### Active Tasks (in-progress)
1. **Refactor database layer** (medium) — started 2026-03-03
2. **Add OAuth provider** (high) — started 2026-03-04
3. **Update API docs** (low) — started 2026-03-02

### Upcoming (todo, by priority)
1. **[critical] Add user authentication** — due 2026-03-10
2. **[high] Implement rate limiting** — no due date
3. **[medium] Add dark mode** — due 2026-03-15
4. **[medium] Refactor utils** — no due date
```

Show the Objective section (first paragraph only) for each active task to provide context.
````

**Step 2: Create the symlink**

```bash
ln -s /Users/xicao/Projects/projectasks/commands/projectask-list.md ~/.claude/commands/projectask-list.md
```

**Step 3: Verify symlink**

Run: `head -3 ~/.claude/commands/projectask-list.md`
Expected: YAML frontmatter visible

**Step 4: Commit**

```bash
git add commands/projectask-list.md
git commit -m "feat: add /projectask-list command for querying task files"
```

---

### Task 4: Create the `/projectask-done` Command

**Files:**
- Create: `commands/projectask-done.md`

**Step 1: Write the command file**

Create `commands/projectask-done.md` with the following content:

````markdown
---
description: "Mark a projectask task file as done or update its status. Updates YAML frontmatter metadata and timestamps."
---

# /projectask-done - Update Task Status

Mark a task file as done (or update to any status) by modifying its YAML frontmatter metadata.

## Usage

```
/projectask-done
/projectask-done path/to/task.md
/projectask-done path/to/task.md --status in-progress
/projectask-done --latest
```

**Input:** $ARGUMENTS

---

## Step 1: Identify the Task File

Parse `$ARGUMENTS`:

1. **Explicit path**: If a `.md` file path is provided, use it directly
2. **`--latest` flag**: Find the most recently modified task file in `.projectasks/` that has `status: in-progress`
3. **No arguments**: Look in `.projectasks/` for task files with `status: in-progress`
   - If exactly one found, use it
   - If multiple found, list them and ask the user which one to update
   - If none found, list `todo` tasks and ask if the user wants to mark one as done

## Step 2: Parse the Status

Check for `--status` flag in `$ARGUMENTS`:

| Flag Value | Action |
|------------|--------|
| (none / omitted) | Set to `done` |
| `in-progress` | Set to `in-progress`, update `started` timestamp |
| `blocked` | Set to `blocked` |
| `done` | Set to `done`, update `completed` timestamp |
| `cancelled` | Set to `cancelled`, update `completed` timestamp |
| `todo` | Reset to `todo`, clear `started` and `completed` |

## Step 3: Read and Update the Task File

1. Read the task file
2. Parse the YAML frontmatter between the `---` delimiters
3. Update the metadata:
   - **`status`**: Set to the target status
   - **`started`**: If transitioning TO `in-progress` and `started` is empty, set to current ISO 8601 timestamp
   - **`completed`**: If transitioning TO `done` or `cancelled`, set to current ISO 8601 timestamp. If transitioning AWAY from `done`/`cancelled`, clear it
4. Write the updated file using the Edit tool (preserve all other content exactly)

## Step 4: Report

After updating:

```
✅ Task updated: `<path>`
   Status: todo → done
   Completed: 2026-03-04T15:30:00
```

If the task had acceptance criteria, remind the user:

```
📋 This task had N acceptance criteria. Have they all been verified?
```
````

**Step 2: Create the symlink**

```bash
ln -s /Users/xicao/Projects/projectasks/commands/projectask-done.md ~/.claude/commands/projectask-done.md
```

**Step 3: Verify symlink**

Run: `head -3 ~/.claude/commands/projectask-done.md`
Expected: YAML frontmatter visible

**Step 4: Commit**

```bash
git add commands/projectask-done.md
git commit -m "feat: add /projectask-done command for updating task status"
```

---

### Task 5: Create the `/projectask-start` Command

**Files:**
- Create: `commands/projectask-start.md`

**Step 1: Write the command file**

Create `commands/projectask-start.md` with the following content:

````markdown
---
description: "Mark a projectask task as in-progress and begin working on it. Shorthand for /projectask-done --status in-progress."
---

# /projectask-start - Start Working on a Task

Mark a task file as in-progress and set the `started` timestamp. This is a convenience shorthand.

## Usage

```
/projectask-start
/projectask-start path/to/task.md
/projectask-start --latest
```

**Input:** $ARGUMENTS

---

## Step 1: Identify the Task File

Parse `$ARGUMENTS`:

1. **Explicit path**: If a `.md` file path is provided, use it directly
2. **`--latest` flag**: Find the most recently created task file in `.projectasks/` with `status: todo`
3. **No arguments**: Look in `.projectasks/` for task files with `status: todo`
   - If exactly one found, use it
   - If multiple found, list them sorted by priority (critical first) and ask the user which one to start
   - If none found, report "No pending tasks found in `.projectasks/`"

## Step 2: Read and Update the Task File

1. Read the task file
2. Parse the YAML frontmatter between the `---` delimiters
3. Update the metadata:
   - **`status`**: Set to `in-progress`
   - **`started`**: Set to current ISO 8601 timestamp (YYYY-MM-DDTHH:MM:SS)
4. Write the updated file using the Edit tool (preserve all other content exactly)

## Step 3: Report

After updating:

```
🔵 Task started: `<path>`
   Status: todo → in-progress
   Started: 2026-03-04T15:30:00
   Priority: high
   Title: [task title]
```

Then display the task's Requirements section so the user can see what needs to be done.
````

**Step 2: Create the symlink**

```bash
ln -s /Users/xicao/Projects/projectasks/commands/projectask-start.md ~/.claude/commands/projectask-start.md
```

**Step 3: Verify symlink**

Run: `head -3 ~/.claude/commands/projectask-start.md`
Expected: YAML frontmatter visible

**Step 4: Commit**

```bash
git add commands/projectask-start.md
git commit -m "feat: add /projectask-start command for beginning task work"
```

---

### Task 6: Update README to Document V2

**Files:**
- Modify: `README.md`

**Step 1: Update the README**

Replace the entire contents of `README.md` with:

```markdown
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
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for projectask v2 with full feature documentation"
```

---

### Task 7: Push to Remote and Verify Symlinks

**Step 1: Push all commits**

```bash
git push
```

**Step 2: Verify symlinks still work**

```bash
head -3 ~/.claude/commands/projectask.md
head -4 ~/.claude/skills/projectask/SKILL.md
head -3 ~/.claude/commands/projectask-list.md
head -3 ~/.claude/commands/projectask-done.md
head -3 ~/.claude/commands/projectask-start.md
```

Expected: All should show V2 frontmatter content, confirming symlinks resolve correctly.

**Step 3: Verify skill is recognized**

The skill list in Claude Code should show `projectask` with the updated description.
