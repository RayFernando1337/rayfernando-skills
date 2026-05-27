# HTML report skeletons

Three files plus a stylesheet that the QA agent copies into
`docs/qa/report/` whenever it generates or refreshes the HTML report.

| File | Becomes | Notes |
|------|---------|-------|
| `assets.css` | `docs/qa/report/assets.css` | Verbatim. Re-write every generation. |
| `index.html` | `docs/qa/report/index.html` | Dashboard. Slot the placeholder tokens (`{{TITLE}}`, `{{VERDICT_…}}`, `{{P0_BUG_CARDS}}`, …) with real content. |
| `bug.html` | `docs/qa/report/bugs/BUG-NNN.html` | One per markdown bug. Mustache-style sections (`{{#FIXED_IN}}…{{/FIXED_IN}}`) mark conditional blocks. |
| `run.html` | `docs/qa/report/runs/<slug>.html` | One per run report and coordinator merge. |

## How the agent uses these

1. Read the style guide:
   [`../../html-report-style-guide.md`](../../html-report-style-guide.md).
2. Read every markdown source under `docs/qa/bug-reports/` and
   `docs/qa/runs/`.
3. For each skeleton: copy the file into the output folder, then
   substitute the `{{TOKEN}}` placeholders with HTML-escaped values from
   the parsed markdown. Loops (e.g. `{{P0_BUG_CARDS}}`) are rendered by
   concatenating the corresponding component snippet from the style guide
   for each item.
4. Write `assets.css` verbatim into `docs/qa/report/assets.css`.
5. Preserve the `<!-- skill:running-bug-review-board v0.2 -->` marker.
6. Print a one-line summary in chat.

## Token conventions

- `{{NAME}}` — single value, HTML-escape the substitution.
- `{{#NAME}}…{{/NAME}}` — conditional block; render only if `NAME` is
  truthy.
- `{{NAME_HTML}}` — pre-rendered HTML fragment (used for body sections
  that already contain `<p>`, `<ul>`, etc.). Still escape any user-
  supplied text inside.
- Token names that end in `_ISO` are machine timestamps for `<time>`;
  matching `_HUMAN` is the rendered string.

## Optional: programmatic templating

If you prefer to render via a small script (e.g. for very large bug
corpora), use `re.sub` over the skeleton with the token map, or a tiny
mustache library. No script ships with the skill — that is intentionally
left to the agent.

## Updating these skeletons

Treat changes to `assets.css` or the skeletons as a skill version bump:

1. Update the `<!-- skill:running-bug-review-board vX.Y -->` marker in
   each HTML file.
2. Bump `plugin.json` and `marketplace.json`.
3. Document the change in `CHANGELOG.md`.

See [`../../extending-the-skill.md`](../../extending-the-skill.md) for the
full version-bump checklist.
