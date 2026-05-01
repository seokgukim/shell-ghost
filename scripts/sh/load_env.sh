#!/usr/bin/env sh

load_env_script_path() {
  if [ -n "${BASH_SOURCE:-}" ]; then
    printf '%s\n' "$BASH_SOURCE"
    return 0
  fi
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval 'printf "%s\n" "${(%):-%x}"'
    return 0
  fi
  printf '%s\n' "$0"
}

resolve_root() {
  script=$(load_env_script_path)
  root=$(CDPATH= cd -- "$(dirname -- "$script")/../.." 2>/dev/null && pwd) && { printf '%s\n' "$root"; return 0; }
  if [ -n "${SHELL_GHOST_ROOT:-}" ]; then printf '%s\n' "$SHELL_GHOST_ROOT"; return 0; fi
  if [ -n "${SHELL_GHOST:-}" ]; then printf '%s\n' "$SHELL_GHOST"; return 0; fi
}

prepend_path_once() {
  candidate=$1
  [ -d "$candidate" ] || return 0
  case ":$PATH:" in
    *":$candidate:"*) ;;
    *) PATH="$candidate:$PATH" ;;
  esac
}

ROOT=$(resolve_root) || { echo '[load-env] unable to resolve repository root' >&2; return 1 2>/dev/null || exit 1; }
SHELL_GHOST_ROOT=$ROOT
SHELL_GHOST=$ROOT
SHELL_GHOST_ENV=1
SHELL_GHOST_MEMORY=$ROOT/MEMORY
SHELL_GHOST_QUEUE=$ROOT/queue

prepend_path_once "$ROOT/scripts/sh"
prepend_path_once "$ROOT/scripts/pwsh"
prepend_path_once "$ROOT/scripts"

export SHELL_GHOST_ROOT SHELL_GHOST SHELL_GHOST_ENV SHELL_GHOST_MEMORY SHELL_GHOST_QUEUE PATH
