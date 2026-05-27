# Browser playbook — cursor-first, fallback ladder

Drive the app like a real user. Whatever tool the agent has, the playbook
is the same: navigate → snapshot → act on **fresh refs** → capture
evidence → release the tab when done.

## Scope: web apps only

This playbook covers **web app QA in a browser** — Chrome viewport
emulation, real Safari / Firefox, headless Playwright. If the repo under
QA is an iOS / iPadOS application project, use
[ios-simulator-playbook.md](ios-simulator-playbook.md) instead. Web app
QA does **not** boot iOS simulators; the project-type detection in
[discovering-the-app.md](discovering-the-app.md) decides which playbook
activates.

## Tool ladder (cursor-first)

Use whichever is available. The shape of the work is identical.

| # | Tool | When |
|---|------|------|
| 1 | **cursor-ide-browser** MCP | Default inside Cursor / Claude Code with this MCP installed |
| 2 | **browser-use** MCP | Provider-agnostic; works in many agent environments |
| 3 | **Playwright** (CLI or MCP) | Repo already has it; or for headless CI-style runs |
| 4 | Manual + screenshot relay | No browser tool — drive yourself, paste console errors and screenshots into chat |

If multiple work, prefer cursor-ide-browser when running in Cursor — its
snapshot YAML and `browser_cdp` give the richest control.

## The universal flow

```
list  tabs                       → see what's open
resize/devtools to 375×812       → primary viewport
lock  the tab (one agent only)
navigate http://localhost:3000/...
snapshot                         → fresh element refs (REQUIRED before each click)
fill / click / press / scroll
wait_for text / time / network idle
capture console + screenshots on failure
unlock                           → only when fully done
```

Always re-snapshot after navigation, click, or form submit — refs go
stale. "Element X has pointer-events: none" or "ref not found" almost
always means a stale snapshot.

## cursor-ide-browser specifics

Reference: tool descriptors live at
`~/.cursor/projects/<workspace>/mcps/cursor-ide-browser/tools/`.

Common calls:

```
browser_tabs           action: list
browser_navigate       url, newTab
browser_lock           viewId, action: lock|unlock
browser_resize         viewId, width, height
browser_snapshot       viewId, take_screenshot_afterwards: true
browser_click          viewId, ref, element (description)
browser_fill           viewId, ref, value
browser_select_option  viewId, ref, value
browser_press_key      viewId, key
browser_scroll         viewId, direction, amount
browser_console_messages viewId
browser_take_screenshot  viewId
browser_cdp            viewId, method, params  ← raw CDP for advanced cases
browser_highlight      viewId, ref            ← debug refs visually
```

**Important:** never call `browser_cdp` with `Input.*` methods (focus
issues in Electron); use the dedicated input tools instead.

### Setting viewport via CDP

```
browser_cdp Emulation.setDeviceMetricsOverride
  { width: 375, height: 812, deviceScaleFactor: 1, mobile: true }
```

### Clearing app storage between scenarios

```
browser_cdp Runtime.evaluate
  expression: "sessionStorage.clear(); localStorage.clear()"
  returnByValue: true
```

### Capturing storage as evidence (before clearing)

```
browser_cdp Runtime.evaluate
  expression: "JSON.stringify({ss: {...sessionStorage}, ls: {...localStorage}, cookies: document.cookie})"
  returnByValue: true
```

## browser-use specifics

browser-use exposes a flat action vocabulary: `goto`, `type`, `click`,
`extract_content`, `take_screenshot`, `evaluate`, `clear_cookies`,
`scroll`. Each scenario step maps directly. Page state is described back
to the agent in natural language.

When using browser-use, prefer `extract_content` to grab the full text
of the current page on errors instead of relying on screenshots alone —
helps with bug evidence.

## Playwright specifics

For projects with Playwright already configured, you can drive scenarios
in `tests/manual/<scenario>.spec.ts` and run with:

```bash
npx playwright test tests/manual/<scenario>.spec.ts --headed
```

