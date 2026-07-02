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

### Implement a reviewed plan (plan → edit wave → verify wave)

The end-to-end SWE shape — three waves with different jobs:

1. **Wave A — spec.** A small wave (or the orchestrator alone) turns the goal
   into a written plan: ordered subtasks, explicit file ownership per subtask,
   `Done when:` criteria. Verify it (the artifact-then-bigger-wave shape); the
   verified plan is the contract every edit worker anchors to.
2. **Wave B — disjoint edits.** One `worker` per plan subtask with strictly
   disjoint path sets (or `best-of-n-runner` worktrees for contested designs).
   Each prompt carries the plan excerpt for its subtask, its exact paths, the
   "you are not alone" warning, and the code/edit handoff format.
3. **Wave C — verify.** Read-only workers run the oracles: tests, type checks,
   lint, a reviewer pass over the combined diff, regression checks on sibling
   routes. Route failures back as narrow fix tasks (bounded — don't loop).
   The orchestrator merges, re-reads critical files, and delivers.

Interleave cheaply: Wave C slices that only touch Wave B's finished subtasks
can start while slower edits finish. Keep the plan in `TodoWrite` and the
per-subtask status in the wave manifest.

### Codemod / migration across many files (row-shaped)

When the same mechanical change applies to N files/callsites (rename an API,
swap a client, migrate a schema field):

1. **Stage the target list.** Grep/list the exact targets into
   `.waves/<run>/targets.csv` (path, symbol, line hints). Verify the count —
   the list *is* the coverage gate.
2. **Wave the edits in batches** of 3–8 workers, each owning a disjoint file
   subset from the list; prompts point at the list rows, not pasted code.
3. **Verify by oracle, not prose:** after each batch, re-run the grep (old
   pattern count must fall to the expected residue), then tests/type checks.
   A row-shaped run with a cheap oracle is the one place going wider than
   usual is safe.

### CI-failure triage (→ diagnosis, then one fix wave)

For a red CI run with several failing jobs: one read-only worker per failing
job/log bundle (disjoint), each returning root-cause hypothesis + evidence
(log lines, commit range) + confidence. Prefer the specialized CI subagents
(`ci-investigator`, `ci-watcher`) where available. The orchestrator dedupes
root causes across jobs (one bad commit often explains several failures),
sends contested diagnoses to a verifier, then runs a single fix wave with
disjoint ownership — and re-runs CI as the deliverable check.

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

Framing decomposition as uncertainty reduction is well-supported, and each
source contributes a usable mechanism — not just a citation:

- **Prefer the probe that halves the surviving interpretations.** Uncertainty
  of Thoughts (UoT, arXiv 2402.03271, NeurIPS 2024) scores candidate questions
  by expected information gain and shows the best probe is the one that splits
  the remaining hypotheses ~50/50 (binary-answer entropy peaks at an even
  split). Swapping that entropy reward into a tree search — not the search
  itself — carried most of its +38% average success gain. Orchestrator use:
  aim scouts at the unknown whose answer eliminates the most plans, not the
  one easiest to look up.
- **Ask only when the value of asking clears a threshold.** SAGE-Agent (arXiv
  2511.08798) prices each candidate question by expected value of perfect
  information minus a redundancy cost, asks only when that beats a fraction of
  its confidence in the best current interpretation, and *acts* once that
  confidence passes an execute threshold. Penalizing redundant questions cut
  questions asked ~18–27% with under 3% quality loss — over-asking is
  measurably wasteful. This paper is also the explicit source of the
  specification-vs-model uncertainty split.
- **Judge "is the goal fully specified?" before acting, and err toward
  asking.** arXiv 2606.19559 gates clarification on a specification-uncertainty
  score emitted *before* choosing an action; a conservative ask-threshold
  silently failed (recall collapsed), while a generous one cost little. Two
  honest caveats it adds: every extra self-assessment channel taxed task
  success slightly, and verbalized confidence ran overconfident — treat
  self-reported scores as rankings, not probabilities. ("Resolve environment
  unknowns by gathering via tools" is this skill's operational extension, not
  that paper's mechanism.)
- **Order the plan least-to-most; invest in the decomposition itself.**
  Least-to-Most (arXiv 2205.10625, ICLR 2023) solves subproblems in sequence,
  each answer feeding the next; its gains concentrate on deep problems (5+
  dependent steps — shallow tasks gain nothing), and its own error analysis
  shows the decomposition step, not the solving, is the bottleneck — and that
  decompositions don't transfer across domains. Plan-and-Solve (arXiv
  2305.04091, ACL 2023) shows plan-then-execute cuts missing-step errors but
  leaves misread-goal errors untouched — which is exactly why the
  specification check above comes *before* planning.

These are single-model prompting results. The parallel fan-out, the
verification gates between waves, and "each **verified** result lowers
uncertainty for the next" are this skill's multi-agent adaptation — the
verification half is grounded separately in `verification.md`.
