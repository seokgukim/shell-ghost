#!/usr/bin/env bash
set -euo pipefail

if [ -n "${SHELL_GHOST_WORKSPACE:-}" ]; then
  QUEUE_DIR="$SHELL_GHOST_WORKSPACE/queue"
else
  ROOT_PREFIX="${SHELL_GHOST:-$(pwd)}"
  QUEUE_DIR="${SHELL_GHOST_QUEUE:-$ROOT_PREFIX/queue}"
fi
QUEUE_FILE="$QUEUE_DIR/queue.md"
HISTORY_FILE="$QUEUE_DIR/history.md"

ensure_files() {
  mkdir -p "$QUEUE_DIR"
  touch "$QUEUE_FILE" "$HISTORY_FILE"
}

is_empty() {
  [ ! -s "$QUEUE_FILE" ]
}

push_item() {
  local priority="$1"
  shift
  local content="$*"

  if ! [[ "$priority" =~ ^[0-9]+$ ]]; then
    echo "priority must be a number" >&2
    exit 1
  fi

  if [ -z "$content" ]; then
    echo "content is required" >&2
    exit 1
  fi

  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  local line
  line="$priority $ts $content"

  if is_empty; then
    printf '%s\n' "$line" > "$QUEUE_FILE"
    return
  fi

  local insert_at
  insert_at="$(awk -v p="$priority" '{ if (($1 + 0) < p) { print NR; exit } }' "$QUEUE_FILE")"

  if [ -z "$insert_at" ]; then
    printf '%s\n' "$line" >> "$QUEUE_FILE"
    return
  fi

  local tmp
  tmp="$(mktemp "$QUEUE_DIR/queue.XXXXXX")"
  awk -v insert_at="$insert_at" -v line="$line" 'NR == insert_at { print line } { print }' "$QUEUE_FILE" > "$tmp"
  mv "$tmp" "$QUEUE_FILE"
}

peek_item() {
  if is_empty; then
    exit 1
  fi
  head -n 1 "$QUEUE_FILE"
}

pop_item() {
  if is_empty; then
    exit 1
  fi

  local top
  top="$(head -n 1 "$QUEUE_FILE")"
  printf '%s\n' "$top" >> "$HISTORY_FILE"
  printf '%s\n' "$top"
  local tmp
  tmp="$(mktemp "$QUEUE_DIR/queue.XXXXXX")"
  tail -n +2 "$QUEUE_FILE" > "$tmp"
  mv "$tmp" "$QUEUE_FILE"
}

list_items() {
  cat "$QUEUE_FILE"
}

clear_items() {
  : > "$QUEUE_FILE"
}

usage() {
  cat <<'EOF'
[CAUTION] priority is in descending order.
job_queue.sh push [priority] <content...>
job_queue.sh peek
job_queue.sh pop
job_queue.sh list
job_queue.sh clear
EOF
}

main() {
  ensure_files

  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    push)
      if [ "$#" -lt 1 ]; then
        usage
        exit 1
      fi
      local priority
      if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        priority="$1"
        shift
      else
        priority="0"
      fi

      if [ "$#" -lt 1 ]; then
        usage
        exit 1
      fi

      push_item "$priority" "$@"
      ;;
    peek)
      peek_item
      ;;
    pop)
      pop_item
      ;;
    list)
      list_items
      ;;
    clear)
      clear_items
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
