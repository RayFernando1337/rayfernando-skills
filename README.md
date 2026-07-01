# rayfernando-skills

A collection of installable **Skill files** for AI coding agents. It started with the one most teams are missing — real-user QA — and now also ships `waves`, an orchestrator-worker skill that fans one big task out to a team of agents (Cursor and Codex variants), plus `bootstrap-ios`, a single entry point for loading Ray's iOS/macOS agent skill stack.

[![Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

## Skills in this collection

| Skill | What it does | Primary install (Claude Code) |
|---|---|---|
| **[running-bug-review-board](#running-bug-review-board--real-user-qa)** · QA | Point an AI agent at your *live* app; it QAs like a real user, files P0/P1/P2 bug reports, and returns a **YES/NO** ship verdict plus a shareable HTML report. | `/plugin install running-bug-review-board@rayfernando-skills` |
| **[waves](#waves--fan-out-to-parallel-agents)** · Cursor + Codex | Fan one big research, analysis, or audit job out to parallel subagents, verify each structured handoff, and synthesize one deliverable. | `/plugin install waves@rayfernando-skills` |
| **[bootstrap-ios](#bootstrap-ios--load-the-ios-agent-stack)** · iOS/macOS | One entry point for Swift, SwiftUI, SwiftData/Core Data, Swift Testing, Xcode build/test/simulator, XcodeBuildMCP, and curated community iOS skills. | `/plugin install bootstrap-ios@rayfernando-skills` |

Each skill installs into Claude Code, Cursor, Codex, and ~50 other agents — full per-agent steps are in the sections below.

**Jump to:** [running-bug-review-board (QA)](#running-bug-review-board--real-user-qa) · [waves](#waves--fan-out-to-parallel-agents) · [bootstrap-ios](#bootstrap-ios--load-the-ios-agent-stack) · [Repo structure](#repo-structure) · [Contributing](#contributing)

---

## running-bug-review-board — real-user QA

> **`running-bug-review-board`** — point an AI agent at your *live* app and it QAs it like a real, slightly unforgiving customer: drives the UI, files structured P0/P1/P2 bug reports with reproduction steps, and gives you a **YES/NO** "is this ready to ship?" verdict — plus a self-contained HTML report you can hand to the team.

### What you get

Most AI workflows point at *code review* and miss where users actually hit bugs: the live app, on a real phone, with stale storage from yesterday and a flaky auth provider the unit tests never see. This Skill file encodes a battle-tested QA cadence so an agent can find those bugs for you.

- **A real-user QA pass, not a code review.** The agent drives the app from URLs and clicks — it is *forbidden* from marking anything "pass" by reading source. It hunts the failures users hit first: stale state across flows, mobile overflow, auth↔routing races, copy that lies, paths that 404 mid-onboarding.
- **Structured bug reports.** Every defect lands as `BUG-NNN-*.md` with severity (P0/P1/P2), impact, what-happened-vs-expected, reproduction steps, and evidence (screenshots, console, network).
- **A ship/defer decision.** Each pass ends with a **YES/NO** sign-off for the phase, listing open P0/P1 blockers and a paste-ready handoff prompt for the next agent.
- **An editorial HTML dashboard** stakeholders can open and share — the bug list and each bug report, regenerated every pass. ([see it below](#see-the-output))
- **Works with what you have.** Repo-agnostic and browser-tool-agnostic; web and iOS/iPadOS apps; optional two-way sync with Linear, GitHub Issues, Jira, or Notion. Runs fine in a cloud VM (e.g. Cursor cloud) with just a browser driver.

---

### See the output

The agent regenerates a self-contained HTML report at the end of every pass — designed to read like a magazine, not a Kanban board (editorial typography, ink-on-paper palette, no chips or pills). Here is what you instantly get:

| The QA dashboard | A single bug report |
|---|---|
| [![QA dashboard — verdict, then the prioritized bug list](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples/dashboard-desktop.png)](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples/dashboard-desktop.png) | [![Bug detail — impact, what's happening vs expected, steps, evidence](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples/bug-detail-desktop.png)](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples/bug-detail-desktop.png) |
| **Verdict first, then the prioritized bug list** and recent runs. | **One bug, told for an engineer:** impact → what's happening vs. what should → steps → evidence. |

It is responsive, too — on a phone the dashboard collapses to a single column with a sticky primary action. ([mobile sample](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples/dashboard-mobile.png) · [design notes](plugins/running-bug-review-board/skills/running-bug-review-board/references/html-report-style-guide.md))

---

### Example prompts

Once the skill is installed, just ask your agent in plain language:

```text
QA this app. Run a manual test plan on mobile and tell me what's broken.

Is phase 3 ready to ship? Give me a YES/NO with the open P0/P1 list.

Drive the signup flow like a brand-new user with stale storage, and file any bugs you find.

Re-test the fixed bugs BUG-007 and BUG-012 on the latest build and update the report.

Run the Interactive Bug Review Board with me on the open backlog.
```

The skill activates on phrases like *"QA this"*, *"is this ready to ship?"*, *"find the bugs"*, or *"run a test plan"* — you don't have to name it.

---

### Quick start

After [installing](#install), the agent walks itself through:

1. **Discover the app** — read the product spec / README / phase doc, open bugs, and public routes.
2. **Plan** — derive real-user scenarios from the spec and the gates.
3. **Prepare** — environment, test accounts, primary viewport.
4. **Execute** — drive the app like a customer, capturing evidence.
5. **File bugs** — `BUG-NNN-*.md` with priority + reproduction steps.
6. **Sign off** — YES/NO verdict, open P0/P1 list, and a paste-ready handoff.

**No QA folder yet?** The skill ships a scaffolder. After installing it lives in the Skill folder (e.g. `~/.claude/skills/running-bug-review-board/scripts/scaffold-qa.sh`). To run it without installing, clone and call it directly:

```bash
git clone https://github.com/RayFernando1337/rayfernando-skills.git
bash rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board/scripts/scaffold-qa.sh \
     /path/to/your/repo PHASE_NUMBER
```

This creates `docs/qa/` with the bug template, run-report skeletons, gates checklist, and a per-phase manual test plan. It is idempotent and won't overwrite existing files.

---

### Install

Pick the section for the agent you use. Each one installs the same Skill file; they differ only in how the agent discovers it.

#### Claude Code

```
/plugin marketplace add RayFernando1337/rayfernando-skills
/plugin install running-bug-review-board@rayfernando-skills
```

To pin a specific release tag, append it to the marketplace add (e.g. `@v0.4.0`). Docs: [code.claude.com/docs/en/plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces).

#### Factory Droid

```bash
droid plugin marketplace add https://github.com/RayFernando1337/rayfernando-skills
droid plugin install running-bug-review-board@rayfernando-skills
```

Factory Droid reads the same `.claude-plugin/marketplace.json` Claude Code uses. Docs: [docs.factory.ai/cli/configuration/plugins](https://docs.factory.ai/cli/configuration/plugins).

#### Codex (app, desktop, IDE, and CLI)

On Codex CLI, add the marketplace and install:

```bash
codex plugin marketplace add RayFernando1337/rayfernando-skills
codex plugin add running-bug-review-board@rayfernando-skills
```

On older Codex CLI without `plugin add`, open Codex, type `/plugins`, switch to the `rayfernando-skills` tab, and Install. In the app/desktop, use the Plugins / Skills installer and restart Codex so the skill cache reloads. Docs: [developers.openai.com/codex/plugins/build](https://developers.openai.com/codex/plugins/build).

<details>
<summary>Codex shows "invalid description: exceeds maximum length of 1024 characters"?</summary>

You are likely running a cached `running-bug-review-board` 0.3.0 install. Update or reinstall `running-bug-review-board@rayfernando-skills`, then restart Codex (app, desktop, IDE, or CLI) so it refreshes the plugin cache. (0.3.1+ ships Codex-valid metadata and the release pipeline now validates it.)
</details>

#### Cursor

Cursor's `/add-plugin` is reserved for the [cursor.com/marketplace](https://cursor.com/marketplace) listings, so for this repo use the cross-vendor installer — it writes the Skill folder into `~/.cursor/skills/`, which Cursor reads on startup:

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/running-bug-review-board/skills/running-bug-review-board -a cursor
```

Docs: [cursor.com/docs/skills](https://cursor.com/docs/skills).

#### Cross-vendor: `npx skills add`

The [`vercel-labs/skills`](https://github.com/vercel-labs/skills) installer detects every supported agent CLI on your machine and writes the Skill folder into each one's expected location (Claude Code, Cursor, Codex, Factory Droid, Windsurf, Zencoder, and ~50 others):

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/running-bug-review-board/skills/running-bug-review-board
```

Add `-a <agent>` to target one tool (`-a cursor`, `-a codex`, `-a droid`) or `--all` for every detected agent.

#### claude.ai (Settings → Features → Skills)

Download `running-bug-review-board.zip` from the [latest release](https://github.com/RayFernando1337/rayfernando-skills/releases/latest) and upload it. To build the zip from a local clone (claude.ai expects a zip whose root contains `SKILL.md`):

```bash
cd plugins/running-bug-review-board/skills
zip -r ../../../running-bug-review-board.zip running-bug-review-board
```

#### Manual install (any other agent)

Clone once and symlink the Skill folder into whichever directory your agent reads:

```bash
git clone https://github.com/RayFernando1337/rayfernando-skills.git ~/Code/rayfernando-skills
ln -sf ~/Code/rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board \
       ~/.<agent>/skills/running-bug-review-board
```

Replace `~/.<agent>/skills/` with your agent's path (`~/.cursor/skills/`, `~/.codex/skills/`, `~/.factory/skills/`, …). The same symlink can be committed inside a project (e.g. under `.claude/skills/` or `.cursor/skills/`) so anyone who clones it picks up the skill.

---

### How it works

- **Drives the live app.** The agent works through URLs and clicks; marking PASS from code inspection alone is forbidden.
- **Three hats, one pass.** Every pass wears PM (does it still deliver the promise?), QA (run the user scenarios with evidence), and Engineer (catch invalidated assumptions). Finding gaps is the point.
- **BRB cadence.** Bugs live in a versioned folder with status transitions (`open → in-progress → fixed → verified`). P0/P1/P2 tells the team what to ship and what to defer. Triage happens in a separate **Interactive Bug Review Board** session so triage bias never contaminates discovery.
- **Tool- and repo-agnostic.** Adopts whatever conventions exist and scaffolds folders when there are none. Parallel or sequential QA modes.

#### Browser & Computer Use

The agent drives the UI with the best driver your environment has, falling back gracefully — so a pass succeeds whether you're in Cursor, another IDE, or a headless cloud VM:

1. **cursor-ide-browser** MCP (default inside Cursor)
2. **[Chrome DevTools for agents](https://github.com/ChromeDevTools/chrome-devtools-mcp)** (`chrome-devtools-mcp`) — auto-waits for results (fewer flaky races) and adds network / console / Lighthouse / accessibility introspection; can attach to your *real signed-in Chrome* so auth flows don't get bot-flagged
3. **browser-use** MCP / **Playwright**
4. **Codex Computer Use** (macOS) — a human-fidelity pass that sees, clicks, and types in the *real* app, and the only way to reach a native macOS app
5. Manual driving with screenshot/console relay

Details and "drive like a human (don't trip the tests)" recipes live in the [browser playbook](plugins/running-bug-review-board/skills/running-bug-review-board/references/browser-playbook.md) and the [Computer Use playbook](plugins/running-bug-review-board/skills/running-bug-review-board/references/computer-use-playbook.md). For iOS/iPadOS apps the skill **orchestrates** and defers simulator driving to the [iOS community's purpose-built skills](plugins/running-bug-review-board/skills/running-bug-review-board/references/ios-simulator-playbook.md) — and never spins up an iOS simulator for a web-only app.

---

### What's inside

Each Skill file uses **progressive disclosure**: a lean `SKILL.md` entry point, with references loaded only when needed. Auditing the skill (or asking your own agent to security-check it) starts at:

- [`SKILL.md`](plugins/running-bug-review-board/skills/running-bug-review-board/SKILL.md) — the entry point: workflow, surfaces, modes, deliverables.
- [`references/`](plugins/running-bug-review-board/skills/running-bug-review-board/references/) — the detailed playbooks (discovery, test plan, browser, Computer Use, iOS, trackers, triage, HTML report, extending).
- [`scripts/`](plugins/running-bug-review-board/skills/running-bug-review-board/scripts/) — tiny shell helpers (scaffold a QA folder, list bugs needing tracker sync/pull). No magic; the agent does the work.

---

## waves — fan out to parallel agents

Turn one big task into a team of agents. **WAVE = Workers · Aggregate · Verify · Extend**: the lead agent discovers the shape of the work, splits it into independent slices, fans them out to parallel **W**orkers, **A**ggregates their structured handoffs, **V**erifies each one (the moat), and **E**xtends into another wave only when warranted — a bounded round, not an open-ended loop. It ships in two tool-tuned variants with different prompts:

- **[`waves`](plugins/waves/skills/waves/SKILL.md)** — for **Cursor**, built around the `Task` tool and Multitask Mode (local subagents on a shared filesystem).
- **[`waves-codex`](plugins/waves-codex/skills/waves-codex/SKILL.md)** — for **Codex**, built around Codex subagents, `spawn_agents_on_csv`, `config.toml` limits, and `codex exec` fleets.

Two upgrades in 0.8.0: **entropy-first decomposition** — before slicing a vague, high-entropy goal ("build a Flappy Bird game") it reduces uncertainty along an information-gain ladder (dig locally → pull from attached resources → ask the user only if it pays), then cascades a decomposition wave into an execution wave, ordered least-to-most; and **per-slice model routing** — send cheap read/scouting waves to a fast model (Composer 2.5 on Cursor, `gpt-5.5` at `low` effort on Codex) and reserve frontier models for high-stakes verification and synthesis.

New in 0.9.0: **deeper paper grounding** (each cited arXiv paper now contributes a verified, actionable mechanism — probe selection that halves the interpretation space, ask-vs-act value thresholds, factored verification with open check questions, judge blinding and disjoint-family panels, sourced citation-hallucination rates) and **skill evals** — both variants ship `evals/evals.json` + fixtures following Anthropic's skill-creator methodology (with-skill vs baseline A/B in fresh sessions, PASS/FAIL expectations graded against the transcript), so the skills can be measured and improved instead of just edited. See each skill's `evals/README.md`.

Reach for it when a single linear pass would be slow and the work splits into independent slices — big research, analysis, audits, or codebase/data exploration. Because a run spawns more agents than usual, it's **opt-in: invoke it explicitly with `/waves` (or `/waves-codex`)** rather than relying on auto-trigger (`disable-model-invocation: true`). Good prompts to pair with it: "fan out", "spin up multiple agents", "parallelize this", "analyze all my X and find patterns", "research A/B/C and build a roadmap", or "audit this repo".

**Cursor:**

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/waves/skills/waves -a cursor
```

**Codex:**

```bash
codex plugin marketplace add RayFernando1337/rayfernando-skills
codex plugin add waves-codex@rayfernando-skills
```

**Claude Code:** `/plugin install waves@rayfernando-skills` (Cursor-tuned) or `/plugin install waves-codex@rayfernando-skills` (Codex-tuned).

**Cross-vendor (`npx skills add`):** point the installer at either skill folder and pass `-a <agent>` (e.g. `-a codex`, `-a claude-code`, `--all`).

---

## bootstrap-ios — load the iOS agent stack

`bootstrap-ios` is a meta-skill for Apple-platform app work. It gives agents one
place to start before touching iOS, iPadOS, macOS, Swift, SwiftUI, SwiftData,
Core Data, Swift Testing, Xcode build/test/debug, Simulator, or App Intents.

It does not try to paste every community Swift rule into context. It routes the
agent to the right focused references and tools:

- Paul Hudson / Hacking with Swift skill packs for SwiftUI, concurrency,
  Swift Testing, and SwiftData.
- Antoine van der Lee / SwiftLee skill packs, including Xcode Build
  Optimization.
- Official OpenAI build iOS/macOS plugin references.
- Krzysztof Zablocki's public Merowing rules and rule-loader approach.
- AppCreator buildability ideas.
- XcodeBuildMCP for parseable Xcode build, test, simulator, and debug flows.

**Install the skill:**

```bash
/plugin install bootstrap-ios@rayfernando-skills
```

**Cursor / cross-vendor install:**

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/bootstrap-ios/skills/bootstrap-ios -a cursor
```

**Optional one-command helper, after installing or cloning:**

```bash
bash plugins/bootstrap-ios/skills/bootstrap-ios/scripts/bootstrap-ios-skills.sh --dry-run --agent cursor
```

Run without `--dry-run` only when you really want to install the public
community skill packs into that agent environment.

---

## Repo structure

```
rayfernando-skills/
├── .claude-plugin/
│   └── marketplace.json                 # marketplace catalog
├── plugins/
│   ├── running-bug-review-board/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json               # plugin manifest
│   │   └── skills/
│   │       └── running-bug-review-board/
│   │           ├── SKILL.md              # lean entry point; references load on demand
│   │           ├── references/           # loaded on demand
│   │           │   ├── workflow.md
│   │           │   ├── discovering-the-app.md
│   │           │   ├── test-plan.md
│   │           │   ├── test-accounts.md
│   │           │   ├── session-hygiene.md
│   │           │   ├── browser-playbook.md
│   │           │   ├── computer-use-playbook.md
│   │           │   ├── ios-simulator-playbook.md
│   │           │   ├── parallel-coordinator.md
│   │           │   ├── sequential-wrapup.md
│   │           │   ├── bug-filing.md
│   │           │   ├── gate-merge.md
│   │           │   ├── issue-trackers.md
│   │           │   ├── brb-interactive.md
│   │           │   ├── triage-heuristics.md
│   │           │   ├── html-report-style-guide.md
│   │           │   ├── extending-the-skill.md
│   │           │   └── templates/        # bug, test-plan, run-report, merge, BRB,
│   │           │       │                 #   qa-config, and html-report/ + samples/
│   │           │       └── html-report/
│   │           └── scripts/
│   │               ├── scaffold-qa.sh           # create the QA folder layout
│   │               ├── bugs-needing-sync.sh     # list bugs missing a tracker ID
│   │               └── bugs-needing-pull.sh     # list bugs with stale tracker sync
│   ├── waves/                     # Cursor variant (Task tool + Multitask Mode)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── skills/
│   │       └── waves/
│   │           ├── SKILL.md
│   │           ├── references/           # examples, handoff-format, verification
│   │           └── evals/                # evals.json + fixtures + eval README
│   ├── waves-codex/               # Codex variant (subagents + config.toml)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── skills/
│   │       └── waves-codex/
│   │           ├── SKILL.md
│   │           ├── agents/openai.yaml
│   │           ├── references/           # adaptation-notes, examples, handoff-format, recommended-config, verification
│   │           └── evals/                # evals.json + fixtures + eval README
│   └── bootstrap-ios/                            # iOS/macOS router skill + optional installer helper
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── bootstrap-ios/
│               ├── SKILL.md
│               ├── references/           # workflow, skill map, XcodeBuildMCP, sources
│               └── scripts/
│                   └── bootstrap-ios-skills.sh
├── scripts/
│   ├── validate-skill-metadata.py        # release-time Codex-metadata validator
│   └── validate-skill-evals.py           # release-time skill-eval validator
├── .github/workflows/release.yml         # builds the claude.ai zip on tag push
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Contributing

Issues and PRs welcome. If you've used the Skill file on a real project, a short writeup of a lesson learned is the most valuable contribution — a session-hygiene rule that saved you, a bug that reveals a new real-user pattern, or a playbook for an auth provider this skill doesn't cover yet. See [`extending-the-skill.md`](plugins/running-bug-review-board/skills/running-bug-review-board/references/extending-the-skill.md) for how the skill grows without rewrites.

Style guide: SKILL.md body under ~500 lines with references one level deep; imperative voice; third-person frontmatter description; examples from real projects; no time-sensitive copy (use "old patterns" sections instead).

---

## Background

Ray spent 12 years at Apple working across many parts of the system. The lesson he carried away: finding the bugs your users would hit first comes from a repeatable workflow, and he has been refining that cadence on his own projects ever since. The Skill files in this collection are his encoding of that work.

---

## Changelog

This project follows [Semantic Versioning](https://semver.org/) and [Keep a Changelog](https://keepachangelog.com/). Recent highlights: skill evals and deeper paper grounding for `waves` (Cursor + Codex); entropy-first decomposition and per-slice model routing in `waves`; the `waves` skill for parallel agent fan-out; plus a Computer Use + Chrome DevTools driver playbook, an editorial HTML report (Zite + Dieter Rams), and confirmed two-way issue-tracker sync. Full history in [`CHANGELOG.md`](CHANGELOG.md).

---

## License

[Apache License 2.0](LICENSE) — copyright 2026 Ray Fernando. The Skill files here can be used, modified, and redistributed in any project, including commercial and internal use. Attribution is appreciated but not required.
