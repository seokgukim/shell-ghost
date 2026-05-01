#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/workflow_utils.sh"

root=$(sg_workspace_root)
output=''

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      [ "$#" -ge 2 ] || { echo 'Missing value for --root' >&2; exit 1; }
      root=$2
      shift 2
      ;;
    --output|-o)
      [ "$#" -ge 2 ] || { echo 'Missing value for --output' >&2; exit 1; }
      output=$2
      shift 2
      ;;
    -h|--help)
      echo 'Usage: tag_list_build.sh [--root ROOT] [--output FILE]' >&2
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

roots=$(sg_allowed_roots "$root")
tags=$(
  sg_memory_files "$root" "$roots" |
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      sg_tags_from_file "$file" || true
    done |
    sort -u
)

if [ -n "$output" ]; then
  printf '%s\n' "$tags" > "$output"
else
  printf '%s\n' "$tags"
fi
