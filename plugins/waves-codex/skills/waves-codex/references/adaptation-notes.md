# Adaptation Notes

These notes record how the Cursor skill was translated into Codex-native terms.
They are part of the skill so future edits do not accidentally reintroduce
Cursor plumbing.

## Verified Codex Sources

Checked on 2026-06-14 with web search, Ref, Exa, current local `codex exec
--help`, and the active tool registry:

- Codex Subagents: `https://developers.openai.com/codex/subagents`
- Codex Subagent Concepts: `https://developers.openai.com/codex/concepts/subagents`
- Codex Skills: `https://developers.openai.com/codex/skills`
- Codex Config Basics: `https://developers.openai.com/codex/config-basic`
- Codex Config Sample: `https://developers.openai.com/codex/config-sample`
- Codex App Worktrees: `https://developers.openai.com/codex/app/worktrees`
- Codex non-interactive mode / `codex exec`: `https://developers.openai.com/codex/noninteractive`
- Codex approvals and Auto-review: `https://developers.openai.com/codex/agent-approvals-security`
- Codex best practices: `https://developers.openai.com/codex/learn/best-practices`
- OpenAI Symphony post: `https://openai.com/index/open-source-codex-orchestration-symphony/`

The active tool registry in this session exposed `spawn_agent`, `wait_agent`,
`send_input`, and `close_agent`, but not `spawn_agents_on_csv`, even though
official docs describe it as experimental.

## What Stayed Portable

- Mental model: discover -> stage -> verify coverage -> decompose -> fan out ->
  handoffs -> verify claims -> synthesize -> second waves.
- Manager/worker separation.
- Worker isolation as a prompting discipline: one slice, one handoff, no
  sibling assumptions.
- Parallel reads as the safest default.
- Fixed handoff format.
- Verification layer: pre-fan-out gate, cheap handoff checks, confidence labels,
  verifier workers, deliverable validation, and escalation.
- Decomposition recipes: data chunks, multi-stream research, repo audit, and
  parallel implementation with explicit ownership.
- Continuous motion until every slice is terminal or explicitly out of scope.
- Entropy-first decomposition: reduce uncertainty (dig locally, then attached
  resources, then ask the user only if it pays) before slicing; cascade a
  decomposition wave into an execution wave; order the plan least-to-most.
- Paper-grounded technique detail, mirrored with the Cursor skill: probe
  selection that halves the surviving interpretations; ask-vs-act thresholds;
  factored self-verification with open check questions; sample-and-vote with
  agreement as a confidence flag; judge blinding (no authorship labels, both
  orderings); disjoint-family judge panels; atomic-fact checks with
  self-contained rewrites; citation URL-health passes. Sources listed in
  `references/verification.md` ("Grounding") and `references/examples.md`.
- Skill evals: both variants ship `evals/evals.json` + fixtures following the
  Anthropic skill-creator format (prompt + expected_output + expectations,
  graded PASS/FAIL with evidence against with-skill vs baseline transcripts).

## Cursor-to-Codex Swaps

