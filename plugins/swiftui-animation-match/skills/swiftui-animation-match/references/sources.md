# Source Index

Every catalog file in this skill is derived from one animation source
(usually a GitHub repo). This index records where each catalog came from,
which revision was read, and the license terms for lifting code.

Read the source's actual code before adapting an entry; catalogs summarize,
they do not replace the source.

## Registered sources

### Shubham0812/SwiftUI-Animations

- **Repo:** https://github.com/Shubham0812/SwiftUI-Animations
- **Catalog:** [catalog-shubham0812-swiftui-animations.md](catalog-shubham0812-swiftui-animations.md)
- **Pinned commit:** `2f5b377abc2f273143befa5ad31c63d1304c7faf` (analyzed 2026-07-15)
- **License:** Apache-2.0 — free to use, modify, and distribute in
  commercial and personal apps. Attribution appreciated.
- **Scope:** 30 self-contained SwiftUI animations (loaders, buttons,
  toggles, card decks, text heroes, reveals) + 7 Metal shader effects.
  Effective deployment floor iOS 17.0.
- **Author:** Shubham Kumar Singh (@Shubham0812)

## Staleness policy

- Each catalog pins the commit it was read at. When a source gains
  significant new animations, re-run the analysis (see
  [adding-a-source.md](adding-a-source.md), which covers refreshes too)
  and update the pinned commit.
- If a catalog path 404s against the live repo, the source moved or was
  renamed: re-verify against the pinned commit
  (`git checkout <sha>`) which is always valid, then refresh the catalog.

## Candidate sources (not yet cataloged)

Add repos here when they are worth cataloging but the analysis has not been
done yet — this is the queue for future additions. None currently queued.
