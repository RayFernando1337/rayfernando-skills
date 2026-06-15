# Worked Example and Decomposition Recipes

## Worked Run: Analyze Messages and Build a Roadmap

Goal: read a user's message history, find patterns/goals/frustrations, research
the relevant product stack, and produce a roadmap.

The upgraded reference pattern is multi-wave, not one burst: 16 workers across 3
waves.

- Wave 1: 8 message chunks, 1 workspace reader, 3 research streams.
- Wave 2: 3 focused Convex deep-dives after the user narrowed scope.
- Wave 3: 1 iOS MVP worker after synthesis exposed a concrete product slice.

The serial staging phase was the largest phase: export, clean, chunk, verify
counts and date ranges, fix a timestamp-sort issue, then fan out.

### Step 0 - Discover Serially

- Locate the data store: SQLite, JSONL, exports, or transcript files.
- Read schema and sample messages.
- Count rows and date coverage.
- Inspect nearby workspace memory/config if relevant.
- Verify the pre-fan-out gate: chunk counts sum to the total, each chunk has
  disjoint bounds, no duplicates/gaps, and date ranges make sense.
- Result: about 3,000 messages, chunked into 8 equal message-count ranges, plus
  4 research or workspace streams.

### Step 1 - Decompose

- 8 data-chunk workers: equal message-count ranges, not equal calendar time.
- 1 workspace reader: memory/config/workspace files.
- 3 research workers: realtime voice stack, Notion/platform SDK, iOS/on-device
  options.

### Step 2 - Fan Out with Codex Subagents

Use explicit manager wording:

```text
Spawn 12 Codex subagents in parallel and wait for all of them before synthesis.
Use explorer agents for the 8 read-only message chunks and workspace reader.
Use docs/research-capable agents for the 3 stack research streams. Each worker
must return the research/analysis handoff format from references/handoff-format.md,
including Coverage and Confidence & verification sections.
```

Example data worker prompt:

```text
Overall goal, context only: find patterns, goals, frustrations, and recurring
workflows in a user's chat history with their assistant to inform an app roadmap.

Your slice: messages with id 1001-1500 only in /path/to/messages.sqlite.

Do: read only that disjoint range. Extract recurring topics, stated goals,
repeated pain points, and workflows the user performs often. Quote message id
and date as evidence.

Coverage rule: report messages read as <actual>/<assigned>. If you skip any
message, list why.

Verification rule: cite-or-drop every finding, tag confidence high|med|low, and
separate verified, inferred, single-sourced, and unresolved claims.

Do not: analyze other message ranges, write files, or produce the final roadmap.

Return exactly the research/analysis handoff format.
```

Example research worker prompt:

```text
Overall goal, context only: build a low-latency realtime voice companion app.

Your slice: research realtime voice stack options only, including current OpenAI
Realtime APIs, proxy/SDK options, and latency tradeoffs. Use available docs/web
or MCP tools. Include source URLs and dates where relevant.

Verification rule: use live/current sources, not training data. Cite-or-drop
claims, tag confidence high|med|low, and say what could not be verified.

Do not: compare all roadmap options or write implementation code.

Return exactly the research/analysis handoff format.
```

### Step 3 - Collect, Verify, and Synthesize

- Read all handoffs.
- Check coverage against assigned slices.
- Spot-check citations and source paths.
- Recount headline numbers from the source data.
- Send contested, high-stakes, or citation-heavy claims to a verifier worker.
- Merge recurring themes across message chunks.
- Separate evidence-backed patterns from one-off observations.
- Reconcile stack research conflicts with source quality and date.
- Promote only important gaps into a second wave.
- Write the roadmap yourself from the merged evidence.

## Recipe: Data-Chunk Fan-Out

Use for large corpora: messages, tickets, logs, transcripts, documents, or
analytics rows.

1. Discover total size and schema.
2. Split into disjoint ranges or files.
3. Verify total count, per-slice bounds, gaps/overlaps, and partition sum.
4. Spawn one `explorer` per chunk, or use `spawn_agents_on_csv` when one row maps
   cleanly to one worker.
5. Require coverage and evidence identifiers in every finding.
6. Merge into themes, counts, outliers, and follow-ups.

CSV-shaped prompt:

```text
Create /tmp/messages.csv with columns chunk_id, start_id, end_id, db_path.
Then use spawn_agents_on_csv if available:
- csv_path: /tmp/messages.csv
- id_column: chunk_id
- instruction: "Analyze messages {start_id}-{end_id} in {db_path}. Return JSON
  with status, scope, coverage, key_findings, sources,
  confidence_and_verification, open_questions, and suggested_follow_ups via
  report_agent_job_result."
- output_csv_path: /tmp/message-analysis-results.csv
- max_concurrency: 6
```

Verifier pass:

```text
Create /tmp/claims.csv with columns claim_id, claim, sources, acceptance_question.
Then use spawn_agents_on_csv if available:
- csv_path: /tmp/claims.csv
- id_column: claim_id
- instruction: "Verify claim {claim_id}: {claim}. Check only these sources:
  {sources}. Answer this acceptance question: {acceptance_question}. Return JSON
  with verdict, evidence, source_status, correction, confidence, and gaps via
  report_agent_job_result."
- output_csv_path: /tmp/claim-verification-results.csv
- max_concurrency: 6
```

## Recipe: Multi-Stream Research

Use for comparisons and roadmaps.

1. Define one worker per technology, vendor, API, or approach.
2. Workers research their own option only.
3. Require source URLs, version/date notes, and confidence labels.
4. Split huge topics when one question list would blow context.
5. The manager performs the comparison and recommendation.

Good slices:

- "Research OpenAI Realtime and current SDK/proxy constraints."
- "Research Notion API/SDK fit for this workflow."
- "Research iOS background audio and on-device model constraints."
- "Research Convex auth and limits."
- "Research Convex core idioms."
- "Research Convex components and ecosystem fit."

## Recipe: Whole-Repo Audit

Use for broad audits where one lens would be slow or noisy.

Split by dimension:

- Security and auth.
- Data correctness.
- Performance and concurrency.
- Dead code and dependency risk.
- Test coverage and CI gaps.

Or split by module:

- `apps/web`
- `apps/api`
- `packages/db`
- `packages/ui`

Default to read-only `explorer` or custom reviewer agents. The manager produces
a severity-ordered report with file references and confidence labels.

## Recipe: Parallel Implementation

Use only when ownership is clear.

Safer patterns:

- One `worker` owns frontend components, another owns backend API, another owns
  tests.
- One worktree per competing implementation.
- One `codex exec` process per git worktree for scripted attempts.
- One verifier or reviewer pass checks the merged result before final delivery.

Risky patterns:

- Multiple workers touching the same file family.
- Multiple workers changing shared contracts without a manager-owned design.
- Workers editing before discovery converges.

## Anti-Patterns

- Fan out before discovering the shape of the task.
- Fan out before verifying coverage.
- Give workers vague prompts and hope they infer context.
- Ask workers to "figure out the whole thing" instead of owning one slice.
- Let workers compare across sibling options; the manager owns cross-cutting
  synthesis.
- Trust `Status: success`; it is a claim, not evidence.
- Embed giant verbatim artifacts in a handoff. Write large artifacts to disk and
  cite the path instead.
- Skip re-reading critical files you wrote.
- Treat `agents.max_depth > 1` as a default. Recursive fan-out is expensive and
  can get unpredictable.
- Assume parallel writes automatically merge. Use disjoint ownership or
  worktrees.
- Forward raw handoffs as the final answer.
