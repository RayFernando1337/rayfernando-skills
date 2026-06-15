# Verification (the orchestrator's highest-leverage job)

You can't make a worker smarter at inference time, but you can decide **how much
verification to buy** per handoff. Two facts make this decisive:

- **Verification is cheaper than generation** (verification asymmetry). You can
  re-check a claim for far less than it cost to produce, so checking pays off.
- **Per-step errors compound.** A multi-wave run is a long-horizon task; each
  handoff is a step. One unchecked bad handoff poisons the synthesis. The
  verification discipline, not the raw worker output, is the moat.

A worker's `Status: success` is a **claim, not evidence.** A confident,
well-written finding can still be a hallucination ("reads-correct" ≠
"is-correct"). Verify against something checkable.

This is strongest where work is **objective and checkable** (counts, code,
facts-with-sources) and weakest on taste/judgment. On subjective slices, verify
the *sub-claims*; don't fake a crisp grade on an inherently subjective output.

## 1. Verify before you spawn (the pre-fan-out gate)

Catch decomposition bugs while they're cheap (one of Fable's strongest habits):

- **Counts + coverage.** Print line/row counts; confirm the partition sums to the
  total (e.g. 8 chunks × ~388 = 3,097). A missing chunk = a silent blind spot.
- **Per-slice bounds.** Print each chunk's range (e.g. `chunk-1: 388 msgs,
  2026-03-10 → 2026-03-22`). Anomalies (bad sort, dup ranges) surface here.
- **Fix centrally, then re-verify.** If you find a problem (timestamp sort bug,
  duplicates), fix it once in staging and re-check before fanning out.

## 2. Cheap checks on every handoff (always)

- **Evidence present.** Each finding cites something re-openable: file:line, msg
  id/date, URL, metric. No traceable source → demote or re-task it.
- **Scope match.** The worker covered exactly its slice. Gaps → re-task; overlap
  → dedupe.
- **Contradiction skim.** Flag claims that conflict with your prior or another
  worker; route those to a verifier, don't fold them into the draft.
- **Citations resolve.** Spot-check that cited URLs/paths exist and actually say
  what's claimed. Deep-research workers hallucinate ~3–13% of citation URLs.

## 3. Push self-checks into the worker prompt (scalable)

Bake into the handoff contract so the worker verifies before returning:

- **Cite-or-drop.** Every claim carries inline evidence, or it's omitted.
- **Confidence per finding** (`high|med|low` + why) — separate *verified* from
  *inferred*.
- **Read COMPLETELY.** Analysis workers report how many lines they read
  (`388/388`) and may add `targeted greps to verify coverage`.
- **Live sources only** (research workers): use current docs/web, not training
  data; `flag anything you could NOT verify`.
- **Factored self-verification (CoVe).** For top claims: draft → list check
  questions → answer them *without looking at the draft* → revise.
- **Self-consistency.** If the slice yields one number/pick, sample 3–5× and
  report the majority + agreement; flag if it didn't converge.

Caveat: **intrinsic self-correction often degrades reasoning.** "Double-check
yourself" with no external signal is weak; give the worker an oracle (a test, a
re-derivation, a fresh source) or a separate verifier.

## 4. Spawn a dedicated VERIFIER worker when it matters

Verifying is a different, easier job than generating — isolate it. Spawn a
verifier (`generalPurpose` for web/MCP, `explore` for local) when a finding is
**high-stakes** (drives the deliverable / a go-no-go / a number the user acts on),
**surprising / contested / conflicting**, or the handoff is **citation-heavy**.

Give the verifier the **claim + its cited sources but NOT the generator's
reasoning** (so it can't inherit the same mistake). It returns, per claim:
`supported | partly | unsupported | source-not-found` + the quote/file:line that
settles it. (This is the CitationAgent pattern: re-attribute every claim to a
source after the fact.) See the Verifier worker template in `handoff-format.md`.

Budget: don't verify everything equally. Inline self-checks are free; reserve
dedicated verifier workers for the ~20% of findings the deliverable hinges on.

## 5. Measure & cross-check (the strongest signals)

- **Re-run the oracle, don't re-read the prose.** If a claim is checkable by
  execution — tests pass, a count, a query/regex result, a metric — have a worker
  *run it* and report `command → output`.
- **Recount from source.** For "N items / all X do Y", recompute N from the
  staged data, not from the summary.
- **≥2 independent sources** to mark a claim `supported`; one source =
  `single-sourced` (flag). For citations, ≥3 independent agreement ≈ 95% reliable.
- **Decompose then verify (SAFE).** Split a long-form claim into atomic facts;
  check each against a fresh source rather than judging the paragraph whole.
- **Panel cross-check.** Running the same high-stakes/contested claim across
  several models and synthesizing the results (consensus vs lone-model) is a
  strong cross-check — see SKILL "Multi-model fan-out".

## 6. Verify the deliverable, not just the handoffs

Before declaring done (Fable's habit on served artifacts):

- **Run/serve it.** For anything deployed: `curl` local **and** production/tailnet;
  check status, size, title. **Regression-check sibling routes** you might have
  touched.
- **Validator scripts.** For generated artifacts (diagrams, configs), add a
  validator (e.g. headless mermaid parse → `20/20 ok`) and run it in the build.
- **Verify intent on infra.** After a first push fails, confirm the result
  (`gh repo view --json visibility` → PRIVATE), not just that the command exited 0.
- **Re-read critical writes.** Don't assume a `Write` landed correctly; re-read or
  `grep` the files the deliverable depends on (Fable hit `Edit`-before-`Read`
  failures from skipping this).

## 7. Acceptance, conflicts, escalation

- **Accept** only if: evidence present + source resolves + scope-correct + not
  contradicted. Otherwise it isn't "done."
- **Encode acceptance bars.** Write `Done when:` criteria into specs/issues at
  synthesis time; file `open-question` items for claims workers flagged unverified.
- **Conflicts → don't average.** Tie-break with a verifier (both claims + both
  sources) or a one-round debate; facts both sides drop are usually the false ones.
- **Three tiers:** auto-accept (high-confidence + corroborated) → verify (medium)
  → escalate (low / single-sourced / unresolved): re-task narrower → dedicated
  verifier → ask the user (who may choose a stronger model).
- **Carry confidence into the synthesis.** Mark surviving claims `verified /
  single-sourced / unverified`; never launder a `low` into a confident sentence.
  Prefer "couldn't confirm X" over a confident guess.

## Sources

- Jason Wei, *Asymmetry of verification & verifier's law* — https://www.jasonwei.net/blog/asymmetry-of-verification-and-verifiers-law
- Anthropic, *Building a multi-agent research system* (rubric judge + CitationAgent) — https://www.anthropic.com/engineering/multi-agent-research-system
- Chain-of-Verification (CoVe), arXiv 2309.11495 — https://arxiv.org/pdf/2309.11495
- Self-Consistency, arXiv 2203.11171 — https://arxiv.org/pdf/2203.11171
- SAFE (decompose → search → rate facts), arXiv 2403.18802 — https://arxiv.org/abs/2403.18802
- Self-correction needs external feedback, arXiv 2310.01798 — https://arxiv.org/abs/2310.01798
