# Clockify

## clockify_log.sh

Quickly log a time entry for today without touching the Clockify UI.

1. Pick a project from a numbered list (favorites ★ first, then alphabetical)
2. Pick a task (alphabetical; skipped if the project has no tasks)
3. Enter hours as a decimal (`1`, `0.5`, `2.25`)
4. Enter a description

The entry is logged today starting at 9:00am local time, or right after
your latest entry of the day, so repeated runs stack up without
overlapping — the clock times don't matter, only the date and duration.

Targets the workspace named in `WORKSPACE_NAME` at the top of the script
(currently "NEMAC's workspace").

### Setup

Requires `curl` and `jq`. Get an API key from
[Clockify preferences](https://app.clockify.me/user/preferences#advanced)
and put it in a `.env` file next to the script (gitignored):

```sh
CLOCKIFY_API_KEY=your-key-here
```

Exporting `CLOCKIFY_API_KEY` in your shell works too.

### Usage

```sh
./clockify_log.sh
```
