#!/usr/bin/env sh

set -eu

MODE="${1:-normal}"

ROOT="${SHELL_GHOST_ROOT:-${SHELL_GHOST:-}}"
if [ -z "$ROOT" ]; then
  ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd) || ROOT=""
fi
if [ -z "$ROOT" ]; then
  printf '%s\n' "[load-context] missing SHELL_GHOST_ROOT/SHELL_GHOST" >&2
  exit 1
fi

SHELL_GHOST_ROOT="${SHELL_GHOST_ROOT:-$ROOT}"
SHELL_GHOST="${SHELL_GHOST:-$ROOT}"
SHELL_GHOST_MEMORY="${SHELL_GHOST_MEMORY:-$ROOT/MEMORY}"
SHELL_GHOST_QUEUE="${SHELL_GHOST_QUEUE:-$ROOT/queue}"

emit_file() {
  if [ -f "$1" ]; then
    cat "$1"
  fi
  return 0
}

emit_base_context() {
  emit_file "$ROOT/AGENTS.md"
  emit_file "$ROOT/TOOLS.md"
}

print_env_snapshot() {
  printf '\n%s\n' "# SHELL GHOST ENV (load mode)"
  for key in \
    SHELL_GHOST_ROOT \
    SHELL_GHOST \
    SHELL_GHOST_ENV \
    SHELL_GHOST_MEMORY \
    SHELL_GHOST_QUEUE \
    SHELL_GHOST_WORKSPACE \
    PROJECTS \
    HOME
  do
    eval "value=\${$key-}"
    if [ -n "${value}" ]; then
      printf '%s=%s\n' "$key" "$value"
    fi
  done
}

case "$MODE" in
  min)
    emit_file "$ROOT/AGENTS.md"
    ;;
  normal)
    emit_base_context
    print_env_snapshot
    ;;
  full)
    emit_base_context

    printf '\n%s\n' "# MEMORY INDEX (full mode)"
    emit_file "$ROOT/MEMORY.md"

    printf '\n%s\n' "# MEMORY HUBS (full mode)"
    hubs_found=0
    hubs_list=''
    if [ -d "$ROOT/MEMORY" ]; then
      hubs_list=$(find "$ROOT/MEMORY" -maxdepth 1 -type f -name 'HUB_*.md' 2>/dev/null | sort)
    fi
    if [ -n "$hubs_list" ]; then
      hubs_found=1
      printf '%s\n' "$hubs_list" | while IFS= read -r hub; do
        [ -n "$hub" ] && cat "$hub"
      done
    fi
    if [ "$hubs_found" -eq 0 ]; then
      printf '%s\n' "[load-context] no hubs found" >&2
    fi

    print_env_snapshot
    ;;
  *)
    printf '%s\n' "usage: load_context.sh [min|normal|full]" >&2
    exit 2
    ;;
esac
