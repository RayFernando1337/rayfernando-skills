---
name: parallel-orchestrate
description: Decompose a large, multi-part goal into independent slices and run them as parallel Cursor subagents via the Task tool (Multitask Mode), then merge their structured handoffs into one deliverable. Use for big research, analysis, audit, or codebase/data-exploration jobs where a single linear pass would be slow — e.g. "analyze all my messages and find patterns", "research stacks A, B, and C and build a roadmap", "audit this whole repo". The orchestrator plans and synthesizes; isolated workers do the parallel heavy lifting. Read also when the user asks to fan out, parallelize, spin up multiple agents, or orchestrate subagents.
---

# Parallel Orchestrate (local subagents)

Run an orchestrator-worker pattern inside one local Cursor session. You are the
**orchestrator**: you discover, decompose the goal into independent slices, fan
them out to parallel **workers** (the `Task` tool, run in the background =
"Multitask Mode"), read each worker's structured **handoff**, and synthesize one
deliverable. Workers are isolated and return exactly one handoff.

This is the local, zero-setup adaptation of the Cursor team's `orchestrate`
plugin (which spawns *cloud* agents over the Cursor SDK). Same principles —
planners plan, workers hand off up, no cross-talk — without API keys, `bun`, git
branches, or Slack. For heavyweight cloud fan-out, see "Escalating" below.

## When to use

- A large goal that splits into **independent** slices (research areas, data
  chunks, files/modules, audit dimensions).
- The work is mostly **read / research / analysis** — the safest thing to
  parallelize locally (see "Parallel writes" for why).
- A single linear pass would be slow and you want real speedup from concurrency.

## When to skip

