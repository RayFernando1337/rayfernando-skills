#!/usr/bin/env bash
#
# scaffold-qa.sh — Create the Bug Review Board (BRB) QA folder layout in any
# target repo. Idempotent: never overwrites an existing file.
#
# Usage:
#   bash scaffold-qa.sh REPO_ROOT [PHASE_NUM] [SLUG]
#
# Examples:
#   bash scaffold-qa.sh ~/work/my-app
#   bash scaffold-qa.sh ~/work/my-app 2
#   bash scaffold-qa.sh ~/work/my-app 2 sessions-scheduling
#
# What it creates (only if missing):
#   <REPO>/docs/qa/README.md
#   <REPO>/docs/qa/QA_GATES.md           (only if not already at <REPO>/docs/QA_GATES.md)
#   <REPO>/docs/qa/bug-reports/README.md
#   <REPO>/docs/qa/bug-reports/_template.md
#   <REPO>/docs/qa/bug-reports/assets/.gitkeep
#   <REPO>/docs/qa/runs/.gitkeep
#   <REPO>/docs/qa/phase-NN-<slug>-manual-test-plan.md   (if PHASE_NUM given)
#   <REPO>/docs/qa/runs/COORDINATOR-MERGE-YYYY-MM-DD.md  (if PHASE_NUM given)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 REPO_ROOT [PHASE_NUM] [SLUG]" >&2
  exit 1
fi

REPO_ROOT="$1"
PHASE_NUM="${2:-}"
SLUG_ARG="${3:-}"

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Error: REPO_ROOT does not exist: $REPO_ROOT" >&2
  exit 1
fi

REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
RUN_DATE=$(date +%Y-%m-%d)

# Resolve where this script lives so we can read the template files.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SKILL_DIR/references/templates"

QA_DIR="$REPO_ROOT/docs/qa"
BUGS_DIR="$QA_DIR/bug-reports"
ASSETS_DIR="$BUGS_DIR/assets"
RUNS_DIR="$QA_DIR/runs"

echo "Repo:         $REPO_ROOT"
echo "QA dir:       $QA_DIR"
echo "Run date:     $RUN_DATE"
if [[ -n "$PHASE_NUM" ]]; then
  PHASE_PADDED=$(printf "%02d" "$PHASE_NUM")
  if [[ -z "$SLUG_ARG" ]]; then
    PHASE_DOC=$(ls "$REPO_ROOT"/docs/phases/phase-${PHASE_PADDED}-*.md 2>/dev/null | head -1 || true)
    if [[ -n "$PHASE_DOC" ]]; then
      SLUG=$(basename "$PHASE_DOC" .md | sed "s/^phase-${PHASE_PADDED}-//")
    else
      SLUG="tentpole"
    fi
  else
    SLUG="$SLUG_ARG"
  fi
  echo "Phase:        $PHASE_NUM ($PHASE_PADDED)"
  echo "Slug:         $SLUG"
fi
echo

mkdir -p "$BUGS_DIR" "$ASSETS_DIR" "$RUNS_DIR"

write_if_missing() {
  # $1 = absolute path, $2 = heredoc-style contents on stdin
  if [[ -e "$1" ]]; then
    echo "  skip (exists): ${1#$REPO_ROOT/}"
    return
  fi
  cat > "$1"
  echo "  wrote: ${1#$REPO_ROOT/}"
}

