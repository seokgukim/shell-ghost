# AGENTS.md - Shell Ghost Agent Router

This file is the public agent routing layer for Shell Ghost. `README.md` is for humans; this file is for agents that need compact operating context.

The harness meta skill lives at `skills/shell_ghost` and should route here after `load_env` is available from the user's shell profile.

## Entry Point

The only system entry point is the profile setup line that sources `load_env` from the script directory.

Unix shell profile:

```sh
. "$HOME/projects/shell-ghost/scripts/sh/load_env.sh"
```

PowerShell profile:

```powershell
. "$HOME/projects/shell-ghost/scripts/pwsh/load_env.ps1"
```

After profile setup, use the commands added to `PATH`. Do not introduce separate bootstrap, context-switch, or root-finder entry points for the general flow.

## Critical Paths

- `$SHELL_GHOST_ROOT` is the cloned Shell Ghost repository root.
- `$SHELL_GHOST` is an alias for the same root.
- `$SHELL_GHOST_ENV=1` marks a shell/profile session where Shell Ghost has been loaded.
- `$SHELL_GHOST_WORKSPACE` optionally points memory and queue commands at another workspace.
- `$SHELL_GHOST_MEMORY` defaults to `$SHELL_GHOST/MEMORY`.
- `$SHELL_GHOST_QUEUE` defaults to `$SHELL_GHOST/queue`.

## First Decision

Before planning or executing, decide the load scope explicitly:

- `min`: only the compact agent routing rules are needed.
- `normal`: routing rules and tool notes are needed.
- `full`: memory index and hub context are needed for recall, policy lookup, handoff, or ambiguous work.
- `targeted`: a specific policy/reference is needed; use tag search instead of loading everything.

Prefer the smallest scope that preserves correctness.

## Commands

Unix shell:

```sh
load_context.sh min
load_context.sh normal
load_context.sh full
tag_search.sh <tag-or-query>
```

PowerShell:

```powershell
load_context.ps1 -Mode min
load_context.ps1 -Mode normal
load_context.ps1 -Mode full
tag_search.ps1 <tag-or-query>
```

## Routing Rules

- New session or uncertain baseline: load `normal`.
- Small command, path lookup, or syntax reminder: load `min`.
- Planning non-trivial work: load `normal`, then targeted tags for the domain.
- Long-running, risky, architectural, or handoff work: load `full`.
- Memory recall by topic: use `tag_search` first, then read only the returned files that are relevant.
- Creating or updating memory: use `new_memory`.
- Queue work: use `job_queue`.
- Templates or scaffolding: read `templates/README.md` first.

## Work Baseline

- Keep user/project-specific content out of the Shell Ghost repository unless intentionally publishing it.
- Treat `MEMORY/`, `queue/`, and `tmp/` as local runtime state.
- Recommend common baseline binaries such as `rg`, `fd`, and `busybox`, but do not assume Shell Ghost vendors exact binaries.
- Prefer GUID-based `related` links and `tags` metadata; do not use `parent`.
- Avoid destructive commands unless explicitly requested.

## Output Discipline

When loading context, state the scope briefly:

- `Loaded Shell Ghost: min`
- `Loaded Shell Ghost: normal`
- `Loaded Shell Ghost: full`
- `Loaded Shell Ghost: targeted tags=<...>`

Then proceed with the task using that context.
