# Changelog

All notable changes to this collection are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.0] — 2026-07-07

### Fixed

- **`bootstrap-ios`: installer script crashed on macOS's default bash 3.2
  before installing anything.** `scripts/bootstrap-ios-skills.sh` combined
  `set -u` with an expansion of the possibly-empty `agent_args` array
  (`"${agent_args[@]}"`), which bash 3.2 treats as an unbound variable —
  every run without `--agent` (and on bash 3.2, every run at all) died with
  `agent_args[@]: unbound variable` at the first install command. Both
  expansions now use the bash-3.2-safe form
  `${agent_args[@]+"${agent_args[@]}"}`. Found when a machine bootstrapped by
  hand around the crash was left with shallow skill installs (see below).

### Added

- **`bootstrap-ios`: post-install verification of every installed skill.**
  Installers have been observed writing only `SKILL.md` and skipping the
  `references/` files the skill routes to at runtime — agents then follow a
  `references/` pointer into nothing and silently degrade. After a real
  (non-dry-run) run, the helper now checks each expected skill across the
  global skill roots (`~/.agents/skills`, `~/.claude/skills`,
  `~/.cursor/skills`, `~/.cursor/skills-cursor`, `~/.codex/skills`,
  `~/.factory/skills`): `SKILL.md` must exist and every `references/`,
  `scripts/`, and `assets/` file it cites must be on disk. Any shallow
  install fails the run with `MISSING:` paths and the reinstall fix
  (`npx skills add <url> --global --yes --full-depth`). Opt out with
  `--skip-verify`. Documented in `SKILL.md`,
  `references/install-and-bootstrap.md`, and the README.
- **Regression tests for the installer** (`tests/test_bootstrap_ios_skills.py`):
  dry-run with/without `--agent` on the system bash (bash 3.2 on macOS, the
  regression that motivated the fix), plus complete/shallow/skip-verify
  verification paths against a stubbed `npx` and fake `HOME`. The release
  workflow now runs the whole `tests/` suite (`python3 -m unittest discover`)
  before building zips, so installer and validator regressions block a
  release.

### Changed

- `bootstrap-ios` plugin bumps to **0.2.0**; marketplace `metadata.version`
  to **0.11.0**.
- Release notes template now includes the `bootstrap-ios` install line
  alongside the other plugins.

[0.11.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.11.0

## [0.10.1] — 2026-07-05

### Fixed

- **`waves`: wave synthesis no longer races the verifier pass** (Bugbot
  finding, medium severity). Step 3 told the orchestrator to write
  `.waves/<run>/synthesis-wave-N.md` "once a wave's handoffs are verified"
  before the section had defined *verified*, and Step 3.5 gated verifier
  verdicts on "the final deliverable" only — so, followed top-to-bottom, a
  `single verifier`-tier claim could land in the wave synthesis file (and in
  dependent slices' prompts via the manifest's `depends_on` dispatch) while
  its verifier was still running. Step 3 now runs the evidence checks before
  the compress-at-the-barrier write and defines **verified** as cheap checks
  passed *and* tier-mandated verdicts returned; Step 3.5 now gates the wave
  synthesis itself, with still-pending claims carried only as explicit
  `pending-verification` lines and never fed to dependent slices. The
  checklist item was tightened to match. (The `waves-codex` variant already
  ordered accept-then-compress correctly and is unchanged.)

### Changed

- `waves` plugin bumps to **0.5.1**; marketplace `metadata.version` to
  **0.10.1**.

[0.10.1]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.10.1

## [0.10.0] — 2026-07-04

### Added

- **`waves` + `waves-codex`: run-shape triage, dependency-aware dispatch, and
  a missing-role fallback** — techniques adapted from reviewing Phillip
  Chaffee's public `deep-research` Cursor skill
  (github.com/PhillipChaffee/.cursor), each re-verified against current
  Cursor/Codex docs and bug trackers before adoption, and kept
  model-agnostic (no pinned researcher rosters or model slugs — routing
  stays a per-slice cost/stakes decision). Both variants now: **state the
  run shape in one line before spawning** (weigh breadth / depth / ambiguity
  / stakes; on the fence pick the smaller shape; if no wave is needed say so
  — never present inline work as wave coverage); record **`depends_on`** as
  a per-slice triage axis and manifest column, with dependency-aware
  dispatch (a wave is every not-yet-run slice whose dependencies are met,
  where met means the dependency's handoff has been *verified*, not merely
  returned; dependents launch with distilled findings folded into their
  self-contained prompts; unrelated slices stay parallel); and treat **a
  missing worker role as not permission
  to skip it** — on Cursor, custom `.cursor/agents/` subagents register as
  `subagent_type` values only after a restart, so an unregistered role runs
  as `generalPurpose` with the role's instructions inlined (and the intended
  `model` passed on the call); on Codex, an unknown `agent_type` fails the
  spawn and `.codex/agents/` loads in trusted projects only, so an
  unavailable role runs as `default`/`worker`/`explorer` with the
  instructions inlined. The worker failure ladder gains a cheaper first
  rung: **steer or resume the same worker** (Cursor resumes by agent ID with
  context preserved; Codex uses `send_input` / `resume_agent`) before
  re-spawning fresh.