copy_if_missing() {
  # $1 = template path, $2 = output path, optional sed substitutions on $3..
  if [[ -e "$2" ]]; then
    echo "  skip (exists): ${2#$REPO_ROOT/}"
    return
  fi
  if [[ ! -f "$1" ]]; then
    echo "  WARN: template missing: $1" >&2
    return
  fi
  if [[ $# -le 2 ]]; then
    cp "$1" "$2"
  else
    shift 2
    local sedargs=()
    while [[ $# -gt 0 ]]; do
      sedargs+=(-e "$1")
      shift
    done
    sed "${sedargs[@]}" "$1" > "$2" 2>/dev/null || sed "${sedargs[@]}" "$TEMPLATES_DIR/test-plan.md" > "$2"
  fi
  echo "  wrote: ${2#$REPO_ROOT/}"
}

# 1. docs/qa/README.md — entry point for QA in this repo
write_if_missing "$QA_DIR/README.md" <<'EOF'
# QA Documentation

Manual testing guides, bug reporting, and triage. Driven by the
[running-bug-review-board](https://github.com/) skill — see
`~/.agents/skills/running-bug-review-board/SKILL.md` for the full
workflow.

## Documents

| Document | Audience | Purpose |
|----------|----------|---------|
| [QA_GATES.md](./QA_GATES.md) | Engineering, QA | Pass/fail gate checklists per phase |
| [bug-reports/README.md](./bug-reports/README.md) | QA | How to file bugs and triage workflow |
| [bug-reports/_template.md](./bug-reports/_template.md) | QA | Copy for each new bug report |
| [runs/](./runs/) | QA, engineering | Per-shard run reports + coordinator merges |
| `phase-NN-<slug>-manual-test-plan.md` | QA, UAT | Step-by-step scenarios per phase |

## Workflow

```
1. Run manual test plan → 2. Mark gate or file bug → 3. Bug review (BRB)
                       → 4. Fix or defer → 5. Re-test → 6. Sign off phase
```

1. **Setup** — start dev server, mobile viewport (375px primary),
   incognito for fresh users.
2. **Execute** — Follow the phase manual test plan; check off scenarios
   as you go.
3. **Gate** — Update pass/fail in [QA_GATES.md](./QA_GATES.md).
4. **Bugs** — Copy [bug-reports/_template.md](./bug-reports/_template.md)
   → `bug-reports/BUG-NNN-short-title.md`.
5. **Review** — Engineering triages open bugs weekly (or before phase
   sign-off).

## Test environment

| Item | Value |
|------|--------|
| Local URL | http://localhost:3000 |
| Viewport | 375px minimum (mobile-first) |
| Fresh users | Incognito / private window + new test account |
| Auth test fixtures | See test-accounts reference in the skill |

## Suggested test personas

| Persona | Purpose |
|---------|---------|
| **Admin** | Creates groups, invites, manages roles |
| **Member A** | First invite signup |
| **Member B** | Second user via same multi-use invite link |

Keep test account passwords in your team's password manager — do not
commit credentials.
EOF

# 2. QA_GATES.md (only if not already present at docs/QA_GATES.md or here)
if [[ ! -e "$REPO_ROOT/docs/QA_GATES.md" ]] && [[ ! -e "$QA_DIR/QA_GATES.md" ]]; then
  write_if_missing "$QA_DIR/QA_GATES.md" <<'EOF'
# QA Gates

Consolidated test checklists for each phase. **All items must pass**
before starting the next phase (P2 exceptions documented in phase doc).

**Last QA merge:** *(none yet)*

## Bug severity guide

| Level | Definition | Action |
|-------|------------|--------|
| P0 | Blocks core flow; data loss; auth bypass | Fix immediately |
| P1 | Feature broken but workaround exists | Fix before next phase |
| P2 | Cosmetic, edge case, nice-to-have | Log; fix in polish phase |

## How to run QA

1. Validate build: typecheck + build must succeed
2. Manual tests on **mobile viewport** (375px width minimum)
3. **Detailed scenarios:** see `docs/qa/phase-NN-*-manual-test-plan.md`
4. **File bugs:** [qa/bug-reports/](./qa/bug-reports/README.md) — copy
   `_template.md` for each issue
5. Document failures in phase doc → fix P0/P1 before handoff

---

## Gate 0 — {Phase 0 name}

| # | Test | Pass |
|---|------|------|
| 0.1 | … | ☐ |

---

## Gate 1 — {Phase 1 name}

| # | Test | Pass |
|---|------|------|
| 1.1 | … | ☐ |

---

*(add more gates as phases are scoped)*
EOF
else
  echo "  skip (exists): docs/QA_GATES.md or docs/qa/QA_GATES.md"
fi

# 3. bug-reports/README.md
write_if_missing "$BUGS_DIR/README.md" <<'EOF'
# Bug reports

QA files bugs here for engineering triage. One file per bug.

## How to file a bug

1. Copy [_template.md](./_template.md) to a new file:
   ```
   docs/qa/bug-reports/BUG-001-short-kebab-title.md
   ```
2. Use the next sequential number (check existing files).
3. Fill in every section — especially **Steps to reproduce** and
   **Expected vs actual**.
4. Set **Status** to `open`.
5. Link the **Test ID** from the phase manual test plan when applicable.
6. Commit the file (or send to engineering via your team's process).

## Naming convention

```
BUG-NNN-short-description.md
```

Examples:
- `BUG-001-invite-signup-lands-on-dashboard.md`
- `BUG-002-member-can-access-settings.md`

## Status values

| Status | Meaning |
|--------|---------|
| `open` | Confirmed; not yet assigned or in progress |
| `in-progress` | Engineer actively fixing |
| `fixed` | Fix merged; awaiting QA re-test |
| `verified` | QA re-tested and closed |
| `deferred` | Accepted P2; fix in later phase (note target phase) |
| `wontfix` | By design or out of scope |

## Priority (severity)

| Level | Definition | Action |
|-------|------------|--------|
| **P0** | Blocks core flow; data loss; auth bypass | Fix before phase sign-off |
| **P1** | Feature broken but workaround exists | Fix before next phase |
| **P2** | Cosmetic, edge case, nice-to-have | Log; fix in polish phase or defer |

## Triage workflow (Bug Review Board / BRB)

1. **Weekly or pre-sign-off** — Review all `open` and `in-progress`
   bugs.
2. **Assign priority** — P0/P1 block phase completion; P2 → `deferred`
   with note in phase doc.
3. **Link fix** — PR or commit reference in bug file when `fixed`.
4. **QA re-test** — Run the linked Test ID scenario; set `verified` or
   reopen.

## Bug review agenda (suggested)

- [ ] List open P0/P1 bugs
- [ ] Any regressions on regression-matrix rows?
- [ ] Deferrals documented in phase doc **Known issues / deferrals**?
- [ ] Gate items in QA_GATES.md updated?

## Index

| ID | Title | Priority | Status | Phase |
|----|-------|----------|--------|-------|
| | | | | |

*Update this table when adding bug reports.*
EOF

# 4. bug-reports/_template.md
copy_if_missing "$TEMPLATES_DIR/bug-report.md" "$BUGS_DIR/_template.md"

# 5. assets and runs .gitkeep
[[ ! -e "$ASSETS_DIR/.gitkeep" ]] && { touch "$ASSETS_DIR/.gitkeep"; echo "  wrote: ${ASSETS_DIR#$REPO_ROOT/}/.gitkeep"; }
[[ ! -e "$RUNS_DIR/.gitkeep" ]] && { touch "$RUNS_DIR/.gitkeep"; echo "  wrote: ${RUNS_DIR#$REPO_ROOT/}/.gitkeep"; }

# 6. Phase-specific scaffolds (only if PHASE_NUM given)
if [[ -n "$PHASE_NUM" ]]; then
  TEST_PLAN="$QA_DIR/phase-${PHASE_PADDED}-${SLUG}-manual-test-plan.md"
  MERGE_STUB="$RUNS_DIR/COORDINATOR-MERGE-${RUN_DATE}.md"

  prefill() {
    if [[ -e "$2" ]]; then
      echo "  skip (exists): ${2#$REPO_ROOT/}"
      return
    fi
    if [[ ! -f "$1" ]]; then
      echo "  WARN: template missing: $1" >&2
      return
    fi
    sed \
      -e "s/{N}/$PHASE_NUM/g" \
      -e "s/{NN}/$PHASE_PADDED/g" \
      -e "s/{slug}/$SLUG/g" \
      -e "s/{PHASE_NUM}/$PHASE_NUM/g" \
      -e "s/{PHASE_NUM_PADDED}/$PHASE_PADDED/g" \
      -e "s/{YYYY-MM-DD}/$RUN_DATE/g" \
      -e "s/{RUN_DATE}/$RUN_DATE/g" \
      "$1" > "$2"
    echo "  wrote: ${2#$REPO_ROOT/}"
  }

  prefill "$TEMPLATES_DIR/test-plan.md"        "$TEST_PLAN"
  prefill "$TEMPLATES_DIR/coordinator-merge.md" "$MERGE_STUB"
fi

cat <<EOF

Done. Next steps:
  1. Open the test plan and fill scenario tables from:
       - docs/phases/phase-${PHASE_PADDED:-NN}-*.md (checkboxes / scope)
       - docs/QA_GATES.md (Gate ${PHASE_NUM:-N} items)
       - docs/PRODUCT_SPEC.md or README (user-flow context)
  2. Pick mode:
       - Parallel:   ~/.agents/skills/running-bug-review-board/references/parallel-coordinator.md
       - Sequential: ~/.agents/skills/running-bug-review-board/references/sequential-wrapup.md
  3. Per-shard reports go to docs/qa/runs/QA-<letter>-run-${RUN_DATE}.md
     (template: ~/.agents/skills/running-bug-review-board/references/templates/run-report.md)
  4. Final verdict goes in docs/qa/runs/COORDINATOR-MERGE-${RUN_DATE}.md
EOF
