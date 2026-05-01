# Job Queue Item

- `job_queue.sh push [priority] <content...>`
- `job_queue.ps1 push [priority] <content...>`

Example output line:

- `10 2026-03-27 14:30:00 resume from /MEMORY/archive/session_topic.md`

## States

- `PENDING`
- `IN_PROGRESS`
- `BLOCKED`
- `DONE`

## Notes

- Queue format is managed by `job_queue`; do not hand-edit queue lines unless repairing corruption.
- Keep items short.
- Keep only current execution context here.
- Move durable lessons to `/MEMORY`.
