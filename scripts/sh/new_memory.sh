#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/workflow_utils.sh"

usage() {
  cat <<'USAGE' >&2
Usage:
  new_memory.sh [--path PATH] [--related UUID|JSON_ARRAY]... [--tag TAG|JSON_ARRAY]...
USAGE
}

path=''
related_lines=''
tag_lines=''

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then echo 'Missing value for --path' >&2; usage; exit 1; fi
      path=$2
      shift 2
      ;;
    --related)
      if [ "$#" -lt 2 ]; then echo 'Missing value for --related' >&2; usage; exit 1; fi
      related_lines=$(sg_add_item_lines "$related_lines" "$2")
      shift 2
      ;;
    --tag)
      if [ "$#" -lt 2 ]; then echo 'Missing value for --tag' >&2; usage; exit 1; fi
      tag_lines=$(sg_add_item_lines "$tag_lines" "$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

out_path=''
if [ -n "$path" ]; then
  root_prefix=$(sg_workspace_root)
  roots=$(sg_allowed_roots "$root_prefix")
  out_path=$(sg_resolve_memory_path "$path" "$root_prefix" "$roots")
fi

uuid=$(sg_gen_uuid)
related_yaml=$(printf '%s\n' "$related_lines" | sg_format_list_from_lines)
tags_yaml=$(printf '%s\n' "$tag_lines" | sg_format_list_from_lines)

if [ -n "$out_path" ]; then
  dir=$(dirname -- "$out_path")
  mkdir -p "$dir"
  printf 'guid: %s\nrelated: %s\ntags: %s\n\n' "$uuid" "$related_yaml" "$tags_yaml" > "$out_path"
  cat >> "$out_path"
else
  printf 'guid: %s\nrelated: %s\ntags: %s\n\n' "$uuid" "$related_yaml" "$tags_yaml"
  cat
fi
