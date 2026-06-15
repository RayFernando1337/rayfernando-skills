---
name: parallel-orchestrate-codex
description: Decompose a large, multi-part goal into independent slices, verify coverage before fan-out, spawn Codex subagents in parallel, collect evidence-backed handoffs, verify important claims, synthesize one deliverable, and launch follow-up waves as needed. Use when the user asks to fan out, parallelize, spin up multiple agents, delegate to subagents, orchestrate workers, analyze large datasets, run multi-stream research, audit a repo, or split disjoint implementation work.
---

# Parallel Orchestrate (Codex subagents)

Use this skill when a task is too broad for one clean linear pass but can be
split into independent slices. You are the manager: discover the problem shape,
stage and verify coverage, decompose it, spawn bounded Codex workers, collect one
structured handoff from each worker, verify important claims, and synthesize the
final deliverable.

Current Codex docs checked on 2026-06-14: Codex subagents are enabled by default
in current releases, built-in roles include `default`, `worker`, and `explorer`,
custom agents live in `~/.codex/agents/` or `.codex/agents/`, and subagent
limits live under `[agents]` in `config.toml`. `spawn_agents_on_csv` is
documented as experimental; use it when it is exposed in the active Codex
surface, and fall back to normal subagent waves when it is not. No current Codex
doc confirms a general-purpose claim-verifier or critic hook; use a verifier
subagent, CSV verification pass, tests, validators, or `codex exec
--output-schema` instead.

Read these references when using the skill:

- `references/handoff-format.md` for the exact worker handoff contract.
- `references/verification.md` for verification gates and verifier-worker
  playbooks.
- `references/examples.md` for decomposition recipes.
- `references/recommended-config.md` for Codex config and custom agent snippets.
- `references/adaptation-notes.md` for Cursor-to-Codex translation notes.

## When to Use

- The user explicitly asks to use multiple agents, subagents, parallel workers,
  fan-out, or orchestration.
- The task splits into independent slices: data ranges, research streams,
  repo modules, audit dimensions, verification rows, or disjoint code ownership.
- The main value is speed, context hygiene, and verification discipline: keep
  noisy exploration out of the manager thread, then check the claims that matter.
- A second or third wave may be useful after first-wave handoffs expose gaps,
  conflicts, narrowed scope, or high-stakes claims needing verification.

## When to Skip

- The task is small, linear, or easy to do locally.
- The slices require constant cross-talk or shared mutable decisions.
- The next action is blocked on one immediate investigation; do that locally.
- Parallel code edits would overlap heavily and no worktree/isolation strategy is
  available.

## Core Principles

1. The manager plans, verifies, and synthesizes. Workers do heavy reading,
   research, tests, audits, bounded edits, or focused claim checks.
2. Worker prompts are self-contained. Do not assume workers can infer the user's
   original request, your scratch reasoning, or sibling work unless you
   intentionally pass or fork that context.
3. One worker owns one slice and returns one handoff.
4. Verify before you trust. A worker's `Status: success` is a claim, not
   evidence.
5. Parallel reads are the default safe case.
6. Parallel writes require disjoint ownership or isolated worktrees. Codex is
   safer than a shared local-only model when workers run in separate sandboxes or
   worktrees, but write conflicts are still a coordination problem.
7. Keep moving until terminal. Handoffs can reveal second-wave tasks; spawn them
   when they materially improve the final deliverable.

## The Loop

Track the run with Codex's plan mechanism (`update_plan`) whenever the workflow
has more than a couple of moving parts.

### Step 0 - Discover Serially

Do not fan out blind. First inspect enough local state to learn the natural
shape of the work:

- List directories or data sources.
- Read schemas, manifests, READMEs, package boundaries, or route maps.
- Sample representative records/files.
- Count rows, files, modules, routes, messages, or scope size.
- Identify likely independent slices and risky overlap.

This manager-side discovery prevents duplicate worker scopes, blind spots, and
mis-sized chunks.

### Step 0.5 - Stage and Verify Coverage

Codex subagents inherit the current sandbox, approvals, MCP, and tool access, so
remote or messy data does not always need to be staged locally first. Still stage
data when it reduces risk or repeated work:

