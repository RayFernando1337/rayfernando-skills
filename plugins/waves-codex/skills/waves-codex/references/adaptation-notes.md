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

Re-checked on 2026-07-03 against the Codex Config Reference
(`https://developers.openai.com/codex/config-reference`) and changelog
(`https://developers.openai.com/codex/changelog`):

- `features.multi_agent` now documents five collaboration tools:
  `spawn_agent`, `send_input`, `resume_agent`, `wait_agent`, `close_agent`
  (stable, on by default). `resume_agent` reopens a closed agent so it can
  receive `send_input` / `wait_agent` again.
- Custom agents are standalone TOML files (one per file) under
  `~/.codex/agents/` or `.codex/agents/`; project agents load in **trusted
  projects only**. Spawning an unknown `agent_type` fails with an error — there
  is no silent fallback (the `default` role is used only when `agent_type` is
  omitted). The skill's "spawn `default`/`worker`/`explorer` with the role's
  instructions inlined" fallback is our recommendation, not documented
  behavior.
- `agents.max_threads` still defaults to `6`, `agents.max_depth` to `1`;
  `spawn_agents_on_csv` is still experimental (now also documents a
  per-call `max_runtime_seconds` override of `agents.job_max_runtime_seconds`).

Re-checked on 2026-07-19 against the subagents doc, config reference, Codex
changelog, the Responses API multi-agent guide, and the openai/codex source
tree (a parallel verification wave with per-claim evidence):

