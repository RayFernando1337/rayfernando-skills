# Changelog

All notable changes to this collection are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] — 2026-06-15

### Added

- **`parallel-orchestrate` — an orchestrator-worker skill for fanning
  one big task out to a team of agents.** The lead agent discovers the
  shape of the work, verifies coverage, splits it into independent
  slices, fans them out to parallel workers, verifies each structured
  handoff, and synthesizes one deliverable. Built for large research,
  analysis, audits, and codebase or data exploration where a single
  linear pass would be slow.
- **Two tool-tuned variants with different prompts.**
  `parallel-orchestrate` (for **Cursor**) is built around the `Task`
  tool and Multitask Mode — local subagents on a shared filesystem.
  `parallel-orchestrate-codex` (for **Codex**) is built around Codex
  subagents, `spawn_agents_on_csv`, `config.toml` limits, and
  `codex exec` fleets; it ships an `agents/openai.yaml` and a
  `recommended-config.md` for role and concurrency setup. Both share
  the same orchestrator-worker principles and verified-handoff
  discipline (`references/handoff-format.md`,
  `references/verification.md`).
- **Marketplace catalog updated.** Both plugins are registered in
  `.claude-plugin/marketplace.json`, each with its own
  `plugins/<name>/.claude-plugin/plugin.json`, and the marketplace
  `metadata.version` is bumped to **0.5.0**. The release workflow now
  builds one claude.ai-compatible zip per skill folder and attaches
  all of them. The `running-bug-review-board` plugin is unchanged.

### Changed

- **README reworked into a multi-skill collection landing page.** It now
  opens with a "Skills in this collection" overview and gives
  `parallel-orchestrate` a first-class section (per-tool install for
  Cursor, Codex, and Claude Code) alongside the existing
  `running-bug-review-board` QA depth, which is preserved under its own
  section.
- **`parallel-orchestrate` (Cursor variant) hardened after a multi-model
  adversarial review.** Corrected the `browser-use` (stateful, can't be
  fanned out) and `explore` (read-only, no MCP/internet) capability
  notes, gated the cloud-orchestrate escalation on "if installed",
  separated competing-attempt worktrees from disjoint edits, and added
  `Coverage` + `Confidence & risk` handoff fields, a batch-into-waves
  concurrency note, and return-only-the-handoff / no-recursion worker
  guardrails.

[0.5.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.5.0

## [0.4.0] — 2026-05-29

### Added

- **Computer Use playbook** (`references/computer-use-playbook.md`). The skill
  now discovers whether **Codex Computer Use** is available (macOS only) and,
  when it is, drives web apps and **native macOS apps** by seeing, clicking,
  and typing — the highest-fidelity way to test the real, signed-in app, and
  the only way this skill can reach a desktop Mac app. It degrades gracefully:
  most VMs (Cursor cloud, CI) lack it, so a pass still succeeds with a browser
  driver alone, and iOS app QA still defers to the iOS simulator playbook.
- **Chrome DevTools for agents (`chrome-devtools-mcp`)** added as a first-class
  rung in the browser playbook, with a new "drive like a human (don't trip the
  tests)" section: attach to your real, already-signed-in Chrome via
  `--autoConnect` / `--browser-url` so auth flows don't get bot-flagged, and
  lean on its built-in auto-wait to remove stale-ref / timing failures.
- **Native macOS app** surface detection wired through `SKILL.md` (surfaces
  table, mode picker, project-type discovery, and the browser-tools ladder).

### Changed

- **Web QA now covers mobile, tablet, and desktop.** The skill no longer
  defaults to a single mobile viewport. It tests all three device modes
  (reference sizes 375×812 / 768×1024 / 1280×800) and leads with the
  product spec's primary target; when the spec is unclear it asks the user,
  and when the user isn't available it infers the primary from the repo and
  notes the assumption — persisted in `qa-config.json#platforms.web`
  (`deviceModes` / `primary` / `primarySource`). Updated across `SKILL.md`,
  the browser playbook,
  discovery, session hygiene, the test-plan / run-report / shard / sequential
  templates, and the bug template.
