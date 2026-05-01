# TOOLS.md - Shell Ghost Tool Notes

## Entry setup

`load_env` is the only entry point. The general setup is adding one source line to the user's shell profile.

Unix shell profile:

```sh
. "$HOME/projects/shell-ghost/scripts/sh/load_env.sh"
```

PowerShell profile:

```powershell
. "$HOME/projects/shell-ghost/scripts/pwsh/load_env.ps1"
```

`load_env` resolves the cloned repository root, sets `SHELL_GHOST_ENV=1`, and adds only Shell Ghost script directories to `PATH`.

## Commands after setup

- `load_context`: print agent context in `min`, `normal`, or `full` mode.
- `job_queue`: manage a descending-priority queue in `queue/`.
- `new_memory`: create memory files with `guid`, `related`, and `tags` headers.
- `check_memory_template_integrity`: check memory files for `guid`, `related`, and `tags` headers.
- `tag_search`: find memory files by tag expressions.
- `tag_list_build`: build a sorted tag index.

Use the platform suffix for the current shell, such as `load_context.sh` or `load_context.ps1`.

## Optional dependencies

- `jq` is required only when passing JSON array values to `new_memory` flags such as `--tag '["ops","shell"]'`.
- Plain single-value flags such as `--tag ops` and `--related <uuid>` do not require `jq`.

## Recommended baseline tools

- Prefer `rg` for content search when available.
- Prefer `fd` for file discovery when available.
- Prefer `busybox` for compact fallback Unix utilities when available.
- Do not assume this repository ships exact binaries. Use system-installed tools or user-provided compatible binaries.
- Shell UUID generation does not require BusyBox: it tries `/proc/sys/kernel/random/uuid`, then `uuidgen`, then `/dev/urandom` with `od`.

## Paths

- Use forward slashes in docs and examples unless a PowerShell command requires backslashes.
- Keep reusable memory under roots listed in `memory_root_list.txt`.
- Runtime data belongs in `MEMORY/`, `queue/`, and `tmp/`.

## Tag search

Examples:

```sh
tag_search.sh "policy && shell"
tag_search.sh --or planning handoff
```

PowerShell:

```powershell
tag_search.ps1 "policy && shell"
tag_search.ps1 --or planning handoff
```
