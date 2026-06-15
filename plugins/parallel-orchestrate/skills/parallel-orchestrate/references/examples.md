# Worked example + decomposition recipes

## Worked run: "analyze all my messages and build a roadmap"

The motivating run (a health-coach app: read every message to an agent, find
patterns/goals/frustrations, research the stack, and produce a roadmap). It has
been run end to end. The reference run (model "Fable") fanned out **16 workers
across 3 waves** — wave 1: 8 message chunks + 1 workspace reader + 3 research
(voice, Notion, iOS); wave 2: 3 Convex deep-dives (split when the user narrowed
scope); wave 3: 1 iOS-MVP worker — with heavy serial staging up front (export →
clean → chunk → **verify counts/date-ranges**, which caught a timestamp-sort bug)
and synthesis between waves. Takeaway: plan for **multiple waves**, not one burst,
and verify coverage before each fan-out.

### Step 0 — Discover (serial, main session)

- List the data dir; find the message store (e.g. the SQLite db / export files).
- Read the schema; sample a few messages; count rows and date coverage.
- Result: "~3,000 messages; chunk into 8 disjoint ranges. Plus 4 research
  workstreams + 1 workspace-data reader."

### Step 1 — Decompose

- 8 × **data-chunk** workers: messages split into 8 disjoint ranges.
- 1 × **workspace reader**: read the agent's memory/config/workspace files.
- 3 × **research** workers: realtime voice stack; Notion SDK platform; iOS SDK + on-device models.

### Step 2 — Fan out (one message, many `Task` calls)

Read-only data chunks → `explore`. Web/MCP research → `generalPurpose`. All with
`run_in_background: true`. Illustrative shape of one analysis worker:

```text
Task(
  description = "Analyze messages chunk 3",
  subagent_type = "explore",        // read-only; "very thorough"
  run_in_background = true,
  prompt = """
  Overall goal (context only): find patterns, goals, frustrations, and recurring
  workflows in a user's chat history with their assistant, to inform an app roadmap.

  Your slice: messages with id 1001–1500 only, in <path-to-store>.

  Do: read that disjoint range. Extract recurring topics, stated goals, repeated
  pain points, and any workflow the user performs often. Quote message id + date
  as evidence.

  Return EXACTLY the research/analysis handoff format (Status, Scope, Key findings,
  Sources, Open questions, Suggested follow-ups).
  """
)
```

…and one research worker:

```text
Task(
  description = "Research realtime voice stack",
  subagent_type = "generalPurpose", // needs web + Exa/Ref MCP — do NOT set readonly
  run_in_background = true,
  prompt = """
  Overall goal (context only): build a low-latency realtime-voice health assistant.

  Your slice: research the realtime voice stack ONLY (e.g. OpenAI Realtime API,
  proxy/SDK options, latency tradeoffs). Use web search + the Exa/Ref MCP tools.

  Return EXACTLY the research/analysis handoff format. Include source URLs.
  """
)
```

Send all ~12 in **one** message, then **end the turn** and wait for completion
notifications (no polling).

### Step 3-5 — Collect, second wave, deliver

- Read all 12 handoffs; merge findings; note conflicts and open questions.
- Spawn a small second wave for gaps surfaced in `Suggested follow-ups`.
- Synthesize the roadmap yourself from the merged handoffs.

## Reusable recipes

### Data-chunk fan-out (large corpus → patterns)

Discover size → split into N disjoint ranges → N `explore` workers, each owning
one range → merge findings. Use when one agent can't hold or read it all in time.

### Multi-stack research (→ comparison / roadmap)

One `generalPurpose` worker per technology/option, each returning findings +
source URLs → orchestrator builds the comparison/roadmap. Workers never compare
across options; the orchestrator does the cross-cutting synthesis.

### Whole-repo audit (→ report)

One worker per dimension (security, performance, dead code, test coverage) or per
top-level module, all `explore` (read-only) → merge into a severity-ordered
report. Pairs well with specialized review subagents when available.

### Parallel implementation (→ code)

Only with **disjoint** file sets per worker, or `best-of-n-runner` (one git
worktree each). Otherwise do research in parallel and edits serially.

### Multi-model panel (the Fusion pattern)

When a slice is **high-stakes** — a design call, a risky correctness/security
question, a key research synthesis — fan the **same** prompt to N different
models in one parallel wave (ask the user which models; don't guess slugs),
then synthesize one answer rather than trusting any single output:

- **Label CONSENSUS** (2+ models agree) vs **lone-model** findings.
- **Resolve contradictions** instead of averaging them.
- **Dedupe overlap** and carry each claim's confidence forward.

The synthesis carries most of the gain (per OpenRouter's Fusion research, ~3/4
from the synthesis step, not the diversity), and cost/latency scale with panel
size — so reserve it for high-stakes slices. The adversarial multi-model code
review (reviewer panel → one synthesized verdict) is the same recipe — see the
SKILL "Multi-model fan-out" section for the Cursor mechanics.

## Anti-patterns

- **Pointing read-only workers at remote/un-staged data.** `explore` workers are
  local + offline; pull and clean the data locally first (see SKILL Step 0.5).
- **Fan out before discovering.** Produces overlapping or mis-sized slices.
- **Fan out before verifying coverage.** Check counts/bounds/partition-sum first;
  a missing chunk is a silent blind spot.
- **Thin worker prompts.** Workers can't see chat history; vague scope = drift.
- **Polling for results.** Background workers notify on completion — end the turn.
- **Trusting `Status: success`.** It's a claim, not evidence; verify each handoff
  (see `verification.md`).
- **Skipping a re-read of your own writes.** Don't assume a `Write` landed; re-read
  or `grep` critical files before depending on them.
- **Parallel writes to shared paths.** Corruption. Partition or use worktrees.
- **Forwarding raw handoffs as the answer.** The orchestrator must synthesize.
