# Recommended Codex Configuration

Use this as a starting point for the `parallel-orchestrate-codex` workflow. Put shared
defaults in `~/.codex/config.toml` or repo-specific settings in
`.codex/config.toml` for trusted projects.

## Default Manager/Worker Setup

```toml
# Manager default. Use GPT-5.5 for all roles; use reasoning effort to scale
# speed/cost/depth. Orchestration benefits from extra-high reasoning.
model = "gpt-5.5"
model_reasoning_effort = "xhigh"

[features]
multi_agent = true

[agents]
# Current Codex default is 6 when unset. Keep it explicit for this workflow.
max_threads = 6

# Current default is 1: root can spawn direct children, children cannot recurse.
max_depth = 1

# Default per-worker timeout for spawn_agents_on_csv jobs.
job_max_runtime_seconds = 1800
```

Recommended defaults:

- Manager/orchestrator: `gpt-5.5` with `xhigh` effort for complex problem
  solving, orchestration, deep thinking between steps, and synthesis before
  fan-out. Use `medium` only for simpler manager passes.
- Read-heavy workers: `gpt-5.5` with `low` effort for fast file reads, greps,
  counting, and simple scans.
- Research/all-around workers: `gpt-5.5` with `medium` effort.
- Implementation workers: `gpt-5.5` with `high` effort.
- Reviewer/security/verifier workers: `gpt-5.5` with `high` effort.
- `max_threads`: keep `6` as the default. Raise only for simple read-heavy work
  on a machine and rate-limit budget that can handle it.
- `max_depth`: keep `1`. Raise to `2` only for deliberate recursive delegation
  with strict instructions and budget awareness.

## Optional Custom Agents

Codex supports standalone custom agent TOML files under `~/.codex/agents/` for
personal agents or `.codex/agents/` for project agents. Each file needs `name`,
`description`, and `developer_instructions`. Optional fields such as `model`,
`model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, and `skills.config`
inherit from the parent when omitted.

### `.codex/agents/parallel-explorer.toml`

```toml
name = "parallel_explorer"
description = "Fast read-heavy explorer for bounded codebase, data, and log slices."
model = "gpt-5.5"
model_reasoning_effort = "low"
sandbox_mode = "read-only"
nickname_candidates = ["Atlas", "Kepler", "Noether", "Turing", "Hopper", "Lovelace"]

developer_instructions = """
Stay in exploration mode. Own only the assigned slice.
Prefer rg, targeted file reads, schema inspection, and concise evidence.
Do not edit files.
Return the requested structured handoff with coverage, confidence, and concrete sources.
"""
```

### `.codex/agents/docs-researcher.toml`

```toml
name = "docs_researcher"
description = "Documentation researcher that verifies APIs, versions, and current behavior through available docs/MCP/web tools."
model = "gpt-5.5"
model_reasoning_effort = "medium"
sandbox_mode = "read-only"

developer_instructions = """
Verify current API and framework behavior from primary documentation when possible.
Include source URLs and call out uncertainty or date-sensitive details.
Do not edit files unless explicitly assigned.
Return the requested structured handoff with confidence labels.
"""

[mcp_servers.openaiDeveloperDocs]
url = "https://developers.openai.com/mcp"
```

### `.codex/agents/parallel-worker.toml`

```toml
name = "parallel_worker"
description = "Implementation worker for one explicitly owned file or module slice."
model = "gpt-5.5"
model_reasoning_effort = "high"

developer_instructions = """
Own only the assigned files/modules.
You are not alone in the codebase: other workers may be active.
Do not revert changes you did not make. Keep unrelated files untouched.
Run focused verification for your slice and return the code/edit handoff.
"""
```

### `.codex/agents/reviewer.toml`

```toml
name = "reviewer"
description = "Read-only reviewer for correctness, security, regressions, and missing tests."
model = "gpt-5.5"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
Review like an owner.
Prioritize correctness, security, behavioral regressions, and missing tests.
Lead with concrete findings and evidence.
Avoid style-only comments unless they hide a real bug.
Return the requested structured handoff.
"""
```

### `.codex/agents/verifier.toml`

```toml
name = "verifier"
description = "Read-only verifier for checking claims against cited sources, commands, counts, or current docs."
model = "gpt-5.5"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
nickname_candidates = ["Verifier", "Crosscheck", "Evidence"]

developer_instructions = """
Your job is verification, not generation.
Check only the assigned claims against the provided sources, commands, or docs.
Do not inspect the generator's reasoning unless explicitly asked.
Return supported, partly-supported, unsupported, or source-not-found per claim.
Quote or cite the exact evidence that settles each verdict.
If evidence is missing or ambiguous, say so and mark confidence low.
Do not edit files.
"""
```

## Registering Custom Agents from Config

Standalone files in `.codex/agents/` are the simplest convention. If you want a
config file to declare roles explicitly, Codex's sample config also supports:

```toml
[agents]
max_threads = 6
max_depth = 1

[agents.parallel_explorer]
description = "Fast read-heavy explorer for bounded slices."
config_file = "./agents/parallel-explorer.toml"
nickname_candidates = ["Atlas", "Kepler", "Noether"]

[agents.reviewer]
description = "Find correctness, security, and test risks."
config_file = "./agents/reviewer.toml"
nickname_candidates = ["Ada", "Grace"]

[agents.verifier]
description = "Verify claims against cited evidence without seeing generator reasoning."
config_file = "./agents/verifier.toml"
nickname_candidates = ["Verifier", "Crosscheck"]
```

Paths in `config_file` are relative to the `config.toml` that defines them.

## Verification Defaults

Recommended acceptance bars for this workflow:

- Pre-fan-out: counts, slice bounds, partition-sum, gaps/duplicates.
- Every handoff: evidence resolves, scope matches, confidence labels preserved.
- High-stakes claims: verifier worker or CSV verifier pass.
- Code edits: tests or type checks plus a diff review.
- Generated files: parser/schema/validator where possible.
- Final response: keep `verified`, `single-sourced`, and `unverified` distinct.

Codex-native helpers:

- `spawn_agents_on_csv` for row-shaped verification when available.
- `codex exec --output-schema` for scripted claim-check outputs.
- `approvals_reviewer = "auto_review"` only for approval/security review; do not
  treat it as a general verifier.
- `web_search = "live"` or MCP docs tools when current sources are required.

## `codex exec` Fleet Pattern

For scriptable parallel writes, create one git worktree per attempt/slice and
run one `codex exec` per worktree:

```bash
git worktree add ../repo-auth-audit -b audit/auth
git worktree add ../repo-api-audit -b audit/api

codex exec --cd ../repo-auth-audit --sandbox workspace-write \
  --model gpt-5.5 -c 'model_reasoning_effort="high"' \
  "Audit and fix auth slice only. Return a code/edit handoff."

codex exec --cd ../repo-api-audit --sandbox workspace-write \
  --model gpt-5.5 -c 'model_reasoning_effort="high"' \
  "Audit and fix API slice only. Return a code/edit handoff."
```

Use `--json` for event streams and `--output-schema` when a script needs
machine-readable results.

## Skill Location Guidance

Current official Codex skill authoring locations:

- Repo-local: `.agents/skills/<skill-name>/`
- User-global: `$HOME/.agents/skills/<skill-name>/`
- Admin/system: `/etc/codex/skills/`
- Bundled system skills: shipped with Codex

Ray's local setup has previously used a `~/.codex/skills` to `$HOME/.agents`
symlink/plugin path, so `~/.codex/skills/<skill-name>/` may work on this
machine. For a portable Codex-native skill, prefer `$HOME/.agents/skills` or
repo `.agents/skills`.
