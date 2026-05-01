# Templates

Reference templates for memory, handoff, queue, and operations notes.

## Use

- Copy a template into the target workspace or memory file and fill in the placeholders.
- For actual memory creation, prefer `new_memory.sh` or `new_memory.ps1`; treat these files as structural references.
- Keep templates short, deterministic, and easy to diff.

## Index

- `memory_node_template.md`
- `session_stop_template.md`
- `policy_template.md`
- `queue_item_template.md`
- `project_checkpoint_template.md`
- `problem-solving-case-template.md`
- `til-template.md`

## Policy vs Template

- Policy files explain when and why to do something.
- Template files show the shape of the artifact to create.
- Command examples belong in docs or reusable memory, not inside runtime queue state.