- **README rewritten for humans first.** It now leads with what you get,
  screenshots of the HTML report (the prioritized bug list and a single bug
  report), and copy-paste example prompts, then links into the deeper sections
  for people and agents auditing the skill. The stacked "What's new in vX"
  blocks at the top are replaced by a short Changelog pointer near the bottom.
- **Corrected the README repo-structure tree** to match the repository — it had
  drifted several references and scripts out of date.
- Trimmed duplicate rows from the `SKILL.md` anti-patterns table so each
  remaining entry explains a distinct *why* instead of repeating the
  Always / Never lists.

### Fixed

- **Surface detection no longer misclassifies macOS-only Xcode projects as
  iOS.** Bare `*.xcodeproj` / `*.xcworkspace` are shared between iOS and
  macOS, so the iOS surface now requires a genuinely iOS-specific marker
  (`.iOS(...)`, `platform :ios`, `UIDeviceFamily`, `ios/`), the iOS row is
  matched before macOS, and the iOS-simulator playbook's signal table carries
  the same caveat. (Cursor Bugbot.)
- **Mixed monorepos no longer skip native iOS QA.** The project-type
  detection in `SKILL.md` previously read as ordered "first match wins,"
  so a web + iOS monorepo matched **Web app** and stopped before the iOS
  check — contradicting the **Mixed (monorepo)** surface that says both
  playbooks should run. Detection now **collects every distinct surface
  present** (a web match never short-circuits a co-located iOS or macOS
  pass), with first-match precedence kept only as a disambiguation rule
  for overlapping signals inside a *single* app (Electron/Tauri vs web;
  macOS vs iOS on a shared `*.xcodeproj`). Reconciled across the
  discovery step, the surfaces table/intro, and the discovery-output
  checklist in `references/discovering-the-app.md`. (Cursor Bugbot.)

### Notes

- The HTML report design is unchanged in this release, so its
  `<!-- skill:running-bug-review-board v0.3 -->` version marker stays put.
- Credits: the Chrome DevTools team for `chrome-devtools-mcp`, and OpenAI for
  Codex Computer Use.

