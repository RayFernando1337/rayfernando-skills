# HTML report style guide — Apple design language

The QA agent generates an HTML report (`docs/qa/report/`) from the existing
markdown bug and run files. **Markdown stays the source of truth.** HTML is
the read-only view layer the team scans during triage.

This reference encodes the design language so any agent that follows it
produces consistent, scannable, Apple-style output. The agent reads this
file, opens the skeleton templates in
[templates/html-report/](templates/html-report/), and writes
`docs/qa/report/index.html` + `bugs/BUG-NNN.html` + `runs/<slug>.html`.

## Contract

- **Source of truth:** markdown in `docs/qa/bug-reports/` and `docs/qa/runs/`.
- **HTML is regenerated** at the end of every auto QA pass, at the end of
  every interactive BRB session, and on user request ("refresh the report").
- **Never edit HTML to change bug state.** Edit the markdown; regenerate.
- **Version marker:** every generated page carries
  `<!-- skill:running-bug-review-board v0.2 -->` near the top of `<head>`.
  Later agents look for this marker to decide whether to extend or rewrite.
- **If a marker doesn't match** (someone hand-edited the file or the
  version is older): write to `index.next.html` (or `bugs/BUG-NNN.next.html`)
  and tell the user to diff. Never silently overwrite.

## Output layout

```
docs/qa/report/
├── index.html              # dashboard
├── assets.css              # shared stylesheet (one copy, embedded if you prefer)
├── bugs/
│   └── BUG-NNN.html        # one per bug-report markdown
└── runs/
    └── <slug>.html         # one per run-report or coordinator-merge markdown
```

The folder sits next to the markdown sources under `docs/qa/`, so links
between pages stay short and `assets/BUG-NNN/*.png` paths resolve with
`../../bug-reports/assets/BUG-NNN/...`.

## Apple design tokens

All values come from Apple's
[Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/).
Encode as CSS custom properties so the agent always works in semantic names.

### Typography (iOS Large default scale)

| Style | Size | Weight | Leading | Use |
|-------|------|--------|---------|-----|
| Large Title | 34 | Regular (Bold emphasized) | 41 | Dashboard page title |
| Title 1 | 28 | Regular (Bold) | 34 | Page section ("Open P0", "Recent runs") |
| Title 2 | 22 | Regular (Bold) | 28 | Bug detail page title |
| Title 3 | 20 | Regular (Semibold) | 25 | Card title |
| Headline | 17 | Semibold | 22 | Card subtitle, table header |
| Body | 17 | Regular (Semibold emphasized) | 22 | Default body text |
| Callout | 16 | Regular | 21 | Field labels |
| Subhead | 15 | Regular | 20 | Metadata, secondary lines |
| Footnote | 13 | Regular | 18 | Small captions |
| Caption 1 | 12 | Regular | 16 | Triage log timestamps |
| Caption 2 | 11 | Regular | 13 | Smallest annotations |

Font stack:

```css
--font-text: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display",
             "Helvetica Neue", Helvetica, Arial, sans-serif;
--font-mono: ui-monospace, "SF Mono", Menlo, Monaco, "Cascadia Mono", monospace;
```

### Color (Apple system palette)

Default light / default dark hex values (matches HIG specification tables;
the increased-contrast pair is left to a future `prefers-contrast: more`
block).

| Token | Light | Dark | Role in QA report |
|-------|-------|------|-------------------|
| systemRed | `#FF3B30` | `#FF453A` | P0, NO verdict, `open` status, fail |
| systemOrange | `#FF9500` | `#FF9F0A` | P1, `fixed` status pending re-test |
| systemYellow | `#FFCC00` | `#FFD60A` | P2, warning, nit |
| systemGreen | `#34C759` | `#30D158` | YES verdict, `verified` status, pass |
| systemMint | `#00C7BE` | `#66D4CF` | Recent activity highlight |
| systemTeal | `#30B0C7` | `#40C8E0` | Info chip |
| systemCyan | `#32ADE6` | `#64D2FF` | Filter active chip |
| systemBlue | `#007AFF` | `#0A84FF` | Primary links + actions, `in-progress` |
| systemIndigo | `#5856D6` | `#5E5CE6` | Tracker tag (Linear / GitHub / Jira) |
| systemPurple | `#AF52DE` | `#BF5AF2` | BRB session marker |
| systemPink | `#FF2D55` | `#FF375F` | Regression marker |
| systemBrown | `#A2845E` | `#AC8E68` | `deferred` status |
| systemGray | `#8E8E93` | `#8E8E93` | Secondary text, `wontfix` |
| systemGray2 | `#AEAEB2` | `#636366` | `duplicate` status |
| systemGray3 | `#C7C7CC` | `#48484A` | Borders |
| systemGray4 | `#D1D1D6` | `#3A3A3C` | Subtle dividers |
| systemGray5 | `#E5E5EA` | `#2C2C2E` | Card surface |
| systemGray6 | `#F2F2F7` | `#1C1C1E` | Page background |
| label | `#000000` | `#FFFFFF` | Primary text |
| secondaryLabel | `rgba(60,60,67,0.60)` | `rgba(235,235,245,0.60)` | Subhead text |
| tertiaryLabel | `rgba(60,60,67,0.30)` | `rgba(235,235,245,0.30)` | Inactive |

