# Verification Playbook

Verification is the manager's highest-leverage job in a multi-agent run.
Workers generate candidate findings; the manager decides what is allowed into
the synthesis. A worker's `Status: success` is a claim, not evidence.

The core idea: capability is roughly `base capability x gradeable signal`.
Checking a claim is often much cheaper than producing it, and multi-wave work
compounds errors. One unchecked bad handoff can contaminate every later
decision.

This playbook is strongest on objective, checkable work: counts, code, tests,
facts with sources, citations, generated files, deployments, and metrics. For
taste or judgment, verify the sub-claims and evidence; do not fake a crisp grade
for subjective preference.

## 1. Verify Before You Spawn

Run a pre-fan-out gate after discovery/staging and before delegation:

- Count total rows, messages, files, routes, modules, or records.
- Print each slice's bounds: ID range, date range, path set, or question set.
- Confirm partition sums: all slice counts add back to the total.
- Check gaps and overlaps: no duplicate ranges, missing rows, empty chunks, or
  bad sort order.
- Fix centrally, then re-run the gate.

Example:

```text
total messages: 3097
chunk-1: ids 1-388, 388 msgs, 2026-03-10..2026-03-22
chunk-2: ids 389-776, 388 msgs, 2026-03-22..2026-04-03
...
partition sum: 3097/3097
duplicates: 0
gaps: 0
```

If the gate does not reconcile, do not spawn workers yet.

## 2. Cheap Checks on Every Handoff

Every handoff gets a fast manager-side pass:

- Evidence exists for each key finding.
- File paths, URLs, message IDs, commands, or metrics resolve.
- The cited evidence actually supports the claim.
- Scope matches the assigned slice.
- Headline numbers can be re-counted or queried.
- Findings do not contradict another worker without being marked contested.
- The worker carried confidence tags and unresolved gaps.

Accept only findings that are evidence-backed, scope-correct, and not
contradicted. Demote, re-task, or verify the rest.

## 3. Push Self-Checks Into Worker Prompts

Make every worker do cheap verification before returning:

- Cite-or-drop every important claim.
- Mark per-finding confidence: `high`, `med`, or `low`.
- Report coverage: `read 388/388`, `checked 12/12 files`, or explain skips.
- Use live/current sources for versioned APIs, pricing, schedules, product
  behavior, laws, and docs.
- Flag anything it could not verify.
- For a single important number or recommendation, sample/re-derive more than
  once and report whether it converged.

Avoid vague "double-check yourself" prompts. Self-correction without external
signal can be weak. Give the worker an oracle: a test, query, source URL,
schema, command, count, or separate verifier.

## 4. Use Dedicated Verifier Workers

Verification is a narrower job than generation. Spawn a verifier when a claim is:

- High-stakes or user-actionable.
- Citation-heavy.
- Surprising, contested, or contradictory.
- Low-confidence or single-sourced.
- A number, benchmark, count, or pass/fail claim the synthesis depends on.

Give the verifier:

- Atomic claim(s).
- Cited sources or commands.
- Acceptance question.
- Any required current-doc lookup.

Do not give it the generator's reasoning. That makes it less likely to inherit
the same mistake.

The verifier returns:

- `supported`
- `partly-supported`
- `unsupported`
- `source-not-found`

For many claims, prefer `spawn_agents_on_csv` when available: one row per claim,
fixed JSON result via `report_agent_job_result`. If unavailable, spawn normal
custom `verifier` agents in bounded waves.

## 5. Measure and Cross-Check

Prefer direct oracles over prose review:

- Run tests, type checks, linters, validators, parsers, or smoke scripts.
- Recount from source data rather than trusting a summary.
- Re-run queries or regexes for headline numbers.
- Use at least two independent sources before treating a factual claim as
  verified.
- Split long claims into atomic facts and verify each separately.

For docs/current behavior, use primary sources first. For Codex/OpenAI details,
prefer `developers.openai.com/codex` and current local CLI/tool behavior.

## 6. Verify the Deliverable

Before declaring done:

- Run or validate the thing produced.
- For web/UI, check local routes, status codes, console errors, screenshots, and
  sibling-route regressions.
- For documents/configs/diagrams, run parsers or schema validators when possible.
- Re-read or grep critical files you wrote; do not assume a write landed.
- Confirm deployment or infra state after command success.
- Keep unverified claims labeled in the final output.

## 7. Acceptance and Escalation

Use this ladder:

1. Auto-accept: high-confidence, evidence-backed, source-resolving, corroborated.
2. Verify: medium confidence, single source, important citation, contested.
3. Escalate: low confidence, unresolved, contradictory, high-stakes.

Escalation order:

1. Re-task narrower.
2. Spawn a verifier.
3. Use a higher-reasoning verifier.
4. Ask the user or mark the limitation explicitly.

Never launder low confidence into confident prose. Final claims should be marked
`verified`, `single-sourced`, or `unverified` when the distinction matters.

## Codex-Native Verification Surfaces

- `explorer` or a custom read-only `verifier` agent for local source checks.
- `default` or custom docs researcher for current docs/web/MCP source checks.
- `spawn_agents_on_csv` for verifier-per-row batches when available.
- `codex exec --output-schema` for scripted verification artifacts.
- Tests, validators, shell commands, browser checks, and direct file reads.
- Codex `/review` and GitHub code review for code-risk review.
- `approvals_reviewer = "auto_review"` for approval/security review only. It
  does not verify arbitrary claims.

Current public docs checked on 2026-06-14 do not confirm a general Codex
claim-verification, eval, or critic hook that automatically grades subagent
handoffs. Treat verifier agents and external oracles as the portable path.
