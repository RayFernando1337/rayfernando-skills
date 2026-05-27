# Parallel coordinator mode

Use when running a fresh full pass with multiple QA agents. Lessons from
real runs are baked in: **the write-path shard runs first** to seed
shared test data, and shards do not share a browser tab.

## When to use

- Phase is freshly implemented and needs a full pass
- Multiple agents / sessions available
- Time-boxed (parallel is faster but introduces auth / browser
  contention)

## When NOT to use

- Only 1–3 bug retests pending → use [sequential-wrapup.md](sequential-wrapup.md)
- One agent only → run scenarios top-to-bottom; do not pretend to shard
- Browser tool can't isolate per-agent (shared tab) → use sequential

## Pre-flight (coordinator only)

```bash
# Adapt these to your repo's commands
bun run validate        # build / typecheck must pass
bun dev                 # leave running
git status              # clean or known-state
```

Confirm:
- Auth provider dev keys are active
- Backend / DB available
- Prior coordinator merge in `docs/qa/runs/` so you don't overwrite

## Shard map (generalize per phase)

Generate the shard map from your test plan. Default skeleton:

| Letter | Block intent | Personas needed |
|--------|-------------|-----------------|
| A | Public + happy path (no auth or fresh signup only) | Fresh user |
| B | Returning user / persistence | 1 onboarded user |
| C | **Admin write paths** — runs first, seeds shared state | Admin |
| D | New user via shared write-path output (e.g. invite) | Admin + 2 fresh users |
| E | Returning user via shared write-path output | Admin + 2 onboarded users |
| F | Roles / access control / negative tests | Admin + member + co-admin |

Keep shards **non-overlapping**. If two shards would touch the same
record, merge them or split by persona.

## Write-path-first rule

The write-path shard (often "C") creates the artifact every other shard
depends on (a group, an org, a workspace, an invite). Run it before
launching the rest.

After the write-path shard reports completion, copy these into the other
agents' prompts:

- IDs created (group / org / tenant / project ID)
- Invite URLs / share codes
- Admin email + reference to where the password is stored
- Backend deployment URL (so subagents can verify data via MCP if
  available)
- Sign-up + sign-in flow recipe

## Launching shards

In Cursor (or your agent UI), launch each shard as a separate Task /
subagent with `run_in_background: true`. **One browser tab per shard is
mandatory** — if all agents share the same tab, run sequentially.

Use the prompt template at
[templates/shard-prompt.md](templates/shard-prompt.md). Per launch:

1. Customize the `## Your shard ONLY` table to one row (the assigned
   letter).
2. Paste the shared artifacts block from the write-path shard.
3. Give the agent a fresh persona suffix (`+runMMDD-shardX`).

## While shards run

- Tail subagent transcripts to know when they finish (system
  notifications fire on completion).
- Spot-check **critical paths** yourself — the highest-risk Test ID for
  this phase. Even if a shard reports PASS, run the one or two
  highest-risk scenarios as coordinator.
- Read backend MCP / dashboard to verify rows match expectations.
- Note any cross-shard observations (e.g. all shards saw same console
  warning) for the merge.

## Hand off if shards stall

The 2026-05-19 Mokuhoe run had 3 of 5 parallel agents stall on Clerk
rate-limits. The fix is **not** to relaunch in parallel — switch to
[sequential-wrapup.md](sequential-wrapup.md). Write what's done into a
coordinator merge stub, then trigger the sequential pass.

Signs of stall:
- Agent's last 5 minutes of output is the same retry loop
- "Too many requests" / 429 / "no sign in attempt was found"
- Browser refs going stale repeatedly

## Merge

When shards finish (complete or stalled with partial data):

1. Collect every `docs/qa/runs/QA-<letter>-run-YYYY-MM-DD.md`
2. Apply [gate-merge.md](gate-merge.md)
3. Verdict goes in `docs/qa/runs/COORDINATOR-MERGE-YYYY-MM-DD.md`
4. **Regenerate the HTML report** per
   [html-report-style-guide.md](html-report-style-guide.md): dashboard
   + per-bug + per-run pages.
5. If a tracker is configured, run:
   ```bash
   bash ~/.agents/skills/running-bug-review-board/scripts/bugs-needing-sync.sh "$REPO_ROOT"
   ```
   Push each listed bug per [issue-trackers.md](issue-trackers.md). Fill
   in the merge doc's "Tracker sync (this pass)" table.

## Common pitfalls (observed)

| Symptom | Cause | Fix |
|---------|-------|-----|
| "No sign in attempt was found" | Two agents in one tab → state mismatch | One tab per agent, or sequential |
| "Too many requests" on verify-email | Multiple parallel signups within 30s | Stagger 30s; use unique `+runMMDD-X` suffixes |
| Wrong account edits mid-run | Shared cookies between shards | Don't share tabs |
| Bug filed in wrong number sequence | Two agents picked same BUG-NNN | Coordinator assigns ranges or merges renames at end |
| Shard reports PASS but DB shows nothing wrote | Optimistic UI — agent didn't verify backend | Add backend-row check to scenarios |

## Shard prompt

Use [templates/shard-prompt.md](templates/shard-prompt.md). Fill in:

- `{PHASE_NUM}`
- `{SHARD_LETTER}` and `{SCENARIO_IDS}` and `{PERSONAS}`
- `{SHARED_ARTIFACTS}` (from the write-path shard output)
- `{RUN_DATE}` (YYYY-MM-DD)

## Coordinator self-check before merging

Before writing the verdict:

- [ ] Did I personally re-run the highest-risk Test ID?
- [ ] Did I verify backend state for at least one write-path scenario?
- [ ] Did I read every shard's run report (not just the chat summary)?
- [ ] Are bug numbers contiguous and titles unique?
- [ ] Are screenshots committed under `assets/BUG-NNN/`?
- [ ] Did each shard hit the "Recommended engineering priority"
      section, or did I synthesize one?

If any answer is no, do that before declaring YES/NO.