| Cursor source idea | Codex-native replacement |
| --- | --- |
| `Task` tool with `subagent_type` and `run_in_background: true` | Explicit Codex subagent delegation: spawn one agent per slice, usually in one manager turn, then wait/synthesize. Direct tool names may appear as `spawn_agent`, `wait_agent`, `send_input`, and `close_agent`, but the stable user-facing contract is "spawn N agents, wait for all, consolidate." |
| "Multitask Mode" | Codex subagent workflows in the app/CLI. Current docs say Codex waits for all requested subagent results and returns one consolidated response. |
| `explore` | Built-in `explorer` for read-heavy exploration. Unlike Cursor's original note, do not assume this is offline/no-MCP; Codex subagents inherit sandbox/tooling, and custom agents can set `sandbox_mode = "read-only"`. |
| `generalPurpose` | Built-in `default`, built-in `worker`, or a custom agent such as `docs_researcher` depending on the task. |
| `shell` | Usually built-in `worker` with shell access inherited from the session, or a custom shell-heavy worker. |
| `best-of-n-runner` | Codex app Worktree mode, or plain `git worktree` plus one `codex exec` run per attempt. There is no exact local built-in named `best-of-n-runner` in the verified Codex docs. |
| `TodoWrite` | Codex `update_plan`. |
| Frontmatter `disable-model-invocation: true` | Included for the cross-vendor opt-in default (Cursor and Claude Code read it to require explicit `/waves-codex` invocation, since a run spawns more agents than usual). Codex itself discovers skills by metadata and only spawns subagents when explicitly asked, so the field is inert there but harmless. |
| `~/.cursor/skills/<name>/` | Current Codex docs document repo `.agents/skills`, user `$HOME/.agents/skills`, admin `/etc/codex/skills`, and system bundled skills. Ray's local memory shows `~/.codex/skills` may exist as a symlink/plugin compatibility path, but `$HOME/.agents/skills` is the better global authoring target. |
| "End your turn and wait for completion notifications" | Ask Codex to spawn, wait for all requested workers, and consolidate. In direct tool mode, continue useful manager-side work and wait only when blocked; do not busy-poll. |
| "Stage remote data because read-only workers are offline" | Reconciled. Codex workers may have full tool/MCP/network access depending on session config, so staging is an optimization and safety move, not always a requirement. |
| "Local workers share one filesystem, so parallel writes are dangerous" | Reconciled. Codex can use isolated sandboxes/worktrees and manager-mediated merging, making parallel writes safer. Still avoid overlapping edits unless using worktrees or isolated `codex exec` runs. |
| `/orchestrate` cloud plugin via Cursor SDK | `codex exec` fleets for scripts/CI, Codex app worktrees for local parallel code, and the Symphony pattern for always-on issue-tracker orchestration. |
| Data-chunk fan-out by many background `Task` calls | `spawn_agents_on_csv` when each row maps to one worker and the experimental tool is available; otherwise normal `explorer` waves. |
| Dedicated verifier worker | Custom Codex verifier agent, normal `explorer`/`default` verifier prompts, or `spawn_agents_on_csv` verifier-per-row batch when available. |
| "Verify before you trust" | Codex manager runs pre-fan-out gates, cheap handoff checks, separate verifier waves, and final deliverable validation. |
| Recursive subplanner idea | Dropped from the default. Current docs say `agents.max_depth` defaults to `1`; raise it only for explicit recursive delegation. |
| Entropy-first decomposition (dig locally then attached resources then ask only if it pays; scouting wave then execution wave; least-to-most) | Portable as-is; `update_plan` replaces `TodoWrite` for the living plan. |
| "Route scouting/read waves to Composer 2.5 (fast) via the `model` field" | Route scouting/read waves to `gpt-5.5` at `low` effort (or `gpt-5.4-mini`) via the per-spawn `reasoning_effort` field. `model_reasoning_effort` is the config/TOML key. `service_tier` / `/fast` is a user-enabled speed tier, not a forced default. |

## Things That Do Not Translate Exactly

- Codex docs do not present `explorer` as a hard offline mode. It is a role, not
  an air-gapped worker. Use sandbox and MCP configuration to shape actual access.
- Codex docs caution that write-heavy parallel workflows can still conflict.
  Worktrees are the reliable isolation boundary for serious parallel code
  attempts.
- `spawn_agents_on_csv` is documented as experimental and may not be exposed in
  every Codex surface or session. Keep a non-CSV subagent fallback.
- I did not find a current public Codex doc for a general arbitrary-claim
  verifier/eval/critic hook. Codex Auto-review exists, but it evaluates approval
  requests at the sandbox/security boundary only. Codex GitHub review and
  `/review` are code-review surfaces, not general handoff verification.
- Custom agent TOML is documented, but the docs note the format may evolve as
  authoring and sharing mature.
- `~/.codex/skills` may be present in local/plugin flows, but the current
  official skill authoring locations emphasize `.agents/skills` and
  `$HOME/.agents/skills`.
- Codex effort has two field names: the live per-spawn `spawn_agent` field is
  `reasoning_effort`, while the config / custom-agent TOML key is
  `model_reasoning_effort`. `service_tier` (`fast` / `flex`) and the `/fast`
  toggle are user-facing speed levers, not general model routing. Reasoning
  levels are `minimal`, `low`, `medium`, `high`, `xhigh`; `gpt-5.4-mini` and
  `gpt-5.3-codex-spark` are lighter/faster options for read-heavy subagent work.

## Why the Final Skill Is Opinionated

This port keeps the original orchestration discipline, but changes the local
gotchas:

- The safest default remains read-heavy fan-out.
- Staging remains useful for clean inputs and repeatability, not because every
  worker is offline.
- Verification is now a first-class step because unchecked worker errors compound
  across waves.
- Parallel implementation is allowed only with clear ownership or worktrees.
- The default config keeps `max_depth = 1` to prevent accidental recursive
  explosion.
- `max_depth = 1` caps *recursion only* (a worker spawning its own workers). It
  does not cap manager-driven sequential waves: continuous motion across second
  and third waves at depth 1 is preserved from the Cursor skill and is the
  expected shape. Do not let the recursion cap leak into "spawn fewer waves" --
  the gated "only important / if needed" phrasing was deliberately reverted to
  Cursor's "each bullet is a candidate second-wave task."