- Export remote/database data once if credentials, rate limits, or query cost
  would make every worker redo the same setup.
- Normalize noisy inputs once: strip wrappers, binary blobs, boilerplate, and
  irrelevant logs.
- Pre-chunk huge corpora into exact per-worker files or ranges.

Then run a pre-fan-out gate:

- Total rows, files, messages, modules, routes, or records.
- One line per slice with ID/range/path/date bounds and item count.
- Partition-sum check: slice counts add back to the total.
- Duplicate/gap check: no overlapping ranges, missing IDs, bad sort, or empty
  chunks.
- Central fix-and-recheck if any anomaly appears.

This serial prep is often the largest phase. The parallel fan-out is fast once
inputs are clean and coverage is proven.

### Step 1 - Decompose into Independent Slices

Choose the split axis that gives each worker clear ownership:

- Data chunks: disjoint ID ranges, date ranges, files, or CSV rows.
- Workstreams: separate technologies, product areas, research questions.
- Repo modules: non-overlapping path sets or package boundaries.
- Audit dimensions: security, performance, correctness, tests, maintainability.
- Verification rows: one claim, citation group, or metric per verifier task.
- Code edits: disjoint file/module ownership, preferably in worktrees for
  heavier changes.

For a large wave, usually 5 or more workers, state the decomposition plan and
the pre-fan-out coverage gate to the user before spawning so they can redirect
cheaply.

Respect `agents.max_threads`. Current Codex docs say it defaults to `6` when
unset. If you need more slices than available threads, batch them into waves.

### Step 2 - Fan Out with Codex Subagents

Spawn all independent workers in the same manager turn when possible. In Codex,
the stable interaction is explicit: "spawn one agent per slice, wait for all of
them, then summarize/synthesize." When the active tool surface exposes direct
subagent tools, use those. If the surface names are visible, they may include
`spawn_agent`, `wait_agent`, `send_input`, and `close_agent`.

Pick the smallest capable role:

| Slice | Codex role | Notes |
| --- | --- | --- |
| Read-heavy code/data exploration | `explorer` | Best for targeted codebase questions and evidence gathering. Use `gpt-5.5` with low reasoning for fast file reads and scans. |
| General research, docs, MCP/web work | `default` or custom docs researcher | Codex workers inherit available MCP/tooling. Use a custom agent when the research shape repeats. |
| Implementation or fixes | `worker` | Give explicit ownership of files/modules and warn that other workers may be active. |
| Review/security/test-risk audit | custom reviewer | Use read-only sandbox and higher reasoning for correctness/security work. |
| Browser/UI investigation | custom browser debugger | Give browser tooling and ask for evidence, not broad edits. |
| Verification of important claims | custom verifier | Give claim + cited sources, not the generator's reasoning. |
| Many row-shaped tasks | `spawn_agents_on_csv` | Experimental; use one CSV row per work item and require `report_agent_job_result`. |

Use `gpt-5.5` for all manager and worker roles. Route cost/speed/capability with
reasoning effort instead of older model families: low for fast reads/scans,
medium for all-around work and research, high for coding and verifying, and
`xhigh` for complex orchestration, deep problem solving, and synthesis before
fan-out.

### Step 3 - Collect and Verify Handoffs

Codex handles spawning, routing follow-ups, waiting, and closing in the manager
workflow. Current docs say when many agents are running, Codex waits until all
requested results are available and returns a consolidated response.

Avoid manual polling loops. Continue non-overlapping local work while workers
run; wait only when synthesis is blocked on their results. For each handoff:

- Check `Status`.
- Check `Coverage` against the assigned slice.
- Extract `Key findings`, evidence, confidence tags, and source paths/URLs.
- Preserve `Sources` and `Confidence & verification`.
- Promote important `Open questions` and `Suggested follow-ups` into a second
  wave if they are needed for the deliverable.
- Reconcile contradictions across workers before presenting claims as settled.

Run cheap checks on every important finding:

