# Worker handoff format

A worker's **final message is its handoff** — the only thing the orchestrator
reads back. Put everything important in it; intermediate output is invisible to
the parent. End every worker prompt by pasting one of these templates and saying
"Use exactly this structure."

## Research / analysis worker

The common case (data analysis, web/MCP research, code reading, audits).

```markdown
## Status
success | partial | blocked

## Scope
<the exact slice this worker owned: data range / area / paths>

## Coverage
- Read: <what you actually read of your scope, with counts, e.g. 388/388 lines or rows>
- Skipped: <anything in scope you did not read, and why — or "none">

## Key findings
- [high|med|low] <finding> — evidence: <file:line | msg id+date | URL | metric> — sources agreeing: <N>
- <finding …>

## Sources
- <paths read, data ranges covered, URLs/docs fetched — so the parent can trace claims>

## Confidence & verification
- Verified (re-ran / cross-checked ≥2 sources / recounted): <which findings + how>
- Inferred (not independently checked): <which findings>
- Single-sourced / unresolved: <claims on one source, or that I could not confirm>
- Citations: <each URL/path cited → resolves? does it actually support the claim?>
- Would change my conclusion: <missing evidence / what would falsify>

## Open questions / gaps
- <anything ambiguous, missing, or out of scope that the parent should resolve>

## Suggested follow-ups
- <concrete next tasks the orchestrator should consider spawning>
```

## Code / edit worker

When a worker edits files (use only with disjoint paths, or via
`best-of-n-runner` worktrees).

```markdown
## Status
success | partial | blocked

## Changed
- <path>: <what changed and why>

## Verification
<one of: live-verified | test-verified | type-check-only | not-verified>
- <command run → outcome / test pass-fail counts>

## Notes & deviations
- <assumptions, surprises, broken invariants, anything the parent must know>

## Confidence & risk
- Risk: <low | med | high> — <blast radius / what could break / what you did NOT test>

## Suggested follow-ups
- <tasks the orchestrator should consider>
```

## Verifier worker

For a worker whose only job is to check another handoff's claims. Give it the
claims + their cited sources, but **not** the original worker's reasoning (so it
can't inherit the same mistake).

```markdown
## Status
success | partial | blocked

## Verdict per claim
- <claim> → supported | partly-supported | unsupported | source-not-found
  - evidence: <quote / file:line / metric that settles it>
  - source checked: <URL/path> (resolved: yes/no)

## Overall
accept | revise | reject — <one line why>

## Corrections
- <for partly/unsupported claims: the corrected statement, or "drop">
```

## How the orchestrator reads a handoff

1. **Status** ≠ `success` → decide: retry, repair scope, or spawn a clarifying task.
2. **Coverage** → check scope vs read vs skipped **first**, before trusting any
   findings. If the worker didn't read its whole slice, the gap is a silent blind
   spot — re-task it rather than synthesizing on partial reads.
3. **Key findings** → each must carry inline evidence + a confidence tag. A claim
   with no traceable source is unverified — demote, re-task, or send to a
   verifier. Skim for claims that contradict expectations or another worker.
4. **Sources / Confidence & verification** → keep; accept `verified` /
   corroborated findings outright. Route `low` / `single-sourced` /
   unresolved-citation findings to a verifier worker or escalate; carry the
   surviving confidence label into the final deliverable.
5. **Open questions / Suggested follow-ups** → the richest section; each bullet is
   a candidate second-wave task. Accept, reject, or consolidate.

## Why a fixed shape

Uniform handoffs are what let many isolated workers converge without talking to
each other — the parent diffs and merges them mechanically. A sloppy, freeform
return forces the orchestrator to re-derive structure from prose and pollutes the
synthesis. The format is a shared commons; keep it tight.
