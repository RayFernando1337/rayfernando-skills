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

### Decomposition of a vague build ("build a Flappy Bird game")

A single high-level request expands into understanding + plan + subtasks:

1. **Locate the entropy.** Specification unknowns (web or native? which
   engine/framework? scope — one screen, score, difficulty curve?) vs
   environment unknowns (what's already in the repo? build tooling? asset
   pipeline?).
2. **Reduce it cheaply.** Dig locally (read the repo, package manifest, existing
   scaffolding). For anything the repo can't answer, spawn a small scouting wave
   (e.g. one worker per candidate engine/framework) on the cheap fast model, and
   verify. State assumptions for the specification gaps ("web canvas, vanilla
   TS, one screen + score") instead of blocking — ask only the one question
   whose answer would change the whole plan.
3. **Decompose least-to-most.** The plan is now low-entropy: game loop → render
   pipes/bird → input + gravity → collision → score/state → polish. First-order
   subtasks first; each verified piece lowers the uncertainty for the next.
4. **Execute in waves.** Build with disjoint-ownership workers (or serially —
   see "Parallel writes"), verify the served artifact, and open another scouting
   sub-wave only where a subtask is still high-entropy.

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

## Wave shapes

A wave isn't one move — pick the shape from how much you know about the problem.

### Decomposition / scouting wave (reduce entropy before the big wave)
When the goal is vague or high-entropy ("build a Flappy Bird game", "make it
faster"), the first wave's job is to *reduce uncertainty*, not to build. Dig
locally, then fan a small scouting wave at the unknowns (stack, constraints,
current APIs, repo shape) on the cheap fast model, verify what came back, and
only then decompose the low-entropy version into the execution wave. The scout
de-risks the build the way the artifact wave does — see "Entropy-first
decomposition" in the SKILL.

### Exploratory wave (you don't know the shape yet)
When the problem space is unmapped (QA, an unfamiliar repo, "what's wrong here?"),
send a **broad** first wave — many workers probing different surfaces/flows at
once. Its job is to *find the edges*, not to finish. Verify what's real, and now
you know the shape.

### Shaping wave (narrow as you learn)
After the broad wave reports, the next wave is more focused: kill the dead ends,
double down on the areas with teeth. Each wave spends the previous wave's findings
instead of re-guessing — the opposite of a loop re-running the same blunt prompt.

### Artifact-then-bigger-wave (let a small wave earn a big one)
Sometimes a wave's deliverable is a *document*. A small wave writes an
architecture doc; you verify it; then a much **bigger** wave builds against it,
many workers anchored to the same verified spec. The small wave de-risks the big
one; the artifact keeps the big wave from poisoning itself.

### Divergent research wave (fan out directions, not just chunks)
For research, send workers in genuinely **different directions** on the same
question, let them return independently, then run verification across them. High
token value with no cross-contamination — separate contexts mean the directions
don't poison each other, and the verify round turns parallel exploration into one
trustworthy synthesis.

Human-in-the-loop is optional by design: read the synthesis and shape the next
wave yourself, or let the verifier gate it automatically. The wave boundary is
the seam a loop doesn't give you.

## Anti-patterns

- **Pointing read-only workers at remote/un-staged data.** `explore` workers are
  local + offline; pull and clean the data locally first (see SKILL Step 0.5).
- **Fan out before discovering.** Produces overlapping or mis-sized slices.
- **Slicing a high-entropy goal before reducing its uncertainty.** Vague goals
  decompose into overlapping, mis-sized slices; dig locally → pull from attached
  resources → ask only if it pays, *then* slice (see "Entropy-first decomposition").
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

## Grounding (why entropy-first works)

Framing decomposition as uncertainty reduction is well-supported. Value a probe
or clarification by its **expected information gain** / expected value of perfect
information, and act once uncertainty is low enough — not before, not forever
(Uncertainty of Thoughts, NeurIPS 2024; EVPI-based clarification, arXiv
2511.08798). Separate **specification** uncertainty (assume, or ask when it
pays) from **environment/model** uncertainty (gather via tools) (arXiv
2606.19559). Then solve the low-entropy plan **least-to-most**, each step feeding
the next (Least-to-Most, arXiv 2205.10625; Plan-and-Solve, arXiv 2305.04091).
