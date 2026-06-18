#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
AGENT=""
INCLUDE_XCODEBUILDMCP_INIT=0

usage() {
  cat <<'EOF'
Usage: bootstrap-ios-skills.sh [--dry-run] [--agent cursor|codex|claude-code|droid] [--include-xcodebuildmcp-init]

Installs the public GitHub-hosted iOS agent skill packs referenced by bootstrap-ios.
Dry-run first before modifying an agent environment. Installs globally and skips
interactive prompts after you choose to run without --dry-run.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --agent)
      AGENT="${2:-}"
      if [[ -z "$AGENT" ]]; then
        echo "--agent requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --include-xcodebuildmcp-init)
      INCLUDE_XCODEBUILDMCP_INIT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

skill_urls=(
  "https://github.com/twostraws/SwiftUI-Agent-Skill/tree/main/swiftui-pro"
  "https://github.com/twostraws/Swift-Concurrency-Agent-Skill/tree/main/swift-concurrency-pro"
  "https://github.com/twostraws/Swift-Testing-Agent-Skill/tree/main/swift-testing-pro"
  "https://github.com/twostraws/SwiftData-Agent-Skill/tree/main/swiftdata-pro"
  "https://github.com/AvdLee/SwiftUI-Agent-Skill/tree/main/swiftui-expert-skill"
  "https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/tree/main/swift-concurrency"
  "https://github.com/AvdLee/Swift-Testing-Agent-Skill/tree/main/swift-testing-expert"
  "https://github.com/AvdLee/Core-Data-Agent-Skill/tree/main/core-data-expert"
)

full_depth_skill_urls=(
  "https://github.com/AvdLee/Xcode-Build-Optimization-Agent-Skill"
)

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

agent_args=()
if [[ -n "$AGENT" ]]; then
  agent_args=(-a "$AGENT")
fi

for url in "${skill_urls[@]}"; do
  run_cmd npx skills add "$url" --global --yes "${agent_args[@]}"
done

for url in "${full_depth_skill_urls[@]}"; do
  run_cmd npx skills add "$url" --full-depth --global --yes "${agent_args[@]}"
done

echo
echo "XcodeBuildMCP is recommended for build/test/simulator work."
echo "Install one of:"
echo "  brew tap getsentry/xcodebuildmcp && brew install xcodebuildmcp"
echo "  npm install -g xcodebuildmcp@latest"

if [[ "$INCLUDE_XCODEBUILDMCP_INIT" -eq 1 ]]; then
  run_cmd npx -y xcodebuildmcp@latest init
else
  echo "Optional agent skills init:"
  echo "  npx -y xcodebuildmcp@latest init"
fi