- Evidence is present.
- Cited path/URL/range resolves.
- Evidence actually supports the claim.
- Scope matches the assigned slice.
- Headline counts can be re-counted from source.
- Confidence labels are preserved.

Accept only evidence-backed, scope-correct, non-contradicted findings. Demote,
re-task, or verify the rest.

### Step 3.5 - Spawn Verifier Passes When Needed

Verification is the manager's highest-leverage job: checking a claim is usually
cheaper than generating it, and unchecked errors compound across waves.

Use a dedicated verifier when a claim is high-stakes, contested, surprising,
citation-heavy, single-sourced, or low-confidence. Give the verifier:

- The atomic claim.
- The cited source paths/URLs/commands.
- The acceptance question.
- No generator reasoning.

The verifier returns `supported`, `partly-supported`, `unsupported`, or
`source-not-found` per claim. For many claims, prefer `spawn_agents_on_csv` when
available: one claim per row, fixed JSON result via `report_agent_job_result`.
If the CSV tool is unavailable, spawn normal verifier subagents in waves under
`agents.max_threads`.

### Step 4 - Second Waves

Spawn another wave when first-wave handoffs expose:

- Missing coverage.
- Conflicting findings.
- A specialized follow-up that was out of scope.
- A verification task that can run while you synthesize.
- A bounded implementation task after research converged.
- A new user request that narrows or redirects the scope.

Multi-wave is normal. A realistic run may be `12 + 3 + 1` workers across three
waves rather than one giant burst.

Do not recurse by default. Current docs say `agents.max_depth` defaults to `1`,
which allows direct child agents but prevents deeper nesting. If a recursive
subplanner is truly needed, raise `agents.max_depth` deliberately and tightly
scope that behavior.

### Step 5 - Deliver One Synthesized Artifact

Do not forward raw handoffs as the final answer. Produce the user's requested
artifact: report, roadmap, code patch, audit, decision memo, or implementation
plan. Cite worker evidence when it helps, especially file paths, line numbers,
data ranges, URLs, and unresolved uncertainties. Carry confidence into the final
output: `verified`, `single-sourced`, or `unverified`. Never turn a
low-confidence handoff into a confident sentence.

If implementation is required after the research wave, either:

- Make the edits yourself in the manager thread after reading all handoffs.
- Spawn a bounded implementation wave with disjoint file ownership.
- Use Codex app worktrees or `codex exec` in separate git worktrees for heavier
  parallel code attempts.

Verify the deliverable itself:

- Run tests, validators, `curl`, screenshots, parsers, or smoke checks as
  appropriate.
- Regression-check sibling routes/files touched by the work.
- Re-read or grep critical files you wrote before relying on them.
- For generated artifacts, prefer a deterministic validator script or schema.

## Worker Prompt Contract

Every worker prompt includes:

1. Overall goal as context only.
2. The worker's exact slice and ownership.
3. Where to look: paths, data ranges, URLs, MCP/docs sources, commands, or repo
   modules.
4. Coverage rule: read the assigned slice completely when feasible, report
   counts read such as `388/388`, and call out skipped files/ranges.
5. Evidence rule: cite-or-drop every important claim, tag confidence
   (`high|med|low`), and say what would change the conclusion.
6. What not to do: avoid owning the whole task, avoid sibling scopes, avoid
   editing unless explicitly assigned.
7. The required handoff format from `references/handoff-format.md`.

Useful ending:

```text
Return only the structured handoff from references/handoff-format.md. Use
exactly the headings. Include concrete evidence and confidence for every
important claim. Flag anything you could not verify.
```

For research workers, add:

```text
Use live/current sources when the fact may have changed. Do not rely on training
data for versioned APIs, pricing, schedules, product behavior, or current docs.
Flag anything you could not verify.
```

For implementation workers, add:

```text
You are not alone in the codebase. Other workers may be active. Own only the
files/modules listed above, do not revert changes you did not make, and adjust
to nearby changes if you encounter them.
```

For verifier workers, add:

```text
Your job is verification, not generation. Check only the assigned claim(s)
against the provided source(s) or oracle(s). Do not use the original worker's
reasoning. Return supported, partly-supported, unsupported, or source-not-found
with exact evidence.
```