Use `page.pause()` for interactive debugging, `page.screenshot({ path:
'docs/qa/bug-reports/assets/BUG-NNN/01-step.png' })` for evidence,
`page.context().clearCookies()` for hygiene.

For one-off scenarios without writing a spec, use Playwright in a REPL
or `npx playwright codegen` to record actions then translate to
imperative steps in the run report.

## Snapshot vs screenshot — when to use what

| Need | Use |
|------|-----|
| Element refs to click / fill | snapshot (YAML / accessibility tree) |
| Visual evidence of bug | screenshot (PNG) |
| Console state | console_messages |
| Network failure | network requests / response |
| Storage state | CDP Runtime.evaluate on storage |
| Layout / overflow at small width | screenshot at exact viewport |

## Mobile readability spot-checks

Every page touched at 375 × 812 — eyeball:

- All tap targets ≥ **44 × 44 px**
- No horizontal scroll on body
- Text contrast readable in default theme
- Form fields visible above on-screen keyboard (focus an input near page
  bottom and confirm)
- Submit button reachable without scroll-to-find
- Modal close affordance on-screen

File a P2 cosmetic bug if any fail. These accumulate across phases and
get triaged in the polish phase.

## Capturing console errors as evidence

After every interaction (or at end of scenario):

```
browser_console_messages viewId
```

Paste verbatim into the bug's Evidence section — last 30 lines is
plenty. Strip any tokens / personal data from auth headers if present.

Real-user-relevant levels: `error`, `warn`. Ignore `info`/`debug` noise
unless it correlates with the failure.

## Network capture

If a scenario's failure looks like a 4xx/5xx, grab the network event:

```
browser_cdp Network.enable
# trigger the action
browser_cdp Network.getResponseBody     # for the relevant request
```

Or use `browser_network_requests` if exposed by your MCP.

Add the request method, URL, status, and (sanitized) response body to
the bug evidence.

## Common UI gotchas (universal)

| Symptom | Cause / Fix |
|---------|-------------|
| `Element X has pointer-events: none` after click | Form is in `Saving…` state — wait 3s, re-snapshot |
| Cloudflare Turnstile / hCaptcha "loading forever" | Refresh tab; stagger between auth attempts; check provider rate limit |
| `Couldn't find your account` after correct password | Account didn't complete OTP; create with fresh `+runMMDD-N` suffix |
| Blank page after redirect | Auth state not yet ready — see [session-hygiene.md](session-hygiene.md) for the auth ↔ routing race |
| Hydration warning on landing | Often P2 — note in console section, do not fail scenario |
| Action does nothing visually but Convex/DB wrote a row | Optimistic UI mismatch — file a P1 |

## Tab discipline (parallel mode)

If you must shard across multiple agents, **one tab per agent**.
Confirmed via 2026-05-19 Mokuhoe run: shared tabs caused half the shards
to stall on stolen OTPs and lost sessions.

If your tooling can't isolate per-agent (e.g. all agents share the IDE
browser), run **sequentially** instead — see
[sequential-wrapup.md](sequential-wrapup.md).

## Capturing evidence efficiently

For each FAIL:

1. Take screenshot at moment of failure (not the next-page error)
2. Save to `docs/qa/bug-reports/assets/BUG-NNN/01-<step>.png`
3. Copy console errors into bug Evidence section
4. Capture URL at failure (full, with query string)
5. (If side-effect) capture relevant DB row from your backend
6. (If 4xx/5xx) capture network request + status

For each PASS, evidence in the run report can be lighter — usually just
"snapshot confirmed expected text" or a one-line description.

## When the browser tool itself is broken

If `browser_snapshot` returns garbage, `browser_navigate` doesn't move
the tab, or the agent loses control of the browser:

1. `browser_unlock` (release any held lock)
2. `browser_tabs list` — see if the tab still exists
3. If yes: `browser_lock` again and retry one operation
4. If no: `browser_navigate` to a fresh tab and retry

If recovery fails twice in a row, **stop and report**. Don't loop. The
parent agent (or user) decides whether to switch tools or restart.