### Changed

- **`waves` + `waves-codex`: subagent mechanics re-verified 2026-07-03.**
  `waves`: the custom-agent registration-after-restart behavior, resume by
  agent ID, and the model-fallback conditions (Max Mode / plan / admin
  restrictions, plus confirmed can-be-ignored bug reports) checked against
  Cursor docs and forum reports; model routing now recommends pinning a
  custom agent's `model` in its frontmatter **and** passing the matching
  `model` on the `Task` call, and treating off-looking worker output as a
  hint the intended model may not have run. `waves-codex`: the documented
  collaboration tool set updated to five tools (adds `resume_agent`);
  unknown-`agent_type` spawn failure and trusted-project loading of
  `.codex/agents/` recorded; `references/adaptation-notes.md` gains the
  2026-07-03 re-check block and the new Cursor-to-Codex swap rows
  (missing-role fallback, steer/resume, run-shape triage + `depends_on`
  portability).
- **Release workflow actions bumped off the deprecated Node 20 runtime.**
  `actions/checkout` v4 → v7 and `softprops/action-gh-release` v2 → v3 (both
  now target Node 24, which GitHub-hosted runners already provide). Checkout
  v7's breaking change only affects `pull_request_target` / `workflow_run`
  triggers; this workflow runs on tag push, so it is unaffected.
- Both `waves` plugins bump to **0.5.0**; marketplace `metadata.version` to
  **0.10.0**.

