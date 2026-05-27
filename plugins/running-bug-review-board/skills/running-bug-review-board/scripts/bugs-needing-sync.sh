#!/usr/bin/env bash
#
# bugs-needing-sync.sh — list bug markdown files whose Tracker / <Type>
# front-matter row is empty, meaning they need to be pushed to the
# configured issue tracker.
#
# Usage:
#   bash bugs-needing-sync.sh REPO_ROOT [--tracker linear|github|jira|notion]
#
# Prints (one per line):
#   <bug-id>\t<title>\t<priority>\t<status>\t<path>
#
# The agent reads the list and runs the appropriate tracker call (Linear
# MCP, `gh issue create`, etc.) per references/issue-trackers.md. This
# helper only enumerates; it never calls a tracker itself.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 REPO_ROOT [--tracker linear|github|jira|notion]" >&2
  exit 1
fi

REPO_ROOT="$1"
shift

TRACKER="auto"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tracker) TRACKER="$2"; shift 2 ;;
    --tracker=*) TRACKER="${1#*=}"; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "REPO_ROOT does not exist: $REPO_ROOT" >&2
  exit 1
fi

CONFIG="$REPO_ROOT/docs/qa/qa-config.json"
BUGS_DIR="$REPO_ROOT/docs/qa/bug-reports"

if [[ ! -d "$BUGS_DIR" ]]; then
  echo "No bug-reports directory found: $BUGS_DIR" >&2
  exit 0
fi

# Resolve tracker type from config if auto.
if [[ "$TRACKER" == "auto" ]]; then
  if [[ -f "$CONFIG" ]] && command -v jq >/dev/null; then
    TRACKER=$(jq -r '.issueTracker.type // "none"' "$CONFIG")
  else
    TRACKER="none"
  fi
fi

if [[ "$TRACKER" == "none" || -z "$TRACKER" ]]; then
  echo "Tracker is 'none' — nothing to sync." >&2
  exit 0
fi

# Map tracker -> the front-matter label this script looks for.
case "$TRACKER" in
  linear) LABEL="Tracker / Linear" ;;
  github) LABEL="Tracker / GitHub" ;;
  jira)   LABEL="Tracker / Jira"   ;;
  notion) LABEL="Tracker / Notion" ;;
  *) echo "Unknown tracker: $TRACKER" >&2; exit 1 ;;
esac

# Walk bug files (excluding the template) and check each for an empty
# (or placeholder) tracker row.
shopt -s nullglob
for bug_file in "$BUGS_DIR"/BUG-*.md; do
  base="$(basename "$bug_file")"
  [[ "$base" == "_template.md" ]] && continue

  bug_id="$(echo "$base" | sed -E 's/^(BUG-[0-9]+).*\.md$/\1/')"

  # Extract the tracker row's value (between the second and third `|`).
  # Empty value or value enclosed in *(...)* placeholder both mean
  # "needs sync".
  value=$(awk -F'|' -v label="**$LABEL**" '
    $2 ~ ("^[[:space:]]*" label "[[:space:]]*$") {
      v = $3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      print v
      exit
    }
  ' "$bug_file")

  needs_sync=0
  if [[ -z "$value" ]]; then
    needs_sync=1
  elif [[ "$value" =~ ^\*\(.+\)\*$ ]]; then
    # Template placeholder like *(LIN-1234 — fill after sync; blank if N/A)*
    needs_sync=1
  fi

  if [[ "$needs_sync" -eq 1 ]]; then
    title=$(awk -F'|' '/^[[:space:]]*\*\*Summary\*\*/ { v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit }' "$bug_file" || true)
    if [[ -z "$title" ]]; then
      # Fallback: first H1 / "# BUG-NNN: ..." line
      title=$(awk '/^# / { sub(/^# /, "", $0); print; exit }' "$bug_file")
    fi
    priority=$(awk -F'|' '/^[[:space:]]*\*\*Priority\*\*/ { v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit }' "$bug_file" || echo "")
    status=$(awk -F'|' '/^[[:space:]]*\*\*Status\*\*/ { v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit }' "$bug_file" || echo "")
    rel_path="${bug_file#$REPO_ROOT/}"
    printf '%s\t%s\t%s\t%s\t%s\n' "$bug_id" "$title" "$priority" "$status" "$rel_path"
  fi
done
