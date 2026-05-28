# rayfernando-skills

Ray Fernando's collection of installable Skill files for AI coding agents.

[![Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> **First Skill file: `running-bug-review-board`** — a real-user QA workflow combined with a Bug Review Board (BRB). The Skill file opens the live app, drives it like a customer, files structured bug reports, and tells the team whether the build is ready to ship.

---

## What's new in v0.3.1

- **Codex compatibility fix.** The Skill frontmatter description is now
  concise enough for Codex's 1024-character metadata limit, while the
  full workflow remains in the Skill body and references for progressive
  disclosure in Codex app, desktop, IDE, and CLI surfaces.
- **Release validation.** A repository validator now checks Skill and
  plugin metadata before release so overlong descriptions cannot ship
  again.

## What's new in v0.3

- **HTML report redesigned around editorial typography.** Inspired by Zite and Dieter Rams. Magazine layout, 640px reading column, ink-on-paper palette, hairline rules. **No coloured chips, no pills, no shadows.** Priority is the word `P0` in small caps in the eyebrow; status is the word `Open`; verdict is a single display-type word (`YES` or `NO`). One ink colour for body, one quiet terracotta accent for links and CTAs. On desktop, bug detail pages gain a quiet right rail for metadata; on mobile, a sticky `thumb-zone` shelf keeps the primary action in reach without scrolling back up. Light + dark + print stylesheets.
- **Engineer-reviewer information hierarchy.** Each bug detail page reads in the order the eye sweeps: Eyebrow (priority · phase · status · tracker) → Title → Deck → **Impact** (a serif pull-quote — what does a user experience if this ships?) → What's happening / What should happen → **Risk to fix** (a quiet engineer's marginal note, hidden when empty) → Steps → Evidence → Triage log.
- **Two new bug template fields:** `## Impact` (filled at file time) and `## Risk to fix` (usually empty at file time; engineer populates during BRB). Both additive — v0.2 bugs render gracefully without them.
- **Design samples in the repo** under [`samples/`](plugins/running-bug-review-board/skills/running-bug-review-board/references/templates/html-report/samples) (dashboard desktop, dashboard mobile, bug-detail desktop) so contributors and reviewers can see the design language at a glance.

## What's new in v0.2

- **Apple-language HTML dashboard.** Every pass and BRB regenerates `docs/qa/report/index.html`. *(Restyled in v0.3 — see above.)*
- **Issue-tracker integration — discovered and confirmed.** Linear (via Linear MCP), GitHub Issues (via `gh`), Jira, or Notion. The skill probes signals and asks the user before writing `docs/qa/qa-config.json`. Never assumed silently.
- **Bi-directional sync.** Engineering's status changes flow back from the tracker into local markdown at BRB start and during re-tests.
- **Interactive BRB (separate session).** A facilitator-agent workflow with pre-BRB tracker pull, pattern-based triage heuristics, per-bug walk, HTML refresh, minutes. Kept separate from the auto pass on purpose.
- **iOS / iPadOS app testing — curated cite hub.** When the repo is an iOS app project, the skill defers actual simulator driving to the iOS community's purpose-built skills ([Cameron Cooke's AXe](https://github.com/cameroncooke/AXe), [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP); [Rudrank Riyam's ASC CLI + skills](https://github.com/rudrankriyam/App-Store-Connect-CLI); [Conor Luddy's ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill); [Josh Adams's ios-build-verify](https://github.com/vermont42/ios-build-verify); [tddworks' baguette](https://github.com/tddworks/baguette); and others).
- **Extension story.** Forward-compatible `qa-config.json` schema. See [`extending-the-skill.md`](plugins/running-bug-review-board/skills/running-bug-review-board/references/extending-the-skill.md).

## Skill files in this collection

| Skill file | What it does |
|------------|--------------|
| **[running-bug-review-board](./plugins/running-bug-review-board/skills/running-bug-review-board/)** | Runs a real-user manual QA pass on any web or mobile app, files structured bug reports with P0/P1/P2 severity, supports parallel or sequential QA modes, and produces a YES/NO sign-off per phase. Repo-agnostic and browser-tool-agnostic. |

More Skill files are on the way. Each one packages a workflow that has been used on real projects.

---

## Why this collection exists

A lot of teams point their AI agents at code review and miss where users actually find bugs, which is the live app on a real phone with stale storage left over from yesterday and a flaky auth provider that the unit tests never see. The Skill files in this collection encode workflows that combine product, QA, and engineering checks into a single agent pass, and they give the team a concrete bug list to base ship-vs-defer decisions on.

---

## Install

Pick the section for the agent you use. Each one installs the same Skill file; they only differ in how the agent discovers it.

### Claude Code

Two slash commands inside Claude Code:

```
/plugin marketplace add RayFernando1337/rayfernando-skills
/plugin install running-bug-review-board@rayfernando-skills
```

To pin a specific release tag:

```
/plugin marketplace add RayFernando1337/rayfernando-skills@v0.1.0
/plugin install running-bug-review-board@rayfernando-skills
```

Docs: [code.claude.com/docs/en/plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces).

### Factory Droid

Two commands in your shell:

```bash
droid plugin marketplace add https://github.com/RayFernando1337/rayfernando-skills
droid plugin install running-bug-review-board@rayfernando-skills
```

Factory Droid's plugin manager reads the same `.claude-plugin/marketplace.json` that Claude Code uses, so the install lines up one-to-one. The `droid plugin marketplace add` command expects a full HTTPS Git URL.

Docs: [docs.factory.ai/cli/configuration/plugins](https://docs.factory.ai/cli/configuration/plugins).

### Codex app, desktop, IDE, and CLI

Codex supports Skills across the app, desktop experience, IDE extension,
and CLI. If you use the CLI, add the marketplace from your shell:

```bash
codex plugin marketplace add RayFernando1337/rayfernando-skills
```

Then install the plugin. On Codex CLI 0.126 and later, the second step is one CLI command:

```bash
codex plugin add running-bug-review-board@rayfernando-skills
```

On Codex CLI 0.125 and earlier, the `plugin add` subcommand isn't there
yet. Open Codex, type `/plugins`, switch to the `rayfernando-skills`
tab, and select Install. In Codex app or desktop surfaces, use the
Plugins / Skills installer UI for the same marketplace and restart Codex
after installing so the skill cache reloads. Codex's marketplace loader
supports `.claude-plugin/marketplace.json` as a legacy-compatible source,
so the same repo works for both flows.

If Codex shows:

```text
invalid description: exceeds maximum length of 1024 characters
```

you are likely running a cached `running-bug-review-board` 0.3.0 install.
Update or reinstall `running-bug-review-board@rayfernando-skills`, then
restart Codex app, desktop, IDE, or CLI so it refreshes the plugin cache.

Docs: [developers.openai.com/codex/plugins/build](https://developers.openai.com/codex/plugins/build).

### Cursor

Cursor's slash command `/add-plugin <slug>` is reserved for plugins listed at [cursor.com/marketplace](https://cursor.com/marketplace) and doesn't accept arbitrary GitHub repos yet. For this repo today, use the cross-vendor installer below — it writes the Skill folder into `~/.cursor/skills/`, which Cursor reads on startup.

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/running-bug-review-board/skills/running-bug-review-board -a cursor
```

Docs for Cursor's Skills system: [cursor.com/docs/skills](https://cursor.com/docs/skills).

### Cross-vendor: `npx skills add`

The [`vercel-labs/skills`](https://github.com/vercel-labs/skills) installer detects every supported agent CLI on your machine and writes the Skill folder into each one's expected location (Claude Code, Cursor, Codex, Factory Droid, Windsurf, Zencoder, and ~50 others). Pointing at the Skill folder URL is the most reliable form for a nested marketplace repo like this one:

```bash
npx skills add https://github.com/RayFernando1337/rayfernando-skills/tree/main/plugins/running-bug-review-board/skills/running-bug-review-board
```

Add `-a <agent>` to target a single tool (e.g. `-a cursor`, `-a codex`, `-a droid`) or `--all` to write to every detected agent.

### claude.ai (Settings > Features > Skills)

Download `running-bug-review-board.zip` from the [latest release](https://github.com/RayFernando1337/rayfernando-skills/releases/latest) and upload it through Settings > Features > Skills.

To build the zip yourself from a local clone:

```bash
cd plugins/running-bug-review-board/skills
zip -r ../../../running-bug-review-board.zip running-bug-review-board
```

claude.ai expects a zip whose root directory contains `SKILL.md`.

### Manual install (any other agent)

For agents without a CLI installer or marketplace integration, clone the repo once and symlink the Skill folder into whichever directory the agent reads:

```bash
git clone https://github.com/RayFernando1337/rayfernando-skills.git ~/Code/rayfernando-skills
ln -sf ~/Code/rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board \
       ~/.<agent>/skills/running-bug-review-board
```

Replace `~/.<agent>/skills/` with the path your agent uses (`~/.cursor/skills/`, `~/.codex/skills/`, `~/.factory/skills/`, etc.). The same symlink can be committed inside a project repo (e.g. under `.claude/skills/` or `.cursor/skills/`) so anyone who clones the project picks up the Skill file.

---

## Quick start: run your first QA pass

Once installed, ask any AI agent:

> *"QA this app. Run a manual test plan and tell me what's broken."*

The Skill file activates and walks the agent through:

1. **Discover the app** — read product spec, phase doc, open bugs, public routes.
2. **Plan** — derive scenarios from spec + phase doc + gates.
3. **Prepare** — environment, auth test fixtures, viewport.
4. **Execute** — drive the browser like a real user, capture evidence.
5. **File bugs** — `BUG-NNN-*.md` with priority + reproduction steps.
6. **Sign off** — YES/NO verdict with open P0/P1 list and a paste-ready handoff prompt.

For repos that don't have a QA folder yet, the Skill file ships a scaffolder. After installing, the script lives inside the Skill folder (e.g. `~/.claude/skills/running-bug-review-board/scripts/scaffold-qa.sh`). To run it without installing first, clone the repo and call the script directly:

```bash
git clone https://github.com/RayFernando1337/rayfernando-skills.git
bash rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board/scripts/scaffold-qa.sh \
     /path/to/your/repo PHASE_NUMBER
```

This creates `docs/qa/` with the bug-report template, run-report skeletons, gates checklist, and per-phase manual test plan. The scaffolder is idempotent and won't overwrite an existing file.

---

## How the Skill file works

- **Drives the live app.** The agent works through URLs and clicks, and the Skill file forbids marking PASS from code inspection alone.
- **PM, QA, and engineering checks in one pass.** Every pass confirms the product still does what the spec promises and runs the user scenarios end-to-end. Any engineering assumption that breaks under real use gets logged on the report. Finding gaps is the point.
- **BRB cadence.** Bugs land in a versioned folder with status transitions (`open → in-progress → fixed → verified`). Severity P0/P1/P2 tells the team what to ship and what to defer.
- **Tool-agnostic.** Works with cursor-ide-browser, browser-use, Playwright, or manual driving. Cursor-first by default.
- **Repo-agnostic.** Adopts whatever conventions exist, and scaffolds folders when there are none.
- **Parallel + sequential modes.** Coordinator launches shards for full passes, and sequential mode wraps up after stalls and re-tests fixed bugs.

---

## Repo structure (under the hood)

The repo follows the standard Claude Code marketplace layout. Each Skill file uses progressive disclosure with a lean SKILL.md and references loaded on demand.

```
rayfernando-skills/
├── .claude-plugin/
│   └── marketplace.json              # marketplace catalog
├── plugins/
│   └── running-bug-review-board/
│       ├── .claude-plugin/
│       │   └── plugin.json           # plugin manifest
│       └── skills/
│           └── running-bug-review-board/
│               ├── SKILL.md          # main entry (~265 lines)
│               ├── references/       # loaded on demand
│               │   ├── workflow.md
│               │   ├── discovering-the-app.md
│               │   ├── test-plan.md
│               │   ├── test-accounts.md
│               │   ├── session-hygiene.md
│               │   ├── browser-playbook.md
│               │   ├── parallel-coordinator.md
│               │   ├── sequential-wrapup.md
│               │   ├── bug-filing.md
│               │   ├── gate-merge.md
│               │   └── templates/    # bug, test-plan, run-report, merge skeletons
│               └── scripts/
│                   └── scaffold-qa.sh   # universal QA folder scaffold
├── .github/workflows/release.yml     # builds claude.ai zip on tag push
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Contributing

Issues and PRs welcome. If you've used the Skill file on a real project and want to share a lesson learned, open a PR with a short writeup. Useful contributions include a session-hygiene rule that saved you, a bug that reveals a new pattern in real-user testing, or a playbook for an auth provider this Skill file doesn't cover yet.

Style guide for contributions:

- SKILL.md body under 500 lines, references one level deep
- Imperative voice, third-person frontmatter description
- Examples drawn from real projects with the project name when it's shareable
- No time-sensitive copy (use "old patterns" sections instead)

---

## Background

Ray spent 12 years at Apple working across many different parts of the system. One thing he came away with from that whole tenure is that finding the bugs your users would hit first comes from a repeatable workflow, and he has been refining the cadence on his own projects ever since. The Skill files in this collection are his encoding of that work.

---

## License

[Apache License 2.0](LICENSE) — copyright 2026 Ray Fernando.

The Skill files here can be used, modified, and redistributed in any project, including commercial and internal use. Attribution is appreciated but not required by the license.
