# QA Run — {Shard} — {YYYY-MM-DD}

| Field | Value |
|-------|--------|
| **Agent** | {QA-X or SEQUENTIAL} |
| **Phase** | {N} |
| **Environment** | local (`http://localhost:3000`) |
| **Device modes** | mobile 375 × 812 · tablet 768 × 1024 · desktop 1280 × 800 (primary: ___) |
| **Build** | `<validate command>` {PASS/FAIL} at start |
| **Shared artifacts** | {group ID, invite URL, admin email — fill from coordinator} |

## Summary

| Metric | Count |
|--------|------:|
| Scenarios run | N |
| Passed | N |
| Failed | N |
| Blocked | N |

## Results table

| Test ID | Result | Gate | Notes / Bug ID |
|---------|--------|------|----------------|
| P{N}-A1 | PASS | {N}.x | |
| P{N}-B3 | FAIL | {N}.x | BUG-NNN |

## Bugs filed

| Bug | Title | Priority |
|-----|-------|----------|
| BUG-NNN | … | P0/P1/P2 |

## Tracker sync (this run)

| Tracker | Pushed (new) | Updated | Pulled | Diverged |
|---------|-------------:|--------:|-------:|---------:|
| {linear/github/jira/notion/none} | N | N | N | N |

## Gate {N} status (this shard)

| # | Item | Result |
|---|------|--------|
| {N}.1 | … | ☑ / ☐ |

## Blockers / env issues

- {auth rate-limit / backend sync / shared tab / …}

## Recommended engineering priority

| Priority | Item |
|----------|------|
| P0 | … |
| P1 | … |
| P2 / defer | … |

## Evidence highlights

- {Critical-path scenario IDs with short evidence note}

## Re-test checklist (if BLOCKED items)

- [ ] {Test ID} — {what to re-do in clean session}

---

## Related

- [Manual test plan](../phase-{NN}-{slug}-manual-test-plan.md)
- [QA gates](../../QA_GATES.md#gate-{N}--{slug})
- [Bug reports](../bug-reports/README.md)
