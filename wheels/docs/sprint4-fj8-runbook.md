# F-J-8 — Micro-optimization runbook

**Target screen:** `HelpCenterScreen` (specifically the browse-view scroll and the
per-category listing scroll). The seed corpus was bumped from 20 → 50
articles in commit (pending) so each category listing now has ~10 tiles
to scroll through.

## Order of operations

1. **Capture the baseline** (this runbook, steps 1–5) — *before* applying any
   optimization to the screen.
2. Ping Claude with "ok, reaply F-J-8 optimizations" and Claude will apply
   the `RepaintBoundary` / sub-Consumer split / `cacheExtent` changes.
3. **Capture the post-change** measurements (same steps, screenshots saved
   under `after/`).
4. Update Wiki §6.1 with the screenshots and a numeric delta.

## 1. Build in profile mode

Profile mode is required — debug-mode performance is intentionally
degraded and does not reflect real-device behavior.

From the repo root:

```
cd wheels
flutter run --profile -d <device_id>
```

`flutter devices` lists the connected device IDs. Use a **real Android
device** if you have one available; emulator is acceptable as fallback but
note it in the Wiki.

## 2. Open Flutter DevTools

When the app boots, the terminal prints a URL like:

```
The Flutter DevTools debugger and profiler on <device> is available at:
  http://127.0.0.1:9100?uri=http://127.0.0.1:50000/...
```

Open that URL in Chrome. Go to the **Performance** tab.

## 3. Capture baseline — browse view scroll

Inside the app:

1. Sign in. Open the drawer → tap **Help & Support**. You land on the
   Help Center.
2. In DevTools Performance, press **Record** (the red circle).
3. In the app, scroll the browse view up and down for **5 full seconds**
   (consistent thumb speed; do not pause).
4. Press **Stop** in DevTools.

Now take 2 screenshots:

- The **timeline frame chart** (top section showing the colored bars per
  frame). Save as
  `wheels/docs/screenshots/microopt/jorge/before/browse-frame-chart.png`.
- The **frame analysis details** that show UI thread + raster thread
  averages (right side panel, "Enhance tracing" / "Frame analysis").
  Save as
  `wheels/docs/screenshots/microopt/jorge/before/browse-frame-analysis.png`.

Write down the numbers you see (you'll paste them later into the Wiki):

| Metric                | Value (before) |
| --------------------- | -------------- |
| Median frame build    | … ms           |
| P95 frame build       | … ms           |
| Median raster         | … ms           |
| P95 raster            | … ms           |
| Janky frames (>16 ms) | … of …         |

## 4. Capture baseline — category listing scroll

Same procedure but with the category listing open:

1. In the app, tap a category card (e.g. **Account** or **Drivers**) — now
   each category has ~10 articles after the seed bump.
2. Record DevTools Performance.
3. Scroll the listing up/down for 5 seconds.
4. Stop, screenshot, save under `before/` as:
   - `category-frame-chart.png`
   - `category-frame-analysis.png`
5. Note the numbers in the same table.

## 5. (Optional) Capture baseline — search results

If you have time:

1. From the Help Center, type a query that matches several articles (e.g.
   `ride` or `driver`).
2. Wait 300 ms for the debounce, then scroll the search results.
3. Save screenshots as `search-frame-chart.png` and
   `search-frame-analysis.png` under `before/`.

## 6. Ping Claude to apply the optimizations

Tell Claude: **"ok, reaply F-J-8 optimizations"**.

Claude will:

- Split `_HelpBrowseView` into independent `Consumer` sections, each
  wrapped in `RepaintBoundary`, so a change to one section does not
  rebuild/repaint the others.
- Add `RepaintBoundary` around every `HelpArticleTile` in the category
  listing, search results, recently-viewed strip and most-helpful list.
- Add `cacheExtent: 600` + `addAutomaticKeepAlives: false` +
  `addRepaintBoundaries: false` on the long `ListView.separated` lists.
- Lift the `_ContactSupportSection` so the snackbar callback does not pull
  the entire browse view into its `ConsumerWidget` build.

Once applied:

```
cd wheels
flutter analyze
flutter test test/features/help
flutter run --profile -d <device_id>
```

## 7. Capture post-change

Repeat steps 3, 4, (5) but save the screenshots under `after/` instead of
`before/`. Re-record the same metrics table column under **Value (after)**.

## 8. Update Wiki §6.1

Edit `wheels/docs/sprint4-wiki.md` §6.1 with:

- Brief description of the change (RepaintBoundary, sub-Consumer split,
  cacheExtent, addRepaintBoundaries=false, etc.).
- Embed the before/after screenshots:
  - `screenshots/microopt/jorge/before/browse-frame-chart.png`
  - `screenshots/microopt/jorge/after/browse-frame-chart.png`
  - …same for category-listing.
- Paste the before/after numeric table.
- One sentence with the bottom-line gain (e.g. *"median frame build dropped
  from 22 ms to 11 ms, P95 from 48 ms to 19 ms; janky frames reduced from
  14/300 to 2/300"*).

## Why this target and not RidesSearchScreen

The F-J-8 issue originally targeted `RidesSearchScreen`. We pivoted because:

- Seeding 100+ rides into Firestore for the demo would have introduced
  fake data visible to the rest of the team's demos.
- `HelpCenterScreen` is a clear-cut owned-by-Jorge feature with seedable
  data we already control, so the change is reproducible by graders.
- The optimization techniques (RepaintBoundary, sub-Consumer split,
  cacheExtent) are the same set the original issue listed; the screen is
  different but the rubric requirements are met identically.

This rationale also goes in the Wiki §6.1 under "Target pivot".