### Spacing — 8-point grid

```css
--space-1:  4px;
--space-2:  8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
```

### Radius

```css
--radius-chip:    8px;   /* pills, chips */
--radius-card:   12px;   /* bug cards */
--radius-surface:16px;   /* page sections */
--radius-hero:   20px;   /* verdict hero */
```

### Layout

```css
--container-narrow: 768px;   /* bug detail (reading optimized) */
--container-wide: 1024px;    /* dashboard */
--page-pad: clamp(20px, 4vw, 32px);
--card-pad: 20px;
```

### Elevation

```css
--shadow-1: 0 1px 2px rgba(0,0,0,0.04), 0 1px 1px rgba(0,0,0,0.06);
--shadow-2: 0 2px 8px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
--shadow-3: 0 8px 24px rgba(0,0,0,0.12), 0 2px 6px rgba(0,0,0,0.04);
```

In dark mode, prefer a 1px `border: 1px solid var(--systemGray3-dark)`
over shadows — Apple's pattern.

## Semantic role mapping

The agent **never** picks colors based on aesthetics. It uses the role
name and the stylesheet does the rest.

| Concept | Class | Visual |
|---------|-------|--------|
| P0 | `.chip.chip-p0` | systemRed background, white text, "P0" label |
| P1 | `.chip.chip-p1` | systemOrange |
| P2 | `.chip.chip-p2` | systemYellow, black text (for contrast on yellow) |
| YES verdict | `.badge.badge-yes` | systemGreen pill, white text, checkmark |
| NO verdict | `.badge.badge-no` | systemRed pill, white text, x-mark |
| Status `open` | `.pill.pill-open` | outline + systemRed dot |
| Status `in-progress` | `.pill.pill-in-progress` | outline + systemBlue dot |
| Status `fixed` | `.pill.pill-fixed` | outline + systemOrange dot |
| Status `verified` | `.pill.pill-verified` | outline + systemGreen dot |
| Status `deferred` | `.pill.pill-deferred` | outline + systemBrown dot |
| Status `wontfix` | `.pill.pill-wontfix` | outline + systemGray dot |
| Status `duplicate` | `.pill.pill-duplicate` | outline + systemGray2 dot, with "Duplicate of BUG-XXX" subtext |
| Regression marker | `.tag.tag-regression` | systemPink chip |
| Tracker tag | `.tag.tag-tracker` | systemIndigo chip, shows "Linear / LIN-1234" |

**Color is never alone.** Every priority / status pairs the swatch with a
text label so screen readers and color-blind viewers always know what
they're looking at.

## Components

Each component below has a fenced HTML snippet the agent copies and fills.
See [templates/html-report/](templates/html-report/) for full skeleton
files that wire these together.

### Page chrome — `<head>`

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">
  <title>{TITLE}</title>
  <link rel="stylesheet" href="assets.css">
  <!-- skill:running-bug-review-board v0.2 -->
</head>
```

### Top bar

```html
<header class="topbar">
  <div class="topbar-inner">
    <h1 class="topbar-title">{TITLE}</h1>
    <p class="topbar-meta">
      Last updated <time datetime="{ISO}">{HUMAN}</time>
      · <a href="../">QA folder</a>
    </p>
  </div>
</header>
```

### Verdict hero

```html
<section class="hero hero-verdict hero-{YES|NO}">
  <div class="hero-eyebrow">Phase {N} — {SLUG}</div>
  <div class="hero-headline">
    <span class="badge badge-{YES|NO}">{YES|NO}</span>
    <span>{Headline phrase from merge doc}</span>
  </div>
  <dl class="hero-stats">
    <div><dt>Open P0</dt><dd>{N}</dd></div>
    <div><dt>Open P1</dt><dd>{N}</dd></div>
    <div><dt>Last merge</dt><dd>{YYYY-MM-DD}</dd></div>
  </dl>
  <a class="hero-cta" href="runs/{merge-slug}.html">Open merge doc →</a>