[0.10.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.10.0

## [0.9.0] — 2026-07-01

### Added

- **Skill evals for both `waves` variants, modeled on Anthropic's
  skill-creator methodology.** Each skill now ships `evals/evals.json`
  (skill-creator format: `id`/`prompt`/`expected_output`/`files`/
  `expectations`), fixtures with known ground truth (a 40-row support-ticket
  CSV with seeded theme counts, plus three pre-written worker handoffs — one
  containing a deliberately wrong count and a phantom citation for the
  verification-catch scenario), and an `evals/README.md` documenting the
  with-skill vs baseline A/B protocol in fresh sessions, PASS/FAIL grading
  with cited evidence and no partial credit, blind grading, programmatic
  recounts, benchmark-style aggregation, the iterate loop, and a retirement
  check (trim guidance the base model has absorbed). Six behavior scenarios
  per variant cover coverage-gated data fan-out, entropy-first handling of a
  vague build, multi-stream research with confidence labels, catching a bad
  handoff before synthesis, refusing unsafe parallel writes, and bounded-wave
  stop discipline.
- **`scripts/validate-skill-evals.py` + tests, wired into release CI.**
  Stdlib-only validator: parses each `evals/evals.json`, checks
  `skill_name` matches the skill directory, requires unique integer ids,
  non-empty prompts/expectations, and verifies referenced fixture files exist
  inside the skill directory.
- **Run mechanics in both `waves` variants (from a comprehensive review).**
  A **wave manifest** (one row per slice: scope / worker type / model or
  effort / verification tier, written before spawning) that doubles as the
  **completion gate** — N rows spawned means N handoffs checked off before
  synthesis, so a worker that never returns can no longer silently drop a
  slice; a **worker failure ladder** (re-spawn once narrower → do the slice
  in the main session → carry it explicitly as `not-covered`); a
  **`.waves/<run>/` scratch-dir convention** (staging, handoffs,
  `synthesis-wave-N.md`) with a compress-at-the-barrier step so next-wave
  prompts cite paths instead of re-pasting handoffs; **handoff digest caps**
  (~15 findings, one-line evidence, large artifacts to disk); an explicit
  **Step 3.5 verifier pass** in the Cursor variant (parity with Codex); and
  three **SWE-workflow recipes** in both `examples.md` — implement a reviewed
  plan (spec wave → disjoint edit wave → verify wave), row-shaped
  codemod/migration with an oracle-gated coverage list, and CI-failure
  triage (one worker per failing job → dedupe root causes → one fix wave).
- **`running-bug-review-board` runs its parallel pass as a wave.** New
  "Run the pass as a wave" section in `references/parallel-coordinator.md`
  mapping the shard map to a wave manifest, write-path-first to Wave 1
  (serial) → Wave 2 (parallel), and run reports to file-based handoffs —
  while keeping the QA-specific constraints (one browser tab per shard,
  auth rate-limit stagger, no browser fan-out inside a shard, PASS requires
  real-app evidence). Adds a **Test-ID coverage gate** (every scenario in
  exactly one shard, counts sum to the plan) before launching, pre-assigned
  BUG-NNN ranges per shard, tiered verification for the coordinator
  (auto-accept low-stakes PASS rows; personally re-run write-path and
  highest-risk IDs; verify every FAIL/BLOCKED and backend-write claim),
  cheap-model routing for low-risk shards, a narrowed single-shard retry
  before the sequential fallback, and token discipline: evidence to disk
  only, coordinators read run-report files instead of tailing transcripts,
  and shards return a fixed six-line structured handoff
  (`Status / Coverage / Results / Bugs filed / Report / Flags`) in chat.
  Mode-picker rows in `SKILL.md` and `workflow.md` point at it when
  `waves`/`waves-codex` is installed. The plugin bumps to **0.5.0**.

### Changed

- **Deeper paper diligence in both `waves` variants.** The grounding notes now
  extract the actionable mechanism from each cited paper instead of
  name-dropping it, with corrected attribution: probe selection that halves
  the surviving interpretations (Uncertainty of Thoughts, arXiv 2402.03271);
  ask-vs-act value thresholds and the specification-vs-model uncertainty
  split (SAGE-Agent, arXiv 2511.08798); specification judgment before acting
  with its overconfidence caveats (arXiv 2606.19559); least-to-most's
  depth-dependent gains and domain-specific decomposition bottleneck (arXiv
  2205.10625); and Plan-and-Solve's "plans fix missing steps, not a misread
  goal" (arXiv 2305.04091) — plus an explicit note that the parallel fan-out
  and inter-wave verification are this skill's multi-agent adaptation, not
  claims from those single-model papers.
- **Verification playbooks upgraded from the sources.** CoVe factored checks
  now include the factor-revise cross-check step and open-not-yes/no question
  phrasing; self-consistency guidance moves to 5–10 samples with real
  sampling variation and agreement-as-confidence; new rules from the
  self-correction literature (never let a retry loop peek at the expected
  answer; at matched budget, k samples + majority vote beats critique/debate
  loops); judge hygiene from the LLM-judge literature (hide authorship
  labels, swap pairwise orderings, keep reference-matching judges from
  over-reasoning, disjoint-family panels per PoLL); SAFE's self-contained
  atomic-fact rewrite step; and sourced citation-hallucination rates (3–13%
  fabricated URLs, arXiv 2604.03173) with a URL-health mitigation. The
  unsupported "≥3 independent agreement ≈ 95% reliable" claim is replaced
  with an honest Condorcet framing that names its independence assumptions.
  Both plugins bump to **0.4.0**; marketplace `metadata.version` to
  **0.9.0**.

[0.9.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.9.0

## [0.8.0] — 2026-07-01

### Added

- **Entropy-first decomposition in both `waves` variants.** A new
  "Entropy-first decomposition" section (plus a `Decomposition is entropy
  reduction` core principle) reframes decomposition as *uncertainty reduction*:
  before slicing a vague, high-entropy goal ("build a Flappy Bird game"), shrink
  the space of plausible plans along an **information-gain ladder** — dig
  locally first, then pull from attached resources (a small **scouting wave** of
  research workers), and ask the user *last*, only when a question's expected
  information gain beats its cost. It separates **specification** uncertainty
  (assume, or ask when it pays) from **environment/knowledge** uncertainty
  (gather via tools), then **cascades** a decomposition wave into an execution
  wave and orders the plan **least-to-most**. Grounded in the information-gain /
  clarification and task-decomposition literature (Uncertainty of Thoughts;
  EVPI-based clarification; Least-to-Most; Plan-and-Solve). `references/examples.md`
  gains a worked "build a Flappy Bird game" recipe, a "decomposition / scouting
  wave" shape, and a grounding/sources note.

### Changed

- **`waves` (Cursor) now routes the model per slice.** New "Picking the model
  per slice (cost / speed routing)" guidance: send scouting / decomposition /
  read-heavy exploration to the cheap, fast model — Cursor's built-in `explore`
  and search subagents already default to the Composer fast family
  (`composer-2.5-fast`), and you can pin `model: "composer-2.5"` on a `Task`
  worker or the `model` field (`inherit` | `fast` | a slug) on a custom
  `.cursor/agents/` subagent — and reserve frontier / multi-model-panel models
  for high-stakes verification and synthesis. Documents availability caveats
  (Max Mode / plan / admin fallbacks, drifting slugs, unreliable `inherit`) and
  keeps model choice subordinate to the user's stated preference. The `waves`
  plugin bumps to **0.3.0**.
- **`waves-codex` ties reasoning effort to the entropy phase and adds model
  precision.** Routes the fast scouting/decomposition reads to `gpt-5.5` at
  `low` effort (with `gpt-5.4-mini` as an even lighter option), clarifies that
  the live per-spawn field is `reasoning_effort` while the config / custom-agent
  TOML key is `model_reasoning_effort`, and notes that Codex fast/priority
  processing (`/fast`, `service_tier`) is a user-enabled speed tier, not a
  forced default. Updated `references/recommended-config.md` and
  `references/adaptation-notes.md` accordingly. The `waves-codex` plugin bumps
  to **0.3.0**.
- **Marketplace catalog** bumps `metadata.version` to **0.8.0**; both `waves`
  plugins move to 0.3.0 with new discovery keywords/tags (`entropy-reduction`,
  `decomposition`, `model-routing`).

[0.8.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.8.0

## [0.7.1] — 2026-06-21

### Fixed

- **`waves-codex` now matches the Cursor `waves` skill's bias toward follow-ups
  and additional waves.** The Codex port had conflated the platform recursion
  cap (`agents.max_depth = 1`) with the willingness to spawn sequential
  follow-up waves, so it stopped earlier and spawned fewer waves than the Cursor
  variant. Reverted the gated phrasing ("only important" / "if needed" /
  "materially improve") back to "each bullet is a candidate second-wave task";
  restored the named **Continuous motion** principle and the **Step 4 — Second
  Waves (continuous motion)** framing in `SKILL.md`; made the `examples.md` hero
  run actually spawn Wave 2 + Wave 3 (and added a "don't stop after one wave"
  anti-pattern); restored the panel/multi-pass cross-check and motion-first
  escalation in `references/verification.md`; and added a "Carrying a Handoff
  Into the Next Wave" section to `references/handoff-format.md`.
- **Decoupled the recursion cap from sequential waves.** `agents.max_depth = 1`
  is now documented across `SKILL.md`, `examples.md`, `recommended-config.md`,
  and `adaptation-notes.md` as capping *recursion only* (a worker spawning its
  own sub-workers); manager-driven second/third waves at depth 1 are encouraged
  and unaffected. Bounded-wave caps (width 3–8, ≤2–3 waves) and the verified
  Codex facts (`max_threads`, experimental `spawn_agents_on_csv`) are unchanged.
- **`recommended-config.md`** now notes that `[features] multi_agent` is Stable
  and defaults to `true` in current Codex, so setting it is optional. The
  `waves-codex` plugin bumps to **0.2.1**.

[0.7.1]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.7.1

## [0.7.0] — 2026-06-20

### Changed

- **Renamed `parallel-orchestrate` → `waves` and `parallel-orchestrate-codex`
  → `waves-codex`.** The method is **WAVE = Workers · Aggregate · Verify ·
  Extend**: bounded rounds of isolated parallel subagents, a verification gate,
  then a deliberate decision to extend into the next wave instead of looping
  open-endedly. The old names are kept as description keywords for
  discoverability; both plugins bump to 0.2.0.
- **Skills are now opt-in (`disable-model-invocation: true`).** Invoke with
  `/waves` (or `/waves-codex`) rather than auto-triggering, since a run spawns
  more agents than usual. The release-time metadata validator now allows the
  `disable-model-invocation` frontmatter key.

### Added

- **WAVE framing** in both variants, mapping Workers · Aggregate · Verify ·
  Extend onto the existing discover → fan-out → verify → second-wave loop.
- **Triage step (classify-and-act):** route each slice by worker type *and*
  verification tier.
- **Bounded-wave economics:** default width N=3–8, ≤2–3 wave cap, ~60/40
  generate/verify budget split, a distilled-handoff anti-poisoning rule, and
  explicit criteria for when loop-until-done is justified.
- **Verification upgrades:** an entailment-based ≥2-source rule, reference-guided
  + chain-of-thought verdicts, and an anti-gaming rule (the generator never sees
  the verifier's rubric). A different-model verifier is documented as an optional
  escalation, planned as a default in a later release.
- **Generate-and-filter & tournaments:** a cheap-filter-before-judge gate and a
  dedup → shortlist → pairwise selection ladder.
- **Wave shapes** (`references/examples.md`): exploratory, shaping,
  artifact-then-bigger-wave, and divergent-research.

[0.7.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.7.0

## [0.6.0] — 2026-06-17

### Added

- **`bootstrap-ios` — a router/loader meta-skill for Apple-platform app
  agents.** It detects iOS, iPadOS, macOS, SwiftPM, Xcode, SwiftUI,
  SwiftData/Core Data, Swift Testing, simulator, and build/debug work; then
  routes agents to focused community Swift skills, XcodeBuildMCP, Merowing
  public rules, AppCreator buildability ideas, and the existing
  `running-bug-review-board` iOS QA playbook without vendoring third-party
  content.
- **Optional `bootstrap-ios-skills.sh` helper.** The helper dry-runs by
  default in the docs, installs verified public GitHub skill folders through
  `npx skills add`, points at concrete skill-folder URLs where repos keep
  `SKILL.md` below root, and exposes optional XcodeBuildMCP agent-skill
  initialization.
- **Marketplace catalog updated.** `bootstrap-ios` is registered in
  `.claude-plugin/marketplace.json`, the collection metadata version is bumped
  to **0.6.0**, and the README now documents the new install path.

[0.6.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.6.0

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
