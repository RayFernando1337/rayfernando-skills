# rayfernando-skills

Ray Fernando's collection of installable Skill files for AI coding agents.

[![Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> **First Skill file: `running-bug-review-board`** — a real-user QA workflow combined with a Bug Review Board (BRB). The Skill file opens the live app, drives it like a customer, files structured bug reports, and tells the team whether the build is ready to ship.

---

## Skill files in this collection

| Skill file | What it does |
|------------|--------------|
| **[running-bug-review-board](./skills/running-bug-review-board/)** | Runs a real-user manual QA pass on any web or mobile app, files structured bug reports with P0/P1/P2 severity, supports parallel or sequential QA modes, and produces a YES/NO sign-off per phase. Repo-agnostic and browser-tool-agnostic. |

More Skill files are on the way. Each one packages a workflow that has been used on real projects.

---

## Why this collection exists

A lot of teams point their AI agents at code review and miss where users actually find bugs, which is the live app on a real phone with stale storage left over from yesterday and a flaky auth provider that the unit tests never see. The Skill files in this collection encode workflows that combine product, QA, and engineering checks into a single agent pass, and they give the team a concrete bug list to base ship-vs-defer decisions on.

---

## Install

### Claude Code (recommended)

Two commands inside Claude Code:

```
/plugin marketplace add RayFernando1337/rayfernando-skills
/plugin install running-bug-review-board@rayfernando-skills
```

That's it. Claude Code adds the marketplace, fetches the plugin, and the Skill file activates the next time an agent matches one of its trigger phrases (e.g. "QA this phase", "run a manual test plan", "is this ready to ship?").

To pin to a specific release tag:

```
/plugin marketplace add RayFernando1337/rayfernando-skills@v0.1.0
/plugin install running-bug-review-board@rayfernando-skills
```

### Cursor / Codex / Droid (and any other filesystem-based agent)

These agents read Skill files directly from a folder on disk. Clone the repo once and symlink the Skill file into each tool's skills directory:

```bash
# Clone once into a central location
git clone https://github.com/RayFernando1337/rayfernando-skills.git ~/Code/rayfernando-skills

# Symlink the Skill file into each tool's skill dir
for tool_dir in ~/.claude/skills ~/.cursor/skills ~/.codex/skills ~/.factory/skills; do
  mkdir -p "$tool_dir"
  ln -sf ~/Code/rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board \
         "$tool_dir/running-bug-review-board"
done
```

Replace the for-loop list with whichever tools you use. The Skill file works the same in every filesystem-based agent.

### Per-project install (project-scoped)

Some projects ship their own `.cursor/skills/` or `.claude/skills/` directories. Drop a symlink there to make the Skill file available to anyone who clones the project:

```bash
ln -s ~/Code/rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board \
      .claude/skills/running-bug-review-board
git add .claude/skills/running-bug-review-board
git commit -m "Add running-bug-review-board Skill file"
```

### claude.ai (Settings > Features > Skills)

Download `running-bug-review-board.zip` from the [latest release](https://github.com/RayFernando1337/rayfernando-skills/releases/latest) and upload it through Settings > Features > Skills.

Or build the zip yourself from a local clone:

```bash
cd plugins/running-bug-review-board/skills
zip -r ../../../running-bug-review-board.zip running-bug-review-board
```

Then upload `running-bug-review-board.zip` in claude.ai. (claude.ai expects a zip whose root directory contains `SKILL.md`.)

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

For repos that don't have a QA folder yet, the Skill file includes a scaffolder:

```bash
bash ~/Code/rayfernando-skills/plugins/running-bug-review-board/skills/running-bug-review-board/scripts/scaffold-qa.sh \
     /path/to/your/repo PHASE_NUMBER
```

This creates `docs/qa/` with the bug-report template, run-report skeletons, gates checklist, and per-phase manual test plan — idempotent, won't overwrite anything.

---

## How the Skill file works

- **Drives the live app.** The agent works through URLs and clicks, and the Skill file forbids marking PASS from code inspection alone.
- **PM, QA, and engineering checks in one pass.** Every pass confirms the user-promise (PM), executes scenarios (QA), and flags invalidated assumptions (engineering). Finding gaps is the point.
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
- Examples grounded in real projects, not invented scenarios
- No time-sensitive copy (use "old patterns" sections instead)

---

## Background

Ray spent 12 years at Apple working across many different parts of the system. One thing he came away with from that whole tenure is that finding the bugs your users would hit first comes from a repeatable workflow, and he has been refining the cadence on his own projects ever since. The Skill files in this collection are his encoding of that work.

---

## License

[Apache License 2.0](LICENSE) — copyright 2026 Ray Fernando.

The Skill files here can be used, modified, and redistributed in any project, including commercial and internal use. Attribution is appreciated but not required by the license.