## CSV Fan-Out

Use `spawn_agents_on_csv` when the work is naturally one row per worker: files,
incidents, packages, PRs, migration targets, messages, customer records, or
claims to verify.

Manager responsibilities:

- Create a CSV with a stable `id_column`.
- Put enough per-row context in columns for a self-contained prompt.
- Provide an `instruction` template with `{column_name}` placeholders.
- Provide an `output_schema` when downstream synthesis needs machine-readable
  results.
- Require each worker to call `report_agent_job_result` exactly once.
- Set `output_csv_path`; use `max_concurrency` below or equal to
  `agents.max_threads`.

For a verifier pass, build `claims.csv` with `claim_id`, `claim`, `sources`,
`acceptance_question`, and optional `stakes`. Require JSON fields: `verdict`,
`evidence`, `source_status`, `correction`, `confidence`, and `gaps`.

If the CSV tool is unavailable in the active Codex surface, split the CSV into
normal worker or verifier slices and use the handoff format.

## Parallel Writes in Codex

Codex subagents are a good fit for parallel write work when you use worktrees,
separate sandboxes, or disjoint ownership. Still treat write coordination as a
real merge problem:

- Read/research/test/log analysis: safe default.
- Disjoint edits in one checkout: acceptable when ownership is explicit and
  paths do not overlap.
- Overlapping edits: avoid. Have workers propose handoffs, then implement
  serially.
- Competing implementations: use Codex app Worktree mode, or plain
  `git worktree` plus one `codex exec` run per attempt.
- Always inspect and test the merged result in the manager thread.

## Native Verification Surfaces in Codex

Use these where they fit:

- Tests, validators, type checks, linters, browser checks, and direct source
  recounts are the strongest verification signals.
- Custom `verifier` agents are the Codex-native replacement for a dedicated
  verifier worker.
- `spawn_agents_on_csv` is ideal for a verifier-per-row pass when exposed.
- `codex exec --output-schema` gives machine-readable verification in scripted
  fleets.
- Codex `/review`, GitHub code review, and reviewer custom agents help for code
  risk review.
- `approvals_reviewer = "auto_review"` is an approval/security reviewer only; it
  is not a general claim-verification hook.
- Lifecycle hooks exist in config, but current public docs do not confirm a
  general eval/critic hook for arbitrary worker findings.

## Escalating Beyond One Interactive Thread

Use this skill for interactive, bounded fan-out inside one Codex task.

For scripted or CI-style fleets, use `codex exec` with explicit sandbox and
model settings, often one process per git worktree. `codex exec --json` and
`--output-schema` are useful when another script needs stable events or
machine-readable results.

For always-on, team-scale orchestration, use the Symphony pattern: an issue
tracker or queue as the control plane, one agent workspace per item, bounded
concurrency, retries, observability, and human review. Treat Symphony as a
reference/spec pattern, not a drop-in replacement for this interactive skill.

## Checklist

- [ ] Used `update_plan` for multi-wave work.
- [ ] Discovered the shape of the problem before decomposing.
- [ ] Staged or normalized inputs when it materially helps.
- [ ] Verified coverage before spawning: counts, bounds, partition-sum,
      gaps/duplicates.
- [ ] Slices are independent and sized to `agents.max_threads`.
- [ ] Each worker prompt is self-contained and ends with the handoff contract.
- [ ] Picked `explorer`, `worker`, `default`, custom agents, verifier agents, or
      `spawn_agents_on_csv` deliberately.
- [ ] Avoided manual polling loops; waited only when synthesis was blocked.
- [ ] Read every handoff and resolved conflicts.
- [ ] Preserved per-finding confidence labels.
- [ ] Spawned second-wave tasks only for real gaps, conflicts, narrowed scope, or
      verification needs.
- [ ] Verified high-stakes, conflicting, low-confidence, or uncited findings
      before synthesizing.
- [ ] Verified the final deliverable: re-ran/validated and re-read critical
      writes.
- [ ] Produced one synthesized deliverable.
- [ ] For edits, verified disjoint ownership or used worktrees.
