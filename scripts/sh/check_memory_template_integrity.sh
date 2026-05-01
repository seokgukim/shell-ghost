#!/usr/bin/env sh

set -eu

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
  printf '%s\n' "Usage: check_memory_template_integrity.sh [MEMORY_DIR]"
  printf '%s\n' "Default MEMORY_DIR: \$SHELL_GHOST_MEMORY or \$SHELL_GHOST/MEMORY"
  exit 0
fi

if [ -n "${1-}" ]; then
  MEMORY_DIR="$1"
elif [ -n "${SHELL_GHOST_MEMORY-}" ]; then
  MEMORY_DIR="$SHELL_GHOST_MEMORY"
elif [ -n "${SHELL_GHOST-}" ]; then
  MEMORY_DIR="$SHELL_GHOST/MEMORY"
else
  printf '%s\n' "Error: pass MEMORY_DIR or set SHELL_GHOST_MEMORY/SHELL_GHOST." >&2
  exit 1
fi

if [ ! -d "$MEMORY_DIR" ]; then
  printf '%s\n' "Error: MEMORY_DIR not found: $MEMORY_DIR" >&2
  exit 1
fi

tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT HUP INT TERM

find "$MEMORY_DIR" -type f -name '*.md' | sort > "$tmp_list"

total=0
failed=0

while IFS= read -r file_path; do
  [ -n "$file_path" ] || continue

  case "$file_path" in
    */thoughts/*|*/notes/*) continue ;;
  esac

  total=$((total + 1))

  line1="$(head -n 1 "$file_path" 2>/dev/null || true)"
  line2="$(head -n 2 "$file_path" 2>/dev/null | tail -n 1 || true)"
  line3="$(head -n 3 "$file_path" 2>/dev/null | tail -n 1 || true)"

  ok=1
  case "$line1" in
    guid:\ *) ;;
    *) ok=0 ;;
  esac
  case "$line2" in
    related:\ *) ;;
    *) ok=0 ;;
  esac
  case "$line3" in
    tags:\ *) ;;
    *) ok=0 ;;
  esac

  if [ "$ok" -eq 0 ]; then
    failed=$((failed + 1))
    printf '%s\n' "FAIL $file_path"
    printf '%s\n' "  1> ${line1:-<empty>}"
    printf '%s\n' "  2> ${line2:-<empty>}"
    printf '%s\n' "  3> ${line3:-<empty>}"
  fi
done < "$tmp_list"

printf '%s\n' "checked=$total failed=$failed memory_dir=$MEMORY_DIR"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