</section>
```

### Priority chip

```html
<span class="chip chip-p0">P0</span>
<span class="chip chip-p1">P1</span>
<span class="chip chip-p2">P2</span>
```

### Status pill

```html
<span class="pill pill-open"><span class="dot"></span> Open</span>
<span class="pill pill-in-progress"><span class="dot"></span> In progress</span>
<span class="pill pill-fixed"><span class="dot"></span> Fixed</span>
<span class="pill pill-verified"><span class="dot"></span> Verified</span>
<span class="pill pill-deferred"><span class="dot"></span> Deferred</span>
<span class="pill pill-wontfix"><span class="dot"></span> Won't fix</span>
<span class="pill pill-duplicate">
  <span class="dot"></span> Duplicate of
  <a href="BUG-{XXX}.html">BUG-{XXX}</a>
</span>
```

### Bug card (dashboard tile)

```html
<article class="bug-card" data-priority="P0" data-status="open" data-phase="2">
  <header class="bug-card-head">
    <a class="bug-card-title" href="bugs/BUG-{NNN}.html">{Title}</a>
    <div class="bug-card-chips">
      <span class="chip chip-{p0|p1|p2}">{P0|P1|P2}</span>
      <span class="pill pill-{status}"><span class="dot"></span> {Status}</span>
    </div>
  </header>
  <p class="bug-card-summary">{One-sentence summary}</p>
  <footer class="bug-card-meta">
    <span>Phase {N}</span> · <span>{Test ID}</span> · <span>Reported {DATE}</span>
    {if tracker.linear.id}· <span class="tag tag-tracker">Linear {LIN-1234}</span>{endif}
  </footer>
</article>
```

### Bug board (dashboard, three columns)

```html
<section class="board" aria-label="Open bugs by priority">
  <div class="board-column board-column-p0">
    <h2 class="board-column-title">
      <span class="chip chip-p0">P0</span> {N} open
    </h2>
    {bug cards…}
  </div>
  <div class="board-column board-column-p1">
    <h2 class="board-column-title">
      <span class="chip chip-p1">P1</span> {N} open
    </h2>
    {bug cards…}
  </div>
  <div class="board-column board-column-p2">
    <h2 class="board-column-title">
      <span class="chip chip-p2">P2</span> {N} open
    </h2>
    {bug cards…}
  </div>
</section>
```

### Recent runs table

```html
<section class="runs">
  <h2 class="section-title">Recent runs</h2>
  <table class="runs-table">
    <thead>
      <tr>
        <th>Date</th><th>Phase</th><th>Verdict</th>
        <th>P0</th><th>P1</th><th>P2</th><th></th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><time datetime="{ISO}">{YYYY-MM-DD}</time></td>
        <td>{N}</td>
        <td><span class="badge badge-{yes|no}">{YES|NO}</span></td>
        <td>{N}</td><td>{N}</td><td>{N}</td>
        <td><a href="runs/{slug}.html">Open →</a></td>
      </tr>
    </tbody>
  </table>
</section>
```

### Bug detail page

Two-column on wide screens; single column under 720px.

```html
<article class="bug">
  <aside class="bug-meta" aria-label="Bug metadata">
    <h2 class="bug-meta-title">BUG-{NNN}</h2>
    <dl>
      <div><dt>Status</dt><dd><span class="pill pill-{status}">…</span></dd></div>
      <div><dt>Priority</dt><dd><span class="chip chip-{px}">{Px}</span></dd></div>
      <div><dt>Phase</dt><dd>{N}</dd></div>
      <div><dt>Test ID</dt><dd>{P{N}-{block}{n}}</dd></div>
      <div><dt>Gate</dt><dd>{N}.{x}</dd></div>
      <div><dt>Reported</dt><dd><time>{DATE}</time> by {NAME}</dd></div>
      {if duplicate}
      <div><dt>Duplicate of</dt><dd><a href="BUG-{XXX}.html">BUG-{XXX}</a></dd></div>
      {endif}
      {if related}
      <div><dt>Related</dt><dd>{links}</dd></div>
      {endif}
      {tracker rows}
    </dl>
  </aside>

  <div class="bug-body">
    <h1 class="bug-title">{Title}</h1>

    <section class="bug-section" id="summary">
      <h2>Summary</h2>
      <p>{One-sentence summary}</p>
    </section>

    <section class="bug-section" id="steps">
      <h2>Steps to reproduce</h2>
      <ol>{step list}</ol>
    </section>

    <section class="bug-section" id="expected">
      <h2>Expected result</h2>
      <p>{Expected}</p>
    </section>

    <section class="bug-section" id="actual">
      <h2>Actual result</h2>
      <p>{Actual}</p>
    </section>

    <section class="bug-section" id="evidence">
      <h2>Evidence</h2>
      {Console block, server / DB block, network block}
      <div class="evidence-gallery">
        {images}
      </div>
    </section>

    <section class="bug-section" id="notes">
      <h2>Notes</h2>
      <p>{Notes content}</p>
    </section>

    <section class="bug-section" id="triage">
      <h2>Triage log</h2>
      <table class="triage-log">…</table>
    </section>
  </div>