- Official docs no longer enumerate the collaboration tool names. The current
  multi-agent V2 surface (code + Responses API multi-agent guide) is
  `spawn_agent`, `send_message`, `followup_task`, `wait_agent`,
  `interrupt_agent`, `list_agents` -- note `interrupt_agent`, not
  `close_agent`. The V1 set (`spawn_agent`, `send_input`, `resume_agent`,
  `wait_agent`, `close_agent`) survives only on threads resumed from before
  the V2 runtime metadata existed ("Threads created before runtime metadata
  existed keep the legacy V1 tool surface" -- codex-rs session code).
- The documented reasoning-effort ladder on the subagents page is now `none`,
  `minimal`, `low`, `medium`, `high`, `xhigh`, `max`, `ultra` (higher/lower
  levels "when the selected model supports" them); the config-reference type
  string is stale (`minimal..xhigh`). For the GPT-5.6 API the ladder is
  `none..max`; `ultra` is a product setting that converts to `max` plus
  proactive multi-agent.
- GPT-5.6 family GA 2026-07-09 (`gpt-5.6` aliases `gpt-5.6-sol`; `-terra`,
  `-luna` tiers). Official Codex subagent guidance: start with `gpt-5.6`, use
  `gpt-5.6-terra` for lighter subagent work, `gpt-5.3-codex-spark` for
  near-instant text-only (Pro). Luna is not recommended for subagents in
  official docs and has a measured long-context cliff (MRCR 41.3% at 256-512K
  vs Sol 91.5%). Codex CLI 0.144.4/5 corrected GPT-5.6 context to 272K in
  clients.
- V2 `spawn_agent` exposes per-spawn `model`/`reasoning_effort` overrides only
  behind `multi_agent_v2.expose_spawn_agent_model_overrides`; custom-agent
  TOML routing always works. V1 `fork_context` / V2 `fork_turns` (fork parent
  history into a child) exist in code but are undocumented -- don't build on
  them.
- V2 delegation payloads (`spawn_agent`/`send_message`/`followup_task`
  messages) are encrypted between model calls, so spawn prompts can no longer
  be audited from local rollout history.
- `thread/start.multiAgentMode` (app-server) shipped June 17 and is already
  deprecated ("Use Ultra reasoning effort for proactive multi-agent
  behavior").
- Desktop threads can receive undocumented `codex_app.*` thread-management
  tools (`create_thread`, `list_threads`, `read_thread`,
  `send_message_to_thread`, `fork_thread`, `handoff_thread`,
  `set_thread_title`, `set_thread_pinned`, `set_thread_archived`) --
  Desktop-local + feature-flag gated; remote/mobile/CLI-started threads and
  pre-feature resumed threads miss them (openai/codex #26907, #25990, #25818
  all open). Basis for the SKILL's "Coordinator Thread Mode" and its
  probe-then-fallback rule.

Native-delegation deep dive, checked 2026-07-19 against codex-rs source at
main (commit-level evidence), official docs, and July field reports:

- Delegation mode is derived from reasoning effort per turn
  (`core/src/session/multi_agents.rs`): `ultra` -> Proactive, anything else ->
  ExplicitRequestOnly. The injected explicit-mode policy text is "Do not spawn
  sub-agents unless the user or applicable AGENTS.md/skill instructions
  explicitly ask" -- skill text is a first-class, documented delegation
  trigger; `ultra` is never required for waves. The deprecated
  `multiAgentMode` app-server params are ignored.
- V2 eligibility is model-catalog-driven: `gpt-5.6-sol` and `gpt-5.6-terra`
  are V2; `gpt-5.6-luna` is V1 (so V2 parents cannot spawn Luna children);
  maintainers state 5.6 roots can only spawn 5.6+ models.
- Native V2 spawns default to a full-history fork (`fork_turns` defaults to
  `all`; filtered -- keeps user/system/final-answer messages, drops reasoning
  and tool output). Full-history forks inherit the parent's agent type, model,
  and effort and REJECT overrides; fresh-context spawns (`fork_turns: none`)
  are the routable shape. Children inherit parent model/effort by default --
  the July quota-burn failure mode (#31814: e.g. 888 model invocations /
  103.6M input tokens across 3 tasks when Sol-Ultra bred Sol-Ultra children).
- Custom TOML role routing was broken on 5.6 V2 at GA (roles -> `agent_role:
  null`, model and sandbox pins ignored -- #31814, #32587, #32782). 0.145+
  re-exposes per-spawn `model`/`reasoning_effort` with baked guidance to honor
  them "only when explicitly requested by the user, applicable AGENTS.md
  instructions, or skill instructions" (maintainer: "the model is not good
  enough yet to judge"). V2 exposes `agent_type` only when custom agents are
  registered. Consequence: inlined role instructions + explicit per-spawn
  model/effort requests are the primary pattern; TOML is optional tuning.
- V2 does not enforce `agents.max_depth`; the binding limit is
  `multi_agent_v2.max_concurrent_threads_per_session` (default 4 including
  the root; `agents.max_threads + 1` when set). V2 has no `close_agent`;
  lifecycle verbs are `followup_task`, `send_message`, `wait_agent`,
  `interrupt_agent`, `list_agents`.
- Codex CLI/app does NOT use the server-side Responses API multi-agent beta
  (no `multi_agent` request field anywhere in codex-rs); all orchestration is
  client-side. The hosted beta is a parallel implementation of the same six
  actions for API developers.
- Encrypted V2 delegation payloads + children hidden from `/agent` mean
  post-hoc transcript audits are gone; the wave manifest is the spawn-plan
  audit, reviewed before dispatch.

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
- Run mechanics, mirrored with the Cursor skill: the wave manifest (slice /
  role / effort / depends_on / verification tier) doubling as the completion
  gate; the worker failure ladder (steer/resume or re-spawn narrower once ->
  do it in the manager thread -> carry as `not-covered`); the `.waves/<run>/`
  scratch-dir convention with `synthesis-wave-N.md` compression at the
  barrier; handoff digest caps; and the SWE recipes
  (implement-a-reviewed-plan, row-shaped codemod, CI-failure triage) in
  `references/examples.md`. Codex keeps worker prompt endings in
  `references/handoff-format.md` § "Prompt endings per worker type".
- Run-shape triage (state the shape in one line before spawning; on the fence
  pick the smaller; never present inline work as wave coverage) and
  dependency-aware dispatch (`depends_on` in the manifest; a wave is every
  slice whose dependencies are met, where met means the dependency's handoff
  has been verified, not merely returned; dependents launch with distilled
  findings folded into their prompts).
  Both portable as-is; adapted from reviewing Phillip Chaffee's public
  `deep-research` Cursor skill (github.com/PhillipChaffee/.cursor), then
  re-verified against current Cursor and Codex docs.

## Cursor-to-Codex Swaps

| Cursor source idea | Codex-native replacement |
| --- | --- |
| `Task` tool with `subagent_type` (backgrounded where the surface supports it) | Explicit Codex subagent delegation: spawn one agent per slice, usually in one manager turn, then wait/synthesize. Current V2 tool names: `spawn_agent`, `send_message`, `followup_task`, `wait_agent`, `interrupt_agent`, `list_agents` (legacy V1 on old resumed threads: `send_input`, `resume_agent`, `close_agent`). The stable user-facing contract is "spawn N agents, wait for all, consolidate." |
| Parallel background Task fan-out (formerly labeled "Multitask Mode") | Codex subagent workflows in the app/CLI. Current docs say Codex waits for all requested subagent results and returns one consolidated response. |
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
| Missing `subagent_type` fallback: custom `.cursor/agents/` files register only after a Cursor restart, so an unregistered role runs as `generalPurpose` with its instructions inlined | Unknown `agent_type` fails the spawn (no silent fallback) and `.codex/agents/` loads in trusted projects only, so an unavailable role runs as `default`/`worker`/`explorer` with its instructions inlined. Either way, a missing role is not permission to skip it. |
| Re-task a failed/partial worker by resuming its agent ID (context preserved) before re-spawning | V2: `send_message` to pass info without triggering a turn, `followup_task` to assign a new turn to the same worker (V1 threads: `send_input` / `resume_agent`); re-spawn fresh only when the context itself is the problem. Same-slice continuation only -- a re-tasked worker keeps its old context. |
| "Verify before you trust" | Codex manager runs pre-fan-out gates, cheap handoff checks, separate verifier waves, and final deliverable validation. |
| Recursive subplanner idea | Dropped from the default. Current docs say `agents.max_depth` defaults to `1`; raise it only for explicit recursive delegation. |
| Entropy-first decomposition (dig locally then attached resources then ask only if it pays; scouting wave then execution wave; least-to-most) | Portable as-is; `update_plan` replaces `TodoWrite` for the living plan. |
| "Route scouting/read waves to Composer 2.5 (fast) via the `model` field" | Route scouting/read waves to `gpt-5.6-terra` at `low` effort (or short-context `gpt-5.6-luna`; `gpt-5.3-codex-spark` / `gpt-5.4-mini` as lighter fallbacks) via custom-agent TOML or the per-spawn `reasoning_effort` field. `model_reasoning_effort` is the config/TOML key. `service_tier` / `/fast` is a user-enabled speed tier, not a forced default. |

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
  levels are `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`
  (model-dependent at both ends; `ultra` is a product setting layered on
  `max`); `gpt-5.6-terra`, `gpt-5.3-codex-spark`, and `gpt-5.4-mini` are
  lighter/faster options for read-heavy subagent work.

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
