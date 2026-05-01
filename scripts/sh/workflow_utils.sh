#!/usr/bin/env sh
set -eu

sg_workspace_root() {
  if [ -n "${SHELL_GHOST_WORKSPACE:-}" ]; then printf '%s\n' "$SHELL_GHOST_WORKSPACE"
  elif [ -n "${SHELL_GHOST:-}" ]; then printf '%s\n' "$SHELL_GHOST"
  elif [ -n "${SHELL_GHOST_ROOT:-}" ]; then printf '%s\n' "$SHELL_GHOST_ROOT"
  else pwd
  fi
}

sg_trim() {
  printf '%s' "${1:-}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

sg_lower() {
  tr '[:upper:]' '[:lower:]'
}

sg_json_array_to_lines() {
  if ! command -v jq >/dev/null 2>&1; then
    echo 'ERROR: jq is required to parse JSON arrays' >&2
    return 2
  fi
  printf '%s\n' "$1" | jq -r 'if type != "array" then error("JSON value is not an array") else .[] | select(. != null) | tostring end'
}

sg_add_item_lines() {
  old="${1:-}"
  raw="$(sg_trim "${2:-}")"
  [ -n "$old" ] && printf '%s\n' "$old"
  [ -z "$raw" ] && return 0
  case "$raw" in
    \[*\]) sg_json_array_to_lines "$raw" | while IFS= read -r line; do line="$(sg_trim "$line")"; [ -n "$line" ] && printf '%s\n' "$line"; done ;;
    *) printf '%s\n' "$raw" ;;
  esac
}

sg_format_list_from_lines() {
  out=''
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    if [ -z "$out" ]; then out="$item"; else out="$out, $item"; fi
  done
  if [ -z "$out" ]; then printf '[]'; else printf '[%s]' "$out"; fi
}

sg_gen_uuid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid; return 0; fi
  if command -v uuidgen >/dev/null 2>&1; then uuidgen; return 0; fi
  if [ -r /dev/urandom ] && command -v od >/dev/null 2>&1; then
    hex=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    if [ "${#hex}" -eq 32 ]; then
      p1=$(printf '%s\n' "$hex" | sed 's/^\(........\).*/\1/')
      p2=$(printf '%s\n' "$hex" | sed 's/^........\(....\).*/\1/')
      p3_tail=$(printf '%s\n' "$hex" | sed 's/^.............\(...\).*/\1/')
      variant_nibble=$(printf '%s\n' "$hex" | sed 's/^................\(.\).*/\1/')
      p4_tail=$(printf '%s\n' "$hex" | sed 's/^.................\(...\).*/\1/')
      p5=$(printf '%s\n' "$hex" | sed 's/^....................\(............\).*/\1/')
      case "$variant_nibble" in
        [0123]) variant=8 ;;
        [4567]) variant=9 ;;
        [89aAbB]) variant=a ;;
        *) variant=b ;;
      esac
      printf '%s-%s-4%s-%s%s-%s\n' "$p1" "$p2" "$p3_tail" "$variant" "$p4_tail" "$p5"
      return 0
    fi
  fi
  echo 'ERROR: no UUID source available (/proc, uuidgen, or /dev/urandom+od)' >&2
  return 1
}

sg_allowed_roots() {
  root_prefix="$1"
  roots_file="$root_prefix/memory_root_list.txt"
  if [ -f "$roots_file" ]; then
    roots="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$roots_file")"
  else
    roots=''
  fi
  if [ -z "$roots" ]; then
    echo "WARNING: $roots_file missing/empty; defaulting to MEMORY" >&2
    printf '%s\n' MEMORY
  else
    printf '%s\n' "$roots"
  fi
}

sg_root_allowed() {
  root="$1"
  roots="$2"
  printf '%s\n' "$roots" | grep -Fx -- "$root" >/dev/null 2>&1
}

sg_resolve_memory_path() {
  path="$1"
  root_prefix="$2"
  roots="$3"
  raw="$(sg_trim "$path")"
  [ -n "$raw" ] || { echo 'ERROR: path is empty' >&2; return 2; }
  case "$raw" in
    "$root_prefix"/*)
      prefix="$root_prefix/"
      rel=${raw#$prefix}
      printf '%s/%s\n' "$root_prefix" "$rel"
      return 0
      ;;
  esac
  case "$raw" in
    /*) rel=${raw#/} ;;
    *) rel=$raw ;;
  esac
  root=${rel%%/*}
  if ! sg_root_allowed "$root" "$roots"; then
    echo "ERROR: --path root '$root' not allowed (see $root_prefix/memory_root_list.txt)" >&2
    return 2
  fi
  printf '%s/%s\n' "$root_prefix" "$rel"
}

sg_tags_from_file() {
  path="$1"
  [ -f "$path" ] || return 1
  sed -n '1,8p' "$path" |
    sed -n 's/^[[:space:]]*tags:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p' |
    sed 1q |
    tr ',' '\n' |
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
    sg_lower |
    sed '/^$/d'
}

sg_memory_files() {
  root_prefix="$1"
  roots="$2"
  [ -f "$root_prefix/MEMORY.md" ] && printf '%s\n' "$root_prefix/MEMORY.md"
  printf '%s\n' "$roots" | while IFS= read -r root; do
    [ -n "$root" ] || continue
    base="$root_prefix/$root"
    [ -d "$base" ] || continue
    find "$base" -type f -name '*.md' 2>/dev/null
  done
}

sg_output_memory_path() {
  path="$1"
  root_prefix="$2"
  case "$path" in
    "$root_prefix"/*)
      prefix="$root_prefix/"
      rel=${path#$prefix}
      printf '/%s\n' "$rel"
      ;;
  esac
}
