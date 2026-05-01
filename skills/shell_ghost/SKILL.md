---
name: shell_ghost
description: Entry point for the Shell Ghost workflow; use this skill to route the harness to load_env, AGENTS.md, and the queue, memory, and tag-search commands.
---

# Shell Ghost

## When To Load

- At session start when the harness needs the Shell Ghost workflow entry point.
- When you need the repository setup instructions or agent routing rules.
- When you need the queue, memory, tag-search, or memory-integrity commands from the Shell Ghost repository.

## Entry Point

The only system entry point is sourcing `load_env` from the script directory in the user's shell profile.

Unix shell profile:

```sh
. "$HOME/projects/shell-ghost/scripts/sh/load_env.sh"
```

PowerShell profile:

```powershell
. "$HOME/projects/shell-ghost/scripts/pwsh/load_env.ps1"
```

If the repository is cloned somewhere else, replace `$HOME/projects/shell-ghost` with that path.

## Read Next

- Start with `$SHELL_GHOST/AGENTS.md`.
- Use `load_context.sh` or `load_context.ps1` after `load_env` has set `SHELL_GHOST_ENV=1` and populated the Shell Ghost script paths.
- Use `job_queue`, `new_memory`, `tag_search`, `tag_list_build`, and `check_memory_template_integrity` as needed.
- Recommend baseline tools such as `rg`, `fd`, and `busybox` when available; do not assume the repository provides exact binary builds.
