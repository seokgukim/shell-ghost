#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/workflow_utils.sh"

usage() {
  echo 'Usage: tag_search.sh "tag1 && tag2 | tag3"' >&2
  echo '   or: tag_search.sh [--and|--or] tag1 [tag2 ...]' >&2
  exit 1
}

tag_in_list() {
  needle=$1
  tags=$2
  printf '%s\n' "$tags" | grep -Fx -- "$needle" >/dev/null 2>&1
}

match_mode() {
  mode=$1
  tags=$2
  shift 2
  case "$mode" in
    and)
      for q in "$@"; do tag_in_list "$q" "$tags" || return 1; done
      return 0
      ;;
    or)
      for q in "$@"; do tag_in_list "$q" "$tags" && return 0; done
      return 1
      ;;
  esac
}

match_expr() {
  tags=$1
  shift
  ok=''
  op=''
  for tok in "$@"; do
    case "$tok" in '&&'|'|') op=$tok; continue ;; esac
    tok=$(printf '%s' "$tok" | sg_lower)
    if tag_in_list "$tok" "$tags"; then val=1; else val=0; fi
    if [ -z "$ok" ]; then ok=$val
    elif [ "$op" = '&&' ]; then
      if [ "$ok" -eq 1 ] && [ "$val" -eq 1 ]; then ok=1; else ok=0; fi
    else
      if [ "$ok" -eq 1 ] || [ "$val" -eq 1 ]; then ok=1; else ok=0; fi
    fi
    op=''
  done
  [ "${ok:-0}" -eq 1 ]
}

tokenize_expr() {
  printf '%s\n' "$1" | sed 's/&&/ \&\& /g; s/|/ | /g' | tr ' ' '\n' | sed '/^$/d'
}

[ "$#" -gt 0 ] || usage
case "$1" in -h|--help) usage ;; esac
root_prefix=$(sg_workspace_root)
roots=$(sg_allowed_roots "$root_prefix")

mode=expr
query=''
if [ "$1" = '--and' ] || [ "$1" = '--or' ]; then
  mode=${1#--}
  shift
  [ "$#" -gt 0 ] || usage
  for q in "$@"; do
    q=$(sg_trim "$q" | sg_lower)
    [ -n "$q" ] && query="${query}${query:+
}$q"
  done
else
  expr=$*
  [ -n "$(sg_trim "$expr")" ] || usage
  query=$(tokenize_expr "$expr")
fi
[ -n "$query" ] || { echo 'No tags provided' >&2; exit 1; }

sg_memory_files "$root_prefix" "$roots" | while IFS= read -r file; do
  [ -n "$file" ] || continue
  tags=$(sg_tags_from_file "$file" || true)
  [ -n "$tags" ] || continue
  if [ "$mode" = expr ]; then
    # shellcheck disable=SC2086
    if match_expr "$tags" $query; then sg_output_memory_path "$file" "$root_prefix"; fi
  else
    # shellcheck disable=SC2086
    if match_mode "$mode" "$tags" $query; then sg_output_memory_path "$file" "$root_prefix"; fi
  fi
done
