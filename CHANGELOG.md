# Changelog

All notable changes to this collection are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-26

### Added

- First Skill file: `running-bug-review-board` — a real-user QA workflow with a Bug Review Board (BRB). Drives the live app like a customer, files structured P0/P1/P2 bug reports, and produces a YES/NO sign-off per phase.
- `.claude-plugin/marketplace.json` so users can install with two commands: `/plugin marketplace add RayFernando1337/rayfernando-skills` followed by `/plugin install running-bug-review-board@rayfernando-skills`.
- Repo restructured to the standard marketplace layout with the plugin under `plugins/running-bug-review-board/`.
- GitHub Actions workflow that builds a claude.ai-compatible zip artifact whenever a `v*` tag is pushed, attached to the GitHub Release.

[0.1.0]: https://github.com/RayFernando1337/rayfernando-skills/releases/tag/v0.1.0
