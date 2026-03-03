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
