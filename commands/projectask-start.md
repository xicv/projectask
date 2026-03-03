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