[0.4.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.4.0

## [0.3.1] — 2026-05-28

### Fixed

- **Codex skill loading compatibility.** Shortened the
  `running-bug-review-board` `SKILL.md` frontmatter description from
  more than 1,600 characters to concise routing metadata under Codex's
  1,024-character hard limit. The detailed trigger language, tracker
  notes, iOS companion-skill context, and Interactive BRB guidance stay
  in the skill body and references where Codex can load them through
  progressive disclosure.

### Changed

- Shortened plugin and marketplace descriptions so Codex app, desktop,
  IDE, and CLI surfaces receive compact metadata instead of changelog-
  length summaries.

### Added

- Added `scripts/validate-skill-metadata.py`, a dependency-free release
  validator for `SKILL.md` frontmatter and plugin marketplace
  descriptions. The release workflow now runs it before building the
  skill zip so future releases cannot ship Codex-invalid descriptions.

## [0.3.0] — 2026-05-27

### Changed

- **HTML report redesigned around editorial typography (Zite + Dieter
  Rams).** The v0.2 report used coloured chips, pills, shadows, and a
  three-column Kanban board to communicate priority and status. v0.3
  removes all of it. Typography does the work that colour did:
  priority is the word `P0` set in small caps in the eyebrow above the
  title, status is the word `Open`, the verdict is a single
  display-type word (`YES` or `NO`). One ink colour for body
  (`#1A1A1A` on `#FAFAF7` paper in light mode; `#ECEAE3` on `#131311`
  in dark mode), one quiet terracotta accent (`#A5391A`) reserved for
  links, CTAs, and the period after `NO`. Hairline rules instead of
  card borders. No shadows. A 640px reading column at every viewport
  width; bug detail pages add a quiet right rail on desktop
  (≥1024px). Mobile gets a sticky `thumb-zone` shelf at the bottom so
  the primary action stays in reach without scrolling back up. Print
  stylesheet drops accent to black and keeps each bug on its own page.
- **Information hierarchy on bug detail pages reordered for the
  engineer-reviewer's sweep:** Eyebrow → Title → Deck → Impact →
  Actual / Expected → Risk to fix → Steps to reproduce → Evidence →
  Notes → Triage log. The eye now lands on what the bug is, then why
  we care, then what's broken — in that order.
- HTML report version marker bumped to
  `<!-- skill:running-bug-review-board v0.3 -->` in `assets.css`,
  `index.html`, `bug.html`, `run.html`.

### Added

- **Two new bug template sections:** `## Impact` and `## Risk to fix`.
  Both are additive — old v0.2 bugs without them render gracefully
  (the corresponding pull-quote and aside simply disappear). Impact
  is filled by the QA agent when filing ("what does a user experience
  if this ships unfixed?") and rendered as a serif pull-quote. Risk
  to fix is usually empty when filed and populated by the engineer
  during the BRB ("local fix, low blast radius" / "cross-cutting,
  spike first"); rendered as a soft tinted aside.
- **Three design samples saved to the skill** for future contributors
  and reviewers:
  `references/templates/html-report/samples/dashboard-desktop.png`,
  `dashboard-mobile.png`, and `bug-detail-desktop.png`. Captured at
  1280×1800, 390×2200, and 1280×2400 respectively against the
  canonical skeletons.
- `references/extending-the-skill.md` version-bump checklist now
  includes the **git tag push** step (regression from v0.2 where the
  manifests said 0.2.0 but the GitHub Releases page kept showing
  0.1.0 until the tag was pushed manually).

### Compatibility

- All v0.3 changes are additive at the data layer (no front-matter
  rows renamed; new sections are optional). Existing v0.2 bug
  markdown renders without modification.
- HTML reports generated by v0.2 use a different version marker; v0.3
  agents that find a v0.2 marker write to `index.next.html` and let
  the user diff before overwriting. The canonical stylesheet should
  be regenerated to pick up the new design tokens.
- `qa-config.json` schema is unchanged. `version: 1` still applies.

### Why

The colour-coded chips and pills of v0.2 drew the eye away from the
prose of each bug. A reviewer scanning ten open issues got pulled into
a colour pattern instead of reading the titles. The traffic-light
palette felt cheap — like a status board, not a magazine of
considered bug reports. v0.3 takes inspiration from
[Zite](https://en.wikipedia.org/wiki/Zite) (magazine layouts,
editorial typography, restrained colour) and Dieter Rams (less, but
better — unobtrusive chrome, honest hierarchy, no decoration) to put
the prose first and let the engineer make triage decisions on the
text, not the swatch.

[0.3.1]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.3.1
[0.3.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.3.0

## [0.2.0] — 2026-05-27

### Added

- **Apple-language HTML report.** The QA agent now writes
  `docs/qa/report/index.html` + per-bug and per-run detail pages by
  applying `references/html-report-style-guide.md`. SF Pro typography
  stack, Apple system color palette with default light and dark
  variants, Dynamic Type-style scale (Large Title 34 → Caption 11),
  8-point spacing grid, evidence galleries with embedded screenshots,
  vanilla-JS filter bar, print stylesheet. Canonical CSS + page
  skeletons in `references/templates/html-report/`. Markdown remains
  the source of truth; HTML is regenerated.
- **Issue-tracker integration via `docs/qa/qa-config.json`.** First-
  class adapters for Linear (Linear MCP at `https://mcp.linear.app/mcp`)
  and GitHub Issues (`gh`); templated adapters for Jira (REST or
  `jira-cli`) and Notion (Notion MCP). The skill leads with a
  **discovery ceremony** — enumerates signals (`LINEAR_API_KEY`,
  `gh auth status`, Atlassian URL, registered MCP servers, etc.),
  surfaces every finding to the user, and never writes the config
  silently. References: `references/issue-trackers.md`. Helper:
  `scripts/bugs-needing-sync.sh`.
- **Bi-directional sync.** Push (markdown → tracker) at file time or
  BRB time; **pull** (tracker → markdown) at BRB start (`pull.onBRBStart`,
  default ON) and during re-tests (`pull.onReTest`, default ON).
  Reconciliation rules favour the tracker for `fixed` / `verified` and
  the markdown for `open` / `in-progress`; divergences surface as
  user-decision diffs. Bug front-matter gains `Tracker / Linear`,
  `Tracker / GitHub`, `Tracker / Jira`, `Tracker / Notion`, and
  `Tracker / lastSyncedAt` rows. Helper:
  `scripts/bugs-needing-pull.sh`. Tracker-only bugs surfaced to the
  user — never auto-imported (`pull.createLocalForUntracked: "ask"`
  by default).
- **Interactive Bug Review Board workflow.** A separate
  facilitator-agent prompt (`templates/brb-interactive-prompt.md`)
  opens the meeting with the pre-BRB pull, runs pattern-based triage
  heuristics, presents bugs one by one, applies user decisions, syncs
  the tracker, regenerates the HTML, and writes minutes
  (`templates/brb-minutes.md`). Kept intentionally separate from the
  auto pass so triage bias doesn't contaminate discovery. References:
  `references/brb-interactive.md`.
- **Pattern-based triage suggestions.** A catalog of named heuristics
  (`same-suspect-file`, `steps-prefix-overlap`,
  `same-persona-surface-outcome`, `same-console-error`,
  `same-test-id`, `phase-cascade`, `cosmetic-cluster`,
  `regression-marker`, `same-owner`) the agent runs at BRB start (and
  optionally at auto-pass file time). Every suggestion cites the
  heuristic name and the matching text — no embeddings, no LLM API,
  no auto-merge. References: `references/triage-heuristics.md`.
- **New `duplicate` bug status** (BRB-only transition, requires user
  confirmation, records `Duplicate of: BUG-XXX`). Bug template gains
  `Duplicate of` and `Linked bugs (related)` front-matter rows.
- **iOS / iPadOS app testing playbook — curated cite hub.** When the
  repo under QA is an iOS app project (detected via `*.xcodeproj`,
  `Package.swift` with `.iOS`, `Podfile` with `platform :ios`, `ios/`
  directory, etc.), the skill orchestrates and **defers actual
  simulator driving** to the iOS community's purpose-built skills:
  [AXe](https://github.com/cameroncooke/AXe) and
  [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) by
  Cameron Cooke, [App Store Connect CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI)
  + [companion skills](https://github.com/rudrankriyam/app-store-connect-cli-skills)
  by Rudrank Riyam, [ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill)
  by Conor Luddy, [ios-build-verify](https://github.com/vermont42/ios-build-verify)
  by Josh Adams, [baguette](https://github.com/tddworks/baguette) by
  tddworks, [ios-idb-skill](https://github.com/haowu77/ios-idb-skill)
  by Hao Wu, [serve-sim-skill](https://github.com/malopezr7/serve-sim-skill)
  by malopezr7, [swiftui-autotest-skill](https://github.com/yusufkaran/swiftui-autotest-skill)
  by Yusuf Karan, and [xcode-build-skill](https://github.com/pzep1/xcode-build-skill)
  by pzep1. References: `references/ios-simulator-playbook.md`. The
  iOS playbook is for iOS app projects only, **not** for testing web
  apps on Mobile Safari.
- **Extension story.** New `references/extending-the-skill.md`
  documents how to add a tracker, heuristic, surface, or mode without
  rewriting the skill. `qa-config.json` carries `version: 1` for
  forward-compat; unknown fields are ignored. HTML report carries a
  versioned `<!-- skill:running-bug-review-board v0.2 -->` comment
  marker.

### Changed

- `SKILL.md` rewritten (449 lines, still under the 500-line cap). New
  sections: Two workflows — Auto QA and Interactive BRB; Surfaces —
  which playbook activates; Issue tracker integration; HTML report;
  Pattern-based triage suggestions; Extending this skill. Mode picker,
  Always / Never lists, References, Scripts, and Anti-patterns tables
  updated.
- Scaffolder (`scripts/scaffold-qa.sh`) now writes a stub
  `docs/qa/qa-config.json` (with `issueTracker.type = "none"`) and a
  `docs/qa/report/.gitkeep` so the discovery ceremony and the HTML
  generator have somewhere to write. Printed next-steps hint extended
  to mention the discovery ceremony, the project-type detection, the
  HTML render step, and the separate-session rule for BRB.
- `references/workflow.md` extended: detect project type and issue
  tracker in step 2, run triage heuristics in step 6, generate HTML +
  sync tracker in step 9, schedule interactive BRB as step 11.
- `references/discovering-the-app.md` extended: project-type
  detection table, issue-tracker discovery question template, monorepo
  / mixed-project ask, output checklist now requires project type +
  tracker + heuristic cluster summary.
- `references/bug-filing.md` extended: step 0.5 (check heuristics
  before filing), step 7 (sync to tracker if configured), step 8
  (refresh HTML). Status transitions add `duplicate`. BRB-cadence
  section replaced with a pointer to `brb-interactive.md`.
- `references/browser-playbook.md` clarified: web apps only. The iOS
  Simulator playbook is **not** the right tool for web-app QA.
- `references/sequential-wrapup.md` and
  `references/parallel-coordinator.md` extended to regenerate HTML at
  end of merge and run the sync helpers.
- Bug template and run-report / coordinator-merge templates updated
  with tracker rows, HTML report path, tracker-sync mini-table, and
  generated-artifacts section.

### Compatibility

- All additions are opt-in. v0.1 installs that don't run the discovery
  ceremony, the heuristics, the pull, or the HTML render continue to
  behave exactly as before.
- `qa-config.json` schema is forward-compatible: unknown top-level
  fields are ignored.
- Bug front-matter additions are additive — existing rows keep their
  labels.

### Credit

This release stands on the iOS community's work. Major thanks to:

- **[Cameron Cooke](https://github.com/cameroncooke)** for
  [AXe](https://github.com/cameroncooke/AXe) and
  [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) and for
  popularizing the accessibility-tree-as-observation-primitive
  pattern.
- **[Rudrank Riyam](https://github.com/rudrankriyam)** for the
  [App Store Connect CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI)
  and [companion skills](https://github.com/rudrankriyam/app-store-connect-cli-skills),
  which thread QA evidence through to TestFlight and review tooling.
- **[Conor Luddy](https://github.com/conorluddy)** for
  [ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill),
  the inspiration for layered helper-script skills.
- **[Josh Adams](https://github.com/vermont42)** for
  [ios-build-verify](https://github.com/vermont42/ios-build-verify),
  for naming intents over raw CLIs.
- **[tddworks](https://github.com/tddworks)** for
  [baguette](https://github.com/tddworks/baguette), for the iOS 26
  input path.
- **[Hao Wu](https://github.com/haowu77)**,
  **[malopezr7](https://github.com/malopezr7)**,
  **[Yusuf Karan](https://github.com/yusufkaran)**,
  **[pzep1](https://github.com/pzep1)**, and many others building in
  the open under [agentskills.io](https://agentskills.io).

[0.2.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.2.0

## Pre-0.2.0 history

### Changed

- README install section rewritten with vendor-native install commands per agent: `droid plugin marketplace add` + `droid plugin install` for Factory Droid, `codex plugin marketplace add` + `codex plugin add` (or `/plugins` TUI on Codex 0.125 and earlier) for Codex CLI, and the existing two-line `/plugin marketplace add` flow for Claude Code. Cursor and other agents without a CLI installer are routed to the cross-vendor `npx skills add` from [vercel-labs/skills](https://github.com/vercel-labs/skills). The manual symlink loop is now a fallback at the end of the section instead of the headline path.

## [0.1.0] — 2026-05-26

### Added

- First Skill file: `running-bug-review-board` — a real-user QA workflow with a Bug Review Board (BRB). Drives the live app like a customer, files structured P0/P1/P2 bug reports, and produces a YES/NO sign-off per phase.
- `.claude-plugin/marketplace.json` so users can install with two commands: `/plugin marketplace add RayFernando1337/rayfernando-skills` followed by `/plugin install running-bug-review-board@rayfernando-skills`.
- Repo restructured to the standard marketplace layout with the plugin under `plugins/running-bug-review-board/`.
- GitHub Actions workflow that builds a claude.ai-compatible zip artifact whenever a `v*` tag is pushed, attached to the GitHub Release.

[0.1.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.1.0