- Small or linear tasks (just do them — fan-out overhead isn't worth it).
- Work needing tight back-and-forth or shared mutable state between steps.
- Parallel **edits to the same files** — local workers share one filesystem.

## Core principles

Adapted from `orchestrate`. These keep the run converging without coordination.

1. **Orchestrator plans and synthesizes; it does not do the heavy lifting.**
   Discovering, decomposing, reading handoffs, and writing the final deliverable
   are your job. The bulk reading/research/analysis is delegated to workers.
2. **Workers are isolated.** A subagent has **no access to the user's message,
   your prior steps, or sibling workers.** Every worker prompt must be fully
   self-contained: goal context, its exact slice, where to look, what to return.
3. **One worker, one slice, one handoff.** The worker's final message is the
   only thing you read back. Define its exact shape (see `references/handoff-format.md`).
4. **Parallelism is for reading, not writing.** Local workers share the
   workspace; concurrent writes to overlapping paths corrupt each other.
5. **Continuous motion.** A handoff can reveal new work. Spawn a second wave
   (driven by a handoff gap *or* a new user request). Stop only when every slice
   is terminal and the synthesis is complete.
6. **Verify before you trust.** A worker's `Status: success` is a claim, not
   evidence. Check each handoff against something re-openable before folding it
   into the synthesis. See "Verification" below and `references/verification.md`.

## The loop

Track it with `TodoWrite` (or the host's planning tool, e.g. `TaskCreate`) so the
waves stay visible.

### Step 0 — Discover first (serial, in the main session)

Do **not** fan out blind. Spend a few cheap tool calls in the main session to
learn the shape of the problem: list the directory, read the schema, sample the
data, confirm coverage/size. This is what tells you the *natural* decomposition
(how many chunks, which workstreams). Skipping discovery produces overlapping or
mis-sized slices.

### Step 0.5 — Stage the data (when it's remote or messy)

`explore` workers run **locally and offline** (no SSH, no network, no MCP). If
the source is on a remote host, in a database, or wrapped in noise, the
orchestrator must stage clean inputs **before** fanning out:

- **Pull remote → local.** SSH/`rsync`/export the relevant data to a local
  scratch dir so read-only workers can read it (e.g. query a remote SQLite
  read-only, export the rows, `rsync` the markdown).
- **Clean + normalize once, centrally.** Strip wrappers, boilerplate, and binary
  blobs (base64, logs); fix timestamps. Doing this once beats making every worker
  re-derive it (and keeps noise out of their context).
- **Pre-chunk for the workers.** Split into the exact per-worker files/ranges so
  each prompt can point at one path.
- **Verify before you spawn.** Print counts and per-slice bounds; confirm the
  partition sums to the total (e.g. 8 chunks × ~388 = 3,097) so no slice is a
  silent blind spot. Fix anomalies (bad sort, dups) centrally, then re-check.
  (Details: `references/verification.md` §1.)

In practice this serial prep is often the *largest* phase; the parallel fan-out is
fast once inputs are clean.

### Step 1 — Decompose into independent slices

Split along whichever axis makes slices independent:

- **Data chunks** — partition large data and give each worker a disjoint range
  (e.g. messages 1–500, 501–1000, …).
- **Workstreams** — separate research/analysis areas (e.g. "research voice
  stack", "research the Notion SDK", "audit auth code").
- **Files / modules** — disjoint, non-overlapping path sets.

Each slice needs: a one-line scope, what to look at, and a defined output. For a
big wave (roughly 5+ workers), state the decomposition plan to the user before
spawning so they can redirect cheaply.

### Step 2 — Fan out in parallel

Send **one message with multiple `Task` tool calls** — that is what makes them
run concurrently. Set `run_in_background: true` on each (Multitask Mode). Pick
`subagent_type` per slice (table below). Give each a 3-5 word `description` and a
self-contained `prompt` ending with the required handoff format.

Then **end your turn.** You are notified as each background worker completes —
do **not** `AwaitShell`, poll, or read output files in a loop. (One quick
status read right after spawning, to confirm they started, is fine.)

### Step 3 — Collect and synthesize

As handoffs arrive, read each one: note `Status`, extract `Key findings`, and
mine `Open questions` / `Suggested follow-ups` — each bullet may become a
second-wave task. Reconcile conflicts across workers.

**Don't trust a handoff because it says `success`.** Verify each finding's
evidence (cited file:line / URL / metric resolves and says what's claimed),
recount headline numbers from the source, and route low-confidence, conflicting,
or citation-heavy claims to a verifier before they enter the draft. See
"Verification" below.

### Step 4 — Second waves (continuous motion)

If handoffs exposed gaps, dependencies, or follow-ups, spawn another parallel
wave the same way. Repeat until no slice is `pending` and nothing new surfaced.

### Step 5 — Deliver

Synthesize all handoffs into the single artifact the user asked for (roadmap,
report, summary, plan). Cite which worker produced which finding when it helps,
and carry each claim's confidence through (`verified / single-sourced /
unverified`) — never launder a `low` into a confident sentence.

Then write any code/files yourself, or spawn a dedicated implementation wave
(mind "Parallel writes"). **Verify the deliverable**, not just the handoffs:
re-run/`curl`/validate served artifacts, regression-check sibling routes, and
re-read the critical files you wrote (see `references/verification.md` §6).

## Verification

The orchestrator's highest-leverage job. You can't make a worker smarter at
inference time, but verifying a handoff is far cheaper than producing it, and in a
multi-wave run one unchecked bad handoff compounds into the synthesis.

- **Gate before spawn** — counts, coverage, partition-sums (Step 0.5).
- **Cheap checks every handoff** — evidence present + resolves, scope match,
  contradiction skim, citations actually support the claim.
- **Self-checks in the prompt** — cite-or-drop, confidence tags, "read
  COMPLETELY", live sources, flag-unverified. (Don't rely on freeform
  "double-check yourself"; give an oracle or a separate verifier.)
- **Dedicated verifier worker** for high-stakes / contested / citation-heavy
  claims — give it the claim + sources but **not** the generator's reasoning.
- **Measure & cross-check** — re-run the oracle, recount from source, require ≥2
  independent sources.
- **Escalate** low-confidence / conflicting findings (re-task → verifier →
  stronger model → ask the user) instead of folding them in.

Strongest on objective, checkable work (counts, code, facts-with-sources); on
taste/judgment, verify the sub-claims, don't fake a grade. Full playbook:
`references/verification.md`.

## Choosing `subagent_type`

| Slice is… | Use | Notes |
|---|---|---|
| Read-only code/data exploration | `explore` | Fast, **read-only**, **no MCP/internet**. Pass thoroughness: "quick" / "medium" / "very thorough". |
| Research needing web / MCP (Exa, Ref, docs) | `generalPurpose` | Multi-step; has internet + MCP. Do **not** set `readonly: true` (that disables MCP/internet). |
| Multi-step work mixing read + light reasoning | `generalPurpose` | The general workhorse. |
| Shell/git heavy investigation | `shell` | Command execution specialist. |
| Browser testing / UI verification | `browser-use` | Stateful; navigates and screenshots. |
| Competing/parallel **code** attempts | `best-of-n-runner` | Each runs in an **isolated git worktree** — safe for parallel writes. |

Only pass `model` when the user explicitly requests a specific model.

## Worker prompt = the contract

A worker cannot ask follow-up questions. Under-specified prompts drift silently.
Write each as if you get one shot. Every worker prompt includes:

1. **Overall goal** (context only — "don't try to own the whole goal").
2. **This worker's exact slice** (the disjoint range / area / paths).
3. **Where to look** (dirs, files, data ranges, which MCP/tools to use).
4. **What to return** — the structured handoff from `references/handoff-format.md`.
5. **Self-verify rules** — cite-or-drop every claim, tag confidence
   (`high|med|low`), and state what you could **not** verify. Analysis workers:
   "read COMPLETELY (N lines) and report the count." Research workers: "use live
   sources, not training data."
6. **Scope boundaries** — what's explicitly OUT of scope (so it doesn't overlap a
   sibling worker).

See `references/handoff-format.md` for the copy-paste worker handoff template and
`references/examples.md` for a full worked run (the health-coach research job in
the screenshots) plus reusable decomposition recipes.

## Parallel writes (the local gotcha)

Cloud `orchestrate` gives every worker its own repo clone, so parallel edits are
safe there. **Local subagents share one working directory.** Concurrent writes
to overlapping files clobber each other.

- Parallel **reads/research/analysis**: always safe. This is the default use.
- Parallel **edits**: only when path sets are strictly disjoint, **or** use
  `best-of-n-runner` (git worktrees), **or** do edits serially after the
  research waves finish.

## Escalating to cloud orchestration

For genuinely large builds (many concurrent code-writing agents, runs that
outlive this session, PRs per task), use the Cursor team's `orchestrate` plugin
instead. It spawns cloud agents via the Cursor SDK, isolates each on its own
branch, and reconciles handoffs from disk/git. It needs `CURSOR_API_KEY` + `bun`
(and optionally Slack). Invoke it explicitly with `/orchestrate <goal>`.

## Checklist

- [ ] Discovered the problem shape before decomposing.
- [ ] Slices are independent (disjoint data/areas/paths).
- [ ] Each worker prompt is fully self-contained (no reliance on chat history).
- [ ] All `Task` calls sent in one message, `run_in_background: true`.
- [ ] Ended turn to await completions — no polling loop.
- [ ] No two parallel workers write the same paths.
- [ ] Verified coverage before spawning (counts/bounds/partition-sum).
- [ ] Read every handoff; spawned follow-ups for open questions.
- [ ] Verified each handoff's evidence (not just its `Status`); escalated
      low-confidence / conflicting / uncited findings before synthesizing.
- [ ] Verified the final deliverable (re-ran/validated; re-read critical writes).
- [ ] Synthesized one deliverable from the handoffs.
