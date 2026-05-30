# Manual test plan — Phase {N} ({slug})

**Audience:** QA, UAT, engineering verification
**Last updated:** {YYYY-MM-DD}
**Maps to:** [QA Gate {N}](../QA_GATES.md#gate-{N}--{slug})

Test **mobile (375 × 812), tablet (768 × 1024), and desktop (1280 × 800)**, leading with the spec's primary target. Use **incognito / private windows** for fresh-user flows.

When a scenario fails, file a bug: [bug-reports/README.md](./bug-reports/README.md).

---

## Setup before testing

| Item | Notes |
|------|--------|
| Environment | `<dev command>` running |
| Browser | Mobile emulation or real phone |
| Accounts | {list personas needed} |
| Backend tables to watch | {tables this phase reads/writes} |
| Console | Watch for errors and provider-specific dev warnings |

### Out of scope (do not file as Phase {N} blockers)

- {bullet list of stub pages, deferred features, things in later phases}

---

## Phase {N} — {Tentpole name}

### P{N}-A: {block intent — public / unauth / read-only}

| ID | Scenario | Steps | Expected | Gate |
|----|----------|-------|----------|------|
| P{N}-A1 | … | … | … | {N}.x |

### P{N}-B: {happy path}

| ID | Scenario | Steps | Expected | Gate |
|----|----------|-------|----------|------|
| P{N}-B1 | … | … | … | {N}.x |

### P{N}-C: {admin write paths — runs first as coordinator shard}

| ID | Scenario | Steps | Expected | Gate |
|----|----------|-------|----------|------|
| P{N}-C1 | … | … | … | {N}.x |

### P{N}-D: {new-user / edge}

### P{N}-E: {returning-user / persistence}

### P{N}-F: {roles + access control — negative tests}

### P{N}-G: {settings / admin config}

### P{N}-H: {navigation + stubs smoke}

---

## Regression matrix (if phase touches auth / invites / notifications)

Run each row as a full end-to-end test:

| Persona | Entry URL | Expected landing | In group / org? |
|---------|-----------|------------------|-----------------|
| … | … | … | … |

---

## Architecture reference (for debugging)

| Area | Path |
|------|------|
| Schema | {your-schema-path} |
| Public functions / API | {your-api-path} |
| Shared logic | {your-lib-path} |
| Pages | {your-pages-path} |
| Components | {your-components-path} |

---

## Pass criteria

**Phase {N} complete:** All P{N}-* pass; regression matrix green (if applicable); QA Gate {N} all ☑; no open P0/P1 bugs.

---

## Related

- [Bug reports](./bug-reports/README.md)
- [QA gates checklist](../QA_GATES.md)
- [Phase {N} doc](../phases/phase-{NN}-{slug}.md)
- [Skill: running-bug-review-board](~/.agents/skills/running-bug-review-board/SKILL.md)