</article>
```

### Evidence gallery

```html
<div class="evidence-gallery">
  <a class="evidence-tile" href="../../bug-reports/assets/BUG-{NNN}/01-step.png" target="_blank" rel="noopener">
    <img loading="lazy" src="../../bug-reports/assets/BUG-{NNN}/01-step.png" alt="Step 1 — page load">
    <figcaption>01-step.png</figcaption>
  </a>
  {…more tiles…}
</div>
```

Use CSS Grid `grid-template-columns: repeat(auto-fit, minmax(240px, 1fr))`
so tiles flow naturally.

### Filter bar

```html
<nav class="filters" aria-label="Filter bugs">
  <details class="filter-group">
    <summary>Priority</summary>
    <label><input type="checkbox" data-filter="priority" value="P0" checked> P0</label>
    <label><input type="checkbox" data-filter="priority" value="P1" checked> P1</label>
    <label><input type="checkbox" data-filter="priority" value="P2" checked> P2</label>
  </details>
  <details class="filter-group">
    <summary>Status</summary>
    <label><input type="checkbox" data-filter="status" value="open" checked> Open</label>
    <!-- … -->
  </details>
</nav>
```

Pair with a tiny inline `<script>` that toggles `[hidden]` on each
`.bug-card` based on its `data-priority` / `data-status` / `data-phase`.

### Footer

```html
<footer class="footer">
  <p class="footer-meta">
    Generated <time datetime="{ISO}">{HUMAN}</time> by the
    <code>running-bug-review-board</code> skill v0.2.
    Markdown is the source of truth — edit
    <a href="../bug-reports/">bug-reports/</a> and regenerate.
  </p>
</footer>
```

## Rendering rules

- **Escape all user-supplied text** (bug titles, summaries, body, console
  errors). HTML entity escape; never trust the markdown.
- **Image paths** are relative from the report folder back into the
  existing assets folder: `../../bug-reports/assets/BUG-{NNN}/...`. Do not
  copy images; reference in place.
- **Strip secrets** from console blocks the same way `bug-filing.md`
  rules already require — re-apply on render in case the markdown
  contains stale tokens.
- **Preserve the version marker** when re-rendering. If the existing
  file's marker doesn't match v0.2 (or has been removed), write to
  `index.next.html` / `bugs/BUG-NNN.next.html` and tell the user to diff.
- **Regenerate the whole `docs/qa/report/` folder each pass** — it's a
  view, not a state store. Old pages for deleted bugs disappear.
- **Always rewrite `assets.css`** from the canonical version in
  [templates/html-report/assets.css](templates/html-report/assets.css).

## Accessibility

- Contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text. The Apple system
  palette already meets this on the chosen backgrounds.
- Focus rings visible (`:focus-visible { outline: 2px solid var(--systemBlue); outline-offset: 2px; }`).
- All chips and pills have text labels; no color-only signaling.
- `prefers-reduced-motion: reduce` disables hover transitions.
- Print stylesheet at the bottom of `assets.css` so a paper BRB looks
  decent: hide filters + footer chrome, force monochrome chips with
  borders, expand evidence images.

## When the agent is asked to "refresh the report"

1. Read `docs/qa/qa-config.json` for `report.outputDir` and `report.title`
   (default `docs/qa/report` and "QA Report").
2. Read every markdown bug file (skipping `_template.md`), every run
   report, and the latest coordinator merge.
3. Write `assets.css` from the canonical template.
4. Write `index.html` using the dashboard skeleton.
5. Write one `bugs/BUG-{NNN}.html` per bug.
6. Write one `runs/{slug}.html` per run + merge.
7. Print a one-line summary: "Wrote {N} bug pages, {M} run pages, index
   updated. Open `docs/qa/report/index.html`."

## Optional: templating via a small Python script

If you prefer to render programmatically rather than inline (e.g. for very
large bug corpora), an example script is documented at the bottom of
[templates/html-report/](templates/html-report/). It is **optional** —
the default is the agent renders the HTML directly.

## Extending the style guide

To add a new component (e.g. an "owner badge" once tracker assignees are
pulled), add a row to the **Semantic role mapping** table, a recipe under
**Components**, and the CSS in `assets.css`. Bump the version marker if
the change is breaking. See
[extending-the-skill.md](extending-the-skill.md).
