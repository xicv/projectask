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
