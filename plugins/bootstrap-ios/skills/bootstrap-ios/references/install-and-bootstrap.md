# Install And Bootstrap

This reference is for machine setup. Do not use it just because an iOS repo is
present; use it when the user asks to install, bootstrap, or load Ray's iOS
skills.

## Default answer to "do I need an install script?"

For normal agent work, no: this `bootstrap-ios` skill is the main entry point,
and agents should load the referenced skills/rules as needed.

For a new machine or agent environment, yes: run the helper script so the public
community skills and XcodeBuildMCP setup are installed consistently.

## Dry run first

From this skill folder:

```bash
bash scripts/bootstrap-ios-skills.sh --dry-run --agent cursor
```

Targets:

- `--agent cursor`
- `--agent codex`
- `--agent claude-code`
- `--agent droid`
- omit `--agent` to let `npx skills add` auto-detect where possible

Install globally after confirming:

```bash
bash scripts/bootstrap-ios-skills.sh --agent cursor
```

The helper passes `--global --yes` to `npx skills add` once you remove
`--dry-run`, so the install is actually one command after the user chooses to
modify the machine.

## Verification (missing and shallow installs fail loudly)

After a real (non-dry-run) install, the helper verifies every expected skill
actually landed and is complete: `SKILL.md` present under a known skill root,
and every `references/`, `scripts/`, and `assets/` file cited in it actually
on disk. Two observed failure modes make this necessary: installers exiting
zero without laying a skill down at all (reported as `NOT INSTALLED:`), and
installers writing only `SKILL.md` without the reference files ("shallow
installs", reported per-file as `MISSING:`). Either way an agent would load
the skill, follow a `references/` pointer, and silently degrade.

If verification fails, the script exits non-zero, prints each `NOT INSTALLED:`
skill or `MISSING:` path, and tells you the fix:

```bash
npx skills add <skill-url> --global --yes --full-depth
```

or clone the upstream repo and copy the full skill folder (SKILL.md +
references/ + scripts/) into the agent's skills directory yourself.

Pass `--skip-verify` to opt out. Verification checks these global skill roots:
`~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills`,
`~/.cursor/skills-cursor`, `~/.codex/skills`, `~/.factory/skills`.

Include optional setup:

```bash
bash scripts/bootstrap-ios-skills.sh --agent cursor --include-xcodebuildmcp-init
```

## What the helper installs

Public GitHub-hosted skill folders:

- twostraws SwiftUI Pro
- twostraws Swift Concurrency Pro
- twostraws Swift Testing Pro
- twostraws SwiftData Pro
- AvdLee SwiftUI Expert
- AvdLee Swift Concurrency
- AvdLee Swift Testing Expert
- AvdLee Core Data Expert
- AvdLee Xcode Build Optimization skill pack, discovered with `--full-depth`

The helper points at the concrete skill folders when repos keep `SKILL.md` below
repo root. Do not simplify those URLs back to repo roots unless `npx skills add
--list` proves the installer now discovers them correctly.

It does not install:

- AppCreator, because it is not published as a GitHub skill repo in the article.
- Merowing Swifty Stack course-only rules.
- Official OpenAI plugin paths unless the target agent supports plugin install
  and the current paths are verified.

## After install

Ask the agent to use `bootstrap-ios` before touching Apple-platform code. The
external skills become the focused references; this skill stays the router.
