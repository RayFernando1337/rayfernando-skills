#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
AGENT=""
INCLUDE_XCODEBUILDMCP_INIT=0
SKIP_VERIFY=0

usage() {
  cat <<'EOF'
Usage: bootstrap-ios-skills.sh [--dry-run] [--agent cursor|codex|claude-code|droid] [--include-xcodebuildmcp-init] [--skip-verify]

Installs the public GitHub-hosted iOS agent skill packs referenced by bootstrap-ios.
Dry-run first before modifying an agent environment. Installs globally and skips
interactive prompts after you choose to run without --dry-run.

After a real install, the script verifies every expected skill actually
landed (SKILL.md present under a known skill root) and is complete (every
references/, scripts/, and assets/ file it cites actually on disk). It exits
non-zero if any skill is missing entirely or installed shallow.
Pass --skip-verify to opt out.
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
    --skip-verify)
      SKIP_VERIFY=1
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

# Skill folder basenames the URLs above install. The full-depth build
# optimization pack expands to the six xcode-*/spm-* skills.
expected_skills=(
  swiftui-pro
  swift-concurrency-pro
  swift-testing-pro
  swiftdata-pro
  swiftui-expert-skill
  swift-concurrency
  swift-testing-expert
  core-data-expert
  xcode-build-orchestrator
  xcode-build-fixer
  xcode-build-benchmark
  xcode-compilation-analyzer
  xcode-project-analyzer
  spm-build-analysis
)

# Global skill directories the supported agents read.
skill_roots=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.cursor/skills-cursor"
  "$HOME/.codex/skills"
  "$HOME/.factory/skills"
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

# Verify a single installed skill folder: every relative references/, scripts/,
# or assets/ path cited in its SKILL.md must exist on disk. Returns non-zero
# and prints MISSING lines if the install is shallow.
verify_skill_dir() {
  local dir="$1"
  local ok=0
  local rel
  while IFS= read -r rel; do
    if [[ ! -e "$dir/$rel" ]]; then
      echo "MISSING: $dir/$rel" >&2
      ok=1
    fi
  done < <(grep -oE '(references|scripts|assets)/[A-Za-z0-9._/-]+\.[A-Za-z0-9]+' "$dir/SKILL.md" | sort -u)
  return "$ok"
}

verify_installs() {
  local failed=0
  local name root dir found
  for name in "${expected_skills[@]}"; do
    found=0
    for root in "${skill_roots[@]}"; do
      dir="$root/$name"
      [[ -f "$dir/SKILL.md" ]] || continue
      found=1
      if ! verify_skill_dir "$dir"; then
        echo "SHALLOW INSTALL: $dir cites files that were not installed." >&2
        failed=1
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      echo "NOT INSTALLED: $name has no SKILL.md under any known skill root." >&2
      failed=1
    fi
  done
  if [[ "$failed" -ne 0 ]]; then
    cat >&2 <<'EOF'

One or more skills are missing entirely or installed without their reference
files. A missing skill means the installer exited zero without laying it down;
a shallow one makes agents load SKILL.md, follow a references/ pointer, and
silently degrade. Re-install the affected skill with:

  npx skills add <skill-url> --global --yes --full-depth

or clone the upstream repo and copy the skill folder (SKILL.md + references/
+ scripts/) into your agent's skills directory manually.
EOF
    return 1
  fi
  echo "Verified: installed skills have all cited reference files."
}

agent_args=()
if [[ -n "$AGENT" ]]; then
  agent_args=(-a "$AGENT")
fi

for url in "${skill_urls[@]}"; do
  run_cmd npx skills add "$url" --global --yes ${agent_args[@]+"${agent_args[@]}"}
done

for url in "${full_depth_skill_urls[@]}"; do
  run_cmd npx skills add "$url" --full-depth --global --yes ${agent_args[@]+"${agent_args[@]}"}
done

if [[ "$DRY_RUN" -eq 0 && "$SKIP_VERIFY" -eq 0 ]]; then
  verify_installs
fi

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
