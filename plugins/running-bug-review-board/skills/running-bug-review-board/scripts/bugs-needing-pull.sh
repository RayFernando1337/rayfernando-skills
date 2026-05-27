#!/usr/bin/env bash
#
# bugs-needing-pull.sh — list bug markdown files whose Tracker /
# lastSyncedAt is stale (older than the threshold) or missing, meaning
# they should be pulled from the configured issue tracker.
#
# Usage:
#   bash bugs-needing-pull.sh REPO_ROOT [--threshold 24h] [--tracker linear|github|jira|notion]
#
# Threshold accepts h (hours) or d (days). Default 24h.
#
# Prints (one per line):
#   <bug-id>\t<tracker-id>\t<lastSyncedAt-or-MISSING>\t<path>
#
# The agent reads the list and runs the appropriate read call per
# references/issue-trackers.md § Bi-directional sync.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 REPO_ROOT [--threshold 24h] [--tracker auto|linear|github|jira|notion]" >&2
  exit 1
fi

REPO_ROOT="$1"
shift

THRESHOLD="24h"
TRACKER="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)   THRESHOLD="$2"; shift 2 ;;
    --threshold=*) THRESHOLD="${1#*=}"; shift ;;
    --tracker)     TRACKER="$2"; shift 2 ;;
    --tracker=*)   TRACKER="${1#*=}"; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Convert threshold to seconds.
case "$THRESHOLD" in
  *h) THRESHOLD_SEC=$(( ${THRESHOLD%h} * 3600 )) ;;
  *d) THRESHOLD_SEC=$(( ${THRESHOLD%d} * 86400 )) ;;
  *)  echo "Threshold must end in h or d (e.g. 24h, 7d)" >&2; exit 1 ;;
esac

CONFIG="$REPO_ROOT/docs/qa/qa-config.json"
BUGS_DIR="$REPO_ROOT/docs/qa/bug-reports"

if [[ ! -d "$BUGS_DIR" ]]; then
  echo "No bug-reports directory found: $BUGS_DIR" >&2
  exit 0
fi

if [[ "$TRACKER" == "auto" ]]; then
  if [[ -f "$CONFIG" ]] && command -v jq >/dev/null; then
    TRACKER=$(jq -r '.issueTracker.type // "none"' "$CONFIG")
  else
    TRACKER="none"
  fi
fi

if [[ "$TRACKER" == "none" || -z "$TRACKER" ]]; then
  echo "Tracker is 'none' — nothing to pull." >&2
  exit 0
fi

case "$TRACKER" in
  linear) TRACKER_LABEL="Tracker / Linear" ;;
  github) TRACKER_LABEL="Tracker / GitHub" ;;
  jira)   TRACKER_LABEL="Tracker / Jira"   ;;
  notion) TRACKER_LABEL="Tracker / Notion" ;;
  *) echo "Unknown tracker: $TRACKER" >&2; exit 1 ;;
esac

NOW_EPOCH=$(date +%s)

iso_to_epoch() {
  # Convert ISO-8601 (e.g. 2026-05-27T18:23:00Z) to epoch seconds.
  # Try GNU date first, then BSD date (macOS) as fallback.
  local iso="$1"
  if date -u -d "$iso" +%s >/dev/null 2>&1; then
    date -u -d "$iso" +%s
  else
    # macOS: strip the trailing Z and use the explicit format.
    local clean="${iso%Z}"
    date -u -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null || echo ""
  fi
}

shopt -s nullglob
for bug_file in "$BUGS_DIR"/BUG-*.md; do
  base="$(basename "$bug_file")"
  [[ "$base" == "_template.md" ]] && continue
  bug_id="$(echo "$base" | sed -E 's/^(BUG-[0-9]+).*\.md$/\1/')"

  # Only consider bugs that already have a tracker ID (an empty tracker
  # row means "needs push", handled by bugs-needing-sync.sh).
  tracker_id=$(awk -F'|' -v label="**$TRACKER_LABEL**" '
    $2 ~ ("^[[:space:]]*" label "[[:space:]]*$") {
      v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit
    }
  ' "$bug_file")

  if [[ -z "$tracker_id" || "$tracker_id" =~ ^\*\(.+\)\*$ ]]; then
    continue  # Needs push, not pull.
  fi

  last_synced=$(awk -F'|' '
    $2 ~ /^[[:space:]]*\*\*Tracker \/ lastSyncedAt\*\*[[:space:]]*$/ {
      v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v; exit
    }
  ' "$bug_file")

  rel_path="${bug_file#$REPO_ROOT/}"

  if [[ -z "$last_synced" || "$last_synced" =~ ^\*\(.+\)\*$ ]]; then
    printf '%s\t%s\t%s\t%s\n' "$bug_id" "$tracker_id" "MISSING" "$rel_path"
    continue
  fi

  last_epoch=$(iso_to_epoch "$last_synced")
  if [[ -z "$last_epoch" ]]; then
    # Unparseable timestamp — treat as stale so the agent re-syncs.
    printf '%s\t%s\t%s\t%s\n' "$bug_id" "$tracker_id" "UNPARSEABLE($last_synced)" "$rel_path"
    continue
  fi

  age=$(( NOW_EPOCH - last_epoch ))
  if (( age > THRESHOLD_SEC )); then
    printf '%s\t%s\t%s\t%s\n' "$bug_id" "$tracker_id" "$last_synced" "$rel_path"
  fi
done
