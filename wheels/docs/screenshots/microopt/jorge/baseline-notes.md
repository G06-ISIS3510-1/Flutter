# F-J-8 baseline notes — `before/`

Device: Samsung Galaxy S20 FE (SM G781B), Android 13, 120 Hz display
(frame budget = 8.33 ms). Build: `flutter run --profile`. Engine: Impeller.

## Browse view scroll

| Metric                        | Value     |
| ----------------------------- | --------- |
| FPS average                   | 119 / 120 |
| Typical frame — UI build      | 0.1 ms    |
| Typical frame — paint         | 0.3 ms    |
| Typical frame — raster        | 3.7 ms    |
| **Worst frame raster (jank)** | **28.2 ms** (frame 656, 3.4× over budget) |
| Janky frames in 5-s scroll    | 1 visible spike (frame 656) |

Screenshots:

- `before/browse-frame-chart.png` — full timeline view with jank spike highlighted
- `before/browse-frame-analysis.png` — frame 656 detail showing "Raster Jank Detected"

## Category listing scroll

| Metric                        | Value     |
| ----------------------------- | --------- |
| FPS average                   | 120 / 120 |
| Typical frame — UI build      | < 0.1 ms  |
| Typical frame — layout        | 0.1 ms    |
| Typical frame — paint         | < 0.1 ms  |
| **Worst frame raster (jank)** | **9.6 ms** (frame 1520, 1.15× over budget) |
| Janky frames in 5-s scroll    | ~3 small spikes (frames 1520, ~1534, ~1544) |

Screenshots:

- `before/category-frame-chart.png` — full timeline (frames 1858–1893 in capture 1, 1512–1546 with jank in capture 2)
- `before/category-frame-analysis.png` — frame 1520 detail with "Raster Jank Detected"

## Search results scroll

*(pending capture)*

## Notes / observations

- The browse view's worst-case raster (28.2 ms) is far more painful than the
  category listing's (9.6 ms). That is exactly what we expected: the browse
  view is a monolithic `ListView` with category grid + horizontal recently-
  viewed strip + most-helpful list + banner + CTA all rebuilding together.
- Category listing already uses `ListView.separated`, so the jank is smaller
  and concentrated on the long-list paint cost.
- Both scenarios have **plenty of headroom** in UI build (0.1 ms typical)
  and paint (0.3 ms typical). The bottleneck is **raster**. That is exactly
  what `RepaintBoundary` and `addRepaintBoundaries=false` are designed to
  address — they isolate which subtrees need to repaint per frame.
- 120 Hz display means our frame budget is 8.33 ms, not 16.67 ms. That
  makes the 28.2 ms spike look 2× worse than it would on a 60 Hz device.
  We will keep both reference values in the Wiki narrative.

## Reminder

Save the PNG files into this folder before applying the optimization. They
go into Wiki §6.1 and we need them as evidence of the baseline.
