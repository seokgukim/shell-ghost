# Shell Ghost

Shell Ghost is a small, agent-friendly shell workflow kit for agent context loading, memory notes, tag search, and a priority job queue.

It is designed to live in a normal cloned repository. It does not assume machine-specific paths or personal identity files.

## Minimal setup

The minimal entry setup is one profile line that sources `load_env` from this repository. After that, every new shell is marked with `SHELL_GHOST_ENV=1` and has the Shell Ghost scripts on `PATH`.

Unix shell profile (`~/.bashrc`, `~/.zshrc`, or another interactive shell profile):

```sh
. "$HOME/projects/shell-ghost/scripts/sh/load_env.sh"
```

PowerShell profile (`$PROFILE`):

```powershell
. "$HOME/projects/shell-ghost/scripts/pwsh/load_env.ps1"
```

If you cloned somewhere else, replace `$HOME/projects/shell-ghost` with that path.

Example profile snippets are included under `home/`; copy the matching line into your real profile file.

## Harness skill

The project includes a portable meta skill at `skills/shell_ghost`. Install or register that skill in any LLM agent environment that supports project skills or custom instructions, such as Codex, Claude Code, or Copilot.

The skill is intentionally thin: it routes the harness to this cloned repo, `AGENTS.md`, and the profile-based `load_env` setup. It does not contain private memory or machine-specific state.

Typical installation pattern:

1. Copy or symlink `skills/shell_ghost` into the agent environment's skill directory.
2. Enable the skill name `shell_ghost` in that environment.
3. Add the `load_env` source line to the user's shell profile so the session is marked as a Shell Ghost environment and Shell Ghost scripts are available on `PATH`.

## Commands after profile setup

| Purpose | Unix shell | PowerShell |
| --- | --- | --- |
| Print agent context | `load_context.sh normal` | `load_context.ps1 -Mode normal` |
| Manage priority queue | `job_queue.sh push 10 "task"` | `job_queue.ps1 push 10 "task"` |
| Create memory note | `echo "body" \| new_memory.sh --path MEMORY/example.md --tag example` | `"body" \| new_memory.ps1 -Path MEMORY/example.md -Tag example` |
| Check memory headers | `check_memory_template_integrity.sh` | `check_memory_template_integrity.ps1` |
| Search by tags | `tag_search.sh "ops && shell"` | `tag_search.ps1 "ops && shell"` |
| Build tag list | `tag_list_build.sh -o tag_list.txt` | `tag_list_build.ps1 -Output tag_list.txt` |

## Recommended tools

Shell Ghost assumes a small, practical command-line baseline. It recommends tools such as `rg`, `fd`, and `busybox` at the instruction level, but it does not vendor or prescribe exact binary builds. Install compatible versions through the user's normal OS or package-manager flow.

## Runtime data

Generated local state is intentionally ignored by git:

- `MEMORY/` and `MEMORY.md` for local memory
- `queue/` for job queue state
- `tmp/` for scratch notes
- `tag_list.txt` for generated tag indexes

Use `memory_root_list.txt` to allow additional memory roots. The default root is `MEMORY`.
