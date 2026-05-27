---
name: running-bug-review-board
description: >-
  Runs a real-user manual QA pass against any web/mobile/desktop app and turns
  the results into a Bug Review Board (BRB) feedback loop. Use whenever the
  user says "QA this", "test phase N", "run a manual test plan", "act as a real
  user", "find UX bugs", "sign off this build", "file a bug report", or
  "is this ready to ship?" — even if they only describe the symptoms ("the
  signup flow feels broken", "check what's wrong before we move on", "we
  finished feature X"). Drives the trifecta: PM (verifies user-promise),
  QA (executes scenarios from a real user's perspective), and Engineer
  (flags invalidated assumptions). Repo-agnostic, browser-tool-agnostic,
  scaffolds folders for bug reports + run reports + coordinator merges with
  P0/P1/P2 priorities. Works alongside cursor-ide-browser, browser-use,
  Playwright, manual driving, or any future browser tool.
---

# Running the Bug Review Board (BRB) QA pass

This skill runs a **real-user QA pass** on an app and feeds the output into a
Bug Review Board: a folder of structured bug reports, per-pass run reports,
and a final YES/NO sign-off the team can act on. It generalizes a
battle-tested workflow that already shipped phase QA on Mokuhoe — the
techniques are repo-agnostic.

## Why this exists

Most engineers test their own code. They confirm what they wrote works. That
misses the bugs **real users hit first** — stale state across flows, mobile
overflow, copy that lies, paths that 404 mid-onboarding, race conditions
between auth and routing.

This skill simulates a real user. The QA agent acts like a careful, mildly
unforgiving customer who does not read the source code.

## The trifecta — three hats, one pass

For every pass, wear all three hats:

- **Product Manager.** Confirm the build delivers the user-visible promise
  documented in the product spec or phase doc. If it does not, that is a
  product gap, not a bug — flag it in the run report.
- **QA.** Execute every scenario from a real user's perspective on the
  primary supported viewport(s). Capture evidence (snapshot, console, server
  data when relevant). Pass / Fail / Blocked.
- **Engineer.** Watch for invalidated assumptions: phase doc says "X uses
  function Y" but Y was renamed; new client orchestration appeared in a flow
  the docs say is server-driven; fields exist in UI that aren't in the
  spec. **Finding gaps is the point** — don't reverse-engineer the docs to
  match buggy behavior.

Do **not** fix product code unless the user explicitly asks. Test, document,
file bugs, hand off.

## Discover the app first (or you'll write bad tests)

Before writing a single test, understand the **intent** of the app — what
the customer is hired to do with it. See
[references/discovering-the-app.md](references/discovering-the-app.md) for
the full investigation playbook. The short version:

1. Read the product spec / README / landing page / pitch deck (in that
   priority order) for what the app **promises**.
2. Read the phase doc (or current sprint plan) for what was **just built**.
3. Read prior QA gates / checklists for what passed before — regressions
   are your highest-value finds.
4. Read the bug-reports index — open bugs are scenarios you must re-test
   first.
5. List the public routes / surfaces / entry points and decide which a
   real new user would touch.

If the user says "QA this app" but no docs exist, **ask** — see
[references/discovering-the-app.md § Asking the user](references/discovering-the-app.md).
Common questions: "Where's the test account playbook?", "Which viewport(s)
are primary?", "Where's the sign-up entry point?".

## Workflow (any phase, any repo)

```
1. Scope        → which surface / phase / build
2. Discover     → product intent + recent change + open bugs
3. Plan         → manual test plan (scenarios, IDs, expected, gates)
4. Prepare      → env, build, test accounts, viewport
5. Mode         → parallel coordinator OR sequential wrap-up
6. Execute      → real-user scenarios with evidence
7. File bugs    → P0/P1/P2 with reproduction steps
8. Merge        → results + verdict (YES/NO + open P0/P1)
9. Hand off     → next QA agent (if NO) or engineering (if blockers)
```

Detail in [references/workflow.md](references/workflow.md).

## Mode picker

| Situation | Mode | Reference |
|-----------|------|-----------|
| Fresh full pass on a phase, multi-agent OK | Parallel coordinator | [references/parallel-coordinator.md](references/parallel-coordinator.md) |
| Prior parallel run stalled or partial | Sequential wrap-up | [references/sequential-wrapup.md](references/sequential-wrapup.md) |
| Solo agent, small surface | Sequential, ordered top-to-bottom | [references/sequential-wrapup.md](references/sequential-wrapup.md) |
| Re-testing 1–3 fixed bugs after engineering shipped | Sequential, scoped to bug Test IDs | [references/sequential-wrapup.md](references/sequential-wrapup.md) |
| No test plan exists yet | Generate plan first | [references/test-plan.md](references/test-plan.md) |
| Phase doc lists features not yet implemented in code | Stop. Tell user — QA needs a working build | — |

## Scaffold folders if missing

If the target repo has no QA folder structure yet, run the bundled
scaffolder to create it:

```bash
bash <skill>/scripts/scaffold-qa.sh "$REPO_ROOT" PHASE_NUM [SLUG]
```

It creates (idempotent — won't overwrite existing files):

```
<repo>/docs/qa/
├── README.md                         # how QA works in this repo
├── phase-NN-<slug>-manual-test-plan.md  # filled-in skeleton
├── bug-reports/
│   ├── README.md                     # index + status workflow
│   ├── _template.md                  # bug template
│   └── assets/                       # screenshots
└── runs/                             # per-shard + coordinator merges
```

If a different layout already exists in the repo (e.g. `tests/manual/`,
`qa/`, an issue tracker), **adopt that layout** — do not duplicate it.

## Always

- **Real user perspective.** Drive the app, not the source. Test from URLs
  and clicks, not from `convex/users.ts` or the API layer alone.
- **Primary viewport first.** Default to **375 × 812 (mobile)** unless the
  app's product spec says otherwise. Re-test critical paths at desktop
  width when the product targets it.
- **One browser tab per agent.** Parallel agents on a shared tab cause
  auth-provider rate limits and stale sessions (observed across runs).
- **Capture evidence.** Snapshot or screenshot at the moment of failure,
  console errors verbatim, server data row when relevant.
- **File bugs immediately on FAIL** — see
  [references/bug-filing.md](references/bug-filing.md). Do not wait until
  end of pass.
- **Use the test account playbook.** See
  [references/test-accounts.md](references/test-accounts.md). If none
  documented, ask the user before guessing.
- **Session hygiene between scenarios.** See
  [references/session-hygiene.md](references/session-hygiene.md). Stale
  storage / cookies / `+test` email reuse silently poisons fresh-user
  flows.

## Never

- Mark a scenario PASS from code inspection alone. The user does not
  experience source — they experience the app.
- Mark a phase gate ☑ without evidence (snapshot, server row, console
  clean).
- Fix product code unprompted. Document. File. Hand off.
- Skip the **Known issues / deferrals** section in the phase doc — those
  drive your scope and prevent false bugs.
- Rename phase docs or specs to match buggy behavior. Hides regressions.
- Run multiple QA browser sub-agents on one cursor-ide-browser tab.
- Reuse a previously-failed test email without changing the run-tag suffix.

## Bug priority (BRB taxonomy)

| Level | Definition | Action |
|-------|------------|--------|
| **P0** | Blocks core flow; data loss; auth bypass; security | Phase cannot ship; halt QA pass until triaged |
| **P1** | Feature broken or wrong; workaround exists | Blocks current phase sign-off |
| **P2** | Cosmetic, edge case, accessibility, dev console noise | Defer to polish phase or release hardening |

When in doubt between P0 and P1, choose **P0** if a user could land in a
non-recoverable state or lose data.

## Pass criteria (any phase)

- All scenarios in the phase manual test plan **PASS** (or are explicitly
  **deferred** with reason in the phase doc).
- Phase gate / checklist all green.
- No open **P0** or **P1** bugs against this phase.
- For phases that touch auth / invites / notifications: the regression
  matrix is green.

## Definition of done

Every pass ends with a coordinator merge doc whose top line reads:

> **Phase N ready? YES** — all gates ☑, no open P0/P1.
> **Phase N ready? NO** — list open P0/P1 + remaining unrun scenarios + a
> one-paragraph handoff prompt for the next QA agent.

If **NO**, the merge doc must be paste-ready into a new conversation. The
next agent should not need to rediscover state. See
[references/gate-merge.md](references/gate-merge.md).

## Browser tools (cursor-first, fallback ladder)

Default to **cursor-ide-browser** MCP when running inside Cursor. If the
session is in another tool or browser MCP is missing, fall back per the
ladder in [references/browser-playbook.md](references/browser-playbook.md):

1. cursor-ide-browser MCP (Cursor / Claude Code)
2. browser-use MCP (provider-agnostic)
3. Playwright (CLI or MCP)
4. Driving manually + asking user to paste console errors / screenshots

Whatever tool, the **playbook** is the same: navigate → snapshot → act on
fresh refs → capture evidence → unlock when done. The reference covers
each tool's specifics.

## Deliverables per pass

| Path | What |
|------|------|
| `docs/qa/phase-NN-<slug>-manual-test-plan.md` | (if newly generated) |
| `docs/qa/runs/QA-<shard>-run-YYYY-MM-DD.md` | Per-shard results |
| `docs/qa/runs/COORDINATOR-MERGE-YYYY-MM-DD.md` | Merge + verdict |
| `docs/qa/bug-reports/BUG-NNN-*.md` + `assets/BUG-NNN/` | Each defect |
| `docs/QA_GATES.md` (or your repo's equivalent) | Gate boxes updated |
| Phase doc § QA status | Sign-off note + link to merge |

Adapt paths to whatever the target repo already uses.

## References (load on demand)

- [references/workflow.md](references/workflow.md) — full PM/QA/Eng decision tree
- [references/discovering-the-app.md](references/discovering-the-app.md) — investigate intent + ask user when docs missing
- [references/test-plan.md](references/test-plan.md) — derive a phase manual test plan from spec + phase doc + gate
- [references/test-accounts.md](references/test-accounts.md) — Clerk / Auth0 / Supabase / custom — and the "ask the user" pattern
- [references/session-hygiene.md](references/session-hygiene.md) — stale storage, rate limits, persona suffixing
- [references/browser-playbook.md](references/browser-playbook.md) — cursor-ide-browser, browser-use, Playwright recipes
- [references/parallel-coordinator.md](references/parallel-coordinator.md) — shard map, write-path-first rule, copy-paste shard prompts
- [references/sequential-wrapup.md](references/sequential-wrapup.md) — single-agent finish; copy-paste prompt
- [references/bug-filing.md](references/bug-filing.md) — bug template, severity, evidence rules
- [references/gate-merge.md](references/gate-merge.md) — merge shard reports → gates + verdict
- [references/templates/](references/templates/) — bug-report, test-plan, run-report, coordinator-merge skeletons

## Scripts

- `scripts/scaffold-qa.sh REPO_ROOT PHASE_NUM [SLUG]` — creates the QA
  folder layout and seeds skeletons in any repo.

## Anti-patterns to avoid

| Don't | Why |
|-------|-----|
| Mark scenarios PASS from code inspection | Users don't experience source |
| Defer P0 bugs to "next phase" | Foundation bugs cascade everywhere |
| Trust prior PASS marks without re-running on a fresh build | Regressions appear from unrelated work |
| Run multiple QA agents on one browser tab | Auth providers throttle; sessions bleed |
| Edit the phase doc to match buggy behavior | Hides the regression — file a bug instead |
| File a bug without **Steps to reproduce** | Engineering can't act on it |
| Test only the happy path | The happy path is what engineers tested already |

## When a QA pass reveals work bigger than QA

If during the pass you find:

- A **missing feature** the phase claims exists (no code path at all)
- A schema diverging from the spec across multiple scenarios
- A P0 blocking every remaining scenario

Stop testing. Surface the finding. The user decides whether to escalate to
engineering or carve a smaller phase. Continuing wastes time on a
foundation that needs replacing.
