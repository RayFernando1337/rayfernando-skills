# BUG-NNN: Short title

| Field | Value |
|-------|--------|
| **Status** | open |
| **Priority** | P0 / P1 / P2 |
| **Phase** | {N} |
| **Test ID** | e.g. P{N}-C1 (from manual test plan) |
| **Gate item** | e.g. {N}.4 (from QA_GATES.md) |
| **Reported by** | Name |
| **Reported on** | YYYY-MM-DD |
| **Environment** | local / staging / production |
| **Fixed in** | *(PR link or commit — fill when fixed)* |
| **Verified by** | *(QA name — fill when verified)* |

---

## Summary

One sentence describing the bug.

---

## Steps to reproduce

1.
2.
3.

---

## Expected result

What should happen according to the test plan or product spec.

---

## Actual result

What actually happened.

---

## Environment details

| Item | Value |
|------|--------|
| Device / browser | e.g. iPhone 14 Safari, Chrome 375px emulation |
| Account | e.g. fresh incognito, admin@test |
| URL | Full URL when bug occurred |
| Provider-specific (invite code, tenant, share link) | If relevant |

---

## Evidence

### Console errors

```
Paste browser console errors here (last 30 lines, no PII / tokens)
```

### Server / DB

- Backend dashboard observations (table, field values)
- Terminal log snippets if relevant

### Network

- Method, URL, status, sanitized response body (if 4xx/5xx)

### Screenshots

Attach or link screenshots. Place files in `docs/qa/bug-reports/assets/BUG-NNN/` if committed to repo.

---

## Notes

- Regression? (worked before / never worked)
- Related bugs: BUG-XXX
- Suggested fix area: (optional — file or function name; **never** prescribe the fix)

---

## Triage log

| Date | Who | Action |
|------|-----|--------|
| YYYY-MM-DD | | Filed |
| | | |

---

*This front-matter and the section headings above are what the HTML report
generator and the tracker sync helpers parse. Keep them stable so the
report renders and `bugs-needing-sync.sh` / `bugs-needing-pull.sh` find
the tracker fields.*
