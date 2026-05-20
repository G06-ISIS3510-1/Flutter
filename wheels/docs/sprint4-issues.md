# Sprint 4 — GitHub Issues (paste-ready)

Each block below maps 1:1 to a GitHub issue. **Milestone** for all of them: `Sprint 4`. **Project board column** starts at `To Do`.

Suggested labels to create once: `sprint-4`, `flutter`, `kotlin`, `feature`, `view`, `bq`, `micro-opt`, `docs`, `ops`, `ethics`.

Branch naming convention: `feature/<short-name>-#<issue-number>` (mirrors what S3 used in the repo).

---

## Team-wide

### T-S4-1 — Sprint 4 milestone + Kanban setup
**Labels:** `sprint-4`, `ops` — **Assignee:** Jorge

- [ ] Create the `Sprint 4` milestone in GitHub Issues (due date **2026-05-23 05:00 GMT-5**).
- [ ] Confirm Kanban columns: `To Do`, `In Progress`, `Review`, `Done`.
- [ ] Move all issues from this document into `To Do`.
- [ ] Assign each issue to its owner.
- [ ] Create labels once: `sprint-4`, `flutter`, `kotlin`, `feature`, `view`, `bq`, `micro-opt`, `docs`, `ops`, `ethics`.

### T-S4-2 — Sprint 4 Wiki committed and published
**Labels:** `sprint-4`, `docs` — **Assignee:** Jorge

- [ ] Commit `wheels/docs/sprint4-wiki.md` to `develop`.
- [ ] Copy contents into the GitHub Wiki page "Sprint 4" once Kotlin TODOs are filled.
- [ ] Verify §9–§14 reflect implemented strategies (no leftover Flutter TODO).
- [ ] Add screenshots referenced from §6 (micro-opt before/after) once they exist.

### T-S4-3 — Value proposition (Wiki §1)
**Labels:** `sprint-4`, `docs` — **Assignee:** Jorge (draft) + team review

- [ ] Team reviews the four pillars + revenue model.
- [ ] Add concrete data points (BQ tile screenshots) once dashboards are ready.
- [ ] Cross-check that the value proposition references actual S2/S3/S4 features (no aspirational claims).

### T-S4-4 — Firebase App Distribution build + invites
**Labels:** `sprint-4`, `ops` — **Assignee:** TBD

- [ ] Build signed APK (`./gradlew assembleRelease` from `wheels/android/`).
- [ ] Upload to Firebase App Distribution.
- [ ] Invite TAs using `isis3510-<team>-flutter-Sprint4`.
- [ ] Verify install on a real device.
- [ ] Seed trial user with ≥ 3 rides, 1 payment, 5 notifications, 3 saved destinations, full help corpus.

### T-S4-5 — Ethics video Sprint 4
**Labels:** `sprint-4`, `ethics` — **Assignee:** TBD

- [ ] Define script, record, publish, add link to Wiki §16.

### T-S4-6 — Looker Studio shared dashboard with all S4 BQs
**Labels:** `sprint-4`, `bq` — **Assignee:** Martín (pipeline) + Jorge / Raúl QA

- [ ] Add BQ-J4, BQ-M4, BQ-R4 tiles to the same shared dashboard as S2/S3.
- [ ] Add Kotlin BQ tiles once delivered.
- [ ] Each tile reads via Power Query (no manual CSV).

---

## Flutter — Jorge — Help Center & FAQ

### F-J-1 — [feature] Help Center scaffolding + Hive boxes
**Labels:** `sprint-4`, `flutter`, `feature`
**Branch:** `feature/help-center-#<n>`

- [ ] Add `cached_network_image` and `flutter_markdown` to `wheels/pubspec.yaml`; `flutter pub get`.
- [ ] Create folder tree `lib/features/help/{domain/{entities},data/{models,datasources,cache,isolates,sync,seed,repositories},presentation/{providers,screens,widgets}}`.
- [ ] Register Hive boxes in `lib/shared/storage/app_hive.dart`: `helpArticles = help_articles_box_v1`, `helpBookmarks = help_bookmarks_box_v1`.
- [ ] Register queues `pending_help_feedback`, `pending_help_bookmarks`.
- [ ] Entities `HelpArticle`, `HelpCategory`, `HelpFeedback`.
- [ ] `HelpArticleModel` with `toJson`/`fromJson` + `version` field.
- [ ] Seed file with ~20 markdown articles across 5 categories (Account, Payments, Rides, Safety, Drivers).
- [ ] Seeding is idempotent (skip if box not empty).
- [ ] `flutter analyze` clean; Hive bootstrap test passes.

### F-J-2 — [feature] Help local datasource + LRU cache + repository
**Labels:** `sprint-4`, `flutter`, `feature`, `caching`

Depends on F-J-1.

- [ ] `help_local_datasource.dart` exposes `Stream<List<HelpArticle>>` via `StreamController`.
- [ ] `help_preferences_local_datasource.dart` for `help_last_query:<userId>`.
- [ ] `help_articles_lru_cache.dart` wraps `MemoryLruCache<String, HelpArticle>` cap = 30, with `///` doc explaining capacity and invalidation.
- [ ] `help_remote_datasource.dart` returns Firestore stream.
- [ ] `help_repository_impl.dart` layered reads (LRU → Hive → remote), writes update Hive + LRU.
- [ ] Unit tests: LRU eviction, invalid Hive payload clears itself, layered read order.

### F-J-3 — [feature] Fuzzy-search isolate
**Labels:** `sprint-4`, `flutter`, `feature`, `multi-threading`

Depends on F-J-2.

- [ ] `help_search_index_isolate.dart` long-lived isolate via `Isolate.spawn`, receives corpus once, handles ranked queries via `SendPort`/`ReceivePort`.
- [ ] Ranking: normalized Levenshtein + token overlap; returns ≤ 20 article ids.
- [ ] Respawns when corpus changes.
- [ ] Only score-sorted ids cross the boundary.
- [ ] Unit test for known small corpus.

### F-J-4 — [view] `HelpCenterScreen`
**Labels:** `sprint-4`, `flutter`, `view`

Depends on F-J-3.

- [ ] New route in router; reachable from profile drawer ("Help Center" entry).
- [ ] Top search bar (debounced 300 ms), category grid (5 cards), "Recently viewed" strip (LRU-driven), "Most helpful" list, "Contact support" CTA.
- [ ] Loading / empty / error states via `AsyncValue.when`.
- [ ] BQ-J4: log `help_session_started` on first frame; log `help_contact_support_clicked` on CTA tap.
- [ ] Manual QA fully offline.

### F-J-5 — [view] `HelpArticleScreen`
**Labels:** `sprint-4`, `flutter`, `view`

Depends on F-J-4.

- [ ] Body rendered with `flutter_markdown`.
- [ ] Embedded images via `cached_network_image` (`memCacheWidth: 800`, placeholder).
- [ ] "Was this helpful? 👍 / 👎" → Hive immediate + enqueue `pending_help_feedback`.
- [ ] Related-articles list (3 from same category).
- [ ] Bookmark icon toggles entry in `help_bookmarks_box_v1`.
- [ ] BQ-J4: log `help_article_viewed` with `{ article_id, category, session_id }`.

### F-J-6 — [feature] `HelpFeedbackSyncWorker` (EvC)
**Labels:** `sprint-4`, `flutter`, `feature`, `eventual-connectivity`

- [ ] Listens to `connectivityStatusProvider`.
- [ ] On online transition, drains `pending_help_feedback` + `pending_help_bookmarks` to Firestore.
- [ ] Idempotent retry with exponential backoff (max 3 retries).
- [ ] Logs flush events.
- [ ] Unit test simulating offline → online.

### F-J-7 — [bq] BQ-J4 + Looker tile
**Labels:** `sprint-4`, `flutter`, `bq`

**BQ-J4 (Type 3):** *What proportion of Help Center sessions resolve without escalating to "contact support"?*

`resolved_rate = 1 - count(help_contact_support_clicked) / count(help_session_started)`

App:
- [ ] Events `help_session_started`, `help_article_viewed`, `help_contact_support_clicked` write to Firestore `help_events` with `userId`, `sessionId`, timestamp.
- [ ] `HelpCenterScreen` footer banner shows current-week `resolved_rate`.

Pipeline:
- [ ] Power Query weekly rollup from `help_events`.
- [ ] Single tile on the **shared Looker dashboard**: 8-week trend + current-week KPI.
- [ ] Same number on app banner AND Looker tile during Viva-Voce.

### F-J-8 — [micro-opt] `RidesSearchScreen` list rendering
**Labels:** `sprint-4`, `flutter`, `micro-opt`

- [ ] Baseline: DevTools Performance, 5-second scroll, ~100 results. Screenshot.
- [ ] Apply: `RepaintBoundary` per tile + `const` + `provider.select` + `ListView.builder` with `itemExtent`.
- [ ] Post-change: same scroll, screenshot.
- [ ] Record median + P95 frame build time before/after.
- [ ] Commit screenshots to `wheels/docs/screenshots/microopt/jorge/`.
- [ ] Wiki §6.1 updated with screenshots, diff snippet, numeric improvement.

---

## Flutter — Martín — Saved Destinations & Trip Planner

### F-M-1 — [feature] Saved Destinations scaffolding + SQLite schema
**Labels:** `sprint-4`, `flutter`, `feature`
**Branch:** `feature/saved-destinations-#<n>`

- [ ] Folder tree `lib/features/saved_destinations/...`.
- [ ] SQLite table `saved_destinations` per Wiki §3.1 F-S4-2.
- [ ] Indexes on `(user_id, last_used_at DESC)` and `(user_id, use_count DESC)`.
- [ ] `UNIQUE(user_id, address)` constraint.
- [ ] Hook into ride-history DB helper or open `wheels_saved.db`.
- [ ] Versioned migration script.

### F-M-2 — [feature] Distance batch isolate + LRU distance cache
**Labels:** `sprint-4`, `flutter`, `feature`, `multi-threading`, `caching`

- [ ] `distance_batch_isolate.dart` — `Isolate.spawn` returns `Map<destId, distanceKm>`.
- [ ] `saved_destinations_distance_cache.dart` — `LinkedHashMap<String, double>` cap 64, LRU; key `<destId>:<bucketLatLng>` with 100 m grid.
- [ ] Unit test for cache eviction.

### F-M-3 — [view] `SavedDestinationsScreen`
**Labels:** `sprint-4`, `flutter`, `view`

- [ ] List with sort toggle (recency / use count).
- [ ] Add-from-current-location FAB.
- [ ] Swipe-to-delete with undo snackbar.
- [ ] Empty state with CTA.
- [ ] Drop `SavedDestinationsChip` into `create_ride_screen.dart` and `rides_search_screen.dart`.

### F-M-4 — [view] `SavedDestinationDetailScreen`
**Labels:** `sprint-4`, `flutter`, `view`

- [ ] Usage stats: last 5 visits, total ride count, average price (local SQLite + ride history).
- [ ] Small route preview (static maps or local placeholder offline).
- [ ] "Create ride here" / "Search rides here" CTAs prefill respective screens.

### F-M-5 — [feature] `SavedDestinationsSyncWorker` (EvC)
**Labels:** `sprint-4`, `flutter`, `feature`, `eventual-connectivity`

- [ ] Drains `pending_sync = 1` rows to `users/{uid}/saved_destinations`.
- [ ] Writes back `remote_id`, sets `pending_sync = 0`.
- [ ] Last-write-wins by `last_used_at`.
- [ ] Idempotent retry with exponential backoff.

### F-M-6 — [bq] BQ-M4 Top saved destinations
**Labels:** `sprint-4`, `flutter`, `bq`

**BQ-M4 (Type 4):** *Which destinations are most frequently saved as favorites across users?*

- [ ] Power Query reads `users/{uid}/saved_destinations` collection group.
- [ ] Groups by normalized address (lowercase + trim + remove punctuation).
- [ ] Counts distinct user_ids per address; top 10.
- [ ] Looker tile shows horizontal bar chart on shared dashboard.
- [ ] `SavedDestinationsScreen` "Trending on campus" section reads the same aggregation.

### F-M-7 — [micro-opt] `DashboardScreen` cold start
**Labels:** `sprint-4`, `flutter`, `micro-opt`

- [ ] Baseline cold-start trace for first frame. Screenshot.
- [ ] Apply: deferred non-critical providers (`addPostFrameCallback`), `precacheImage`, `RepaintBoundary`, `Selector`.
- [ ] Post-change trace.
- [ ] Wiki §6.2 updated.

---

## Flutter — Raúl — Smart Notifications & Inbox

### F-R-1 — [feature] Notifications scaffolding + Hive boxes
**Labels:** `sprint-4`, `flutter`, `feature`
**Branch:** `feature/notifications-inbox-#<n>`

- [ ] Folder tree `lib/features/notifications/...` (extend existing scaffold).
- [ ] Register Hive box `notifications_inbox_box_v1` and list `pending_notification_actions`.
- [ ] Add SharedPreferences key `notification_preferences:<userId>`.
- [ ] `NotificationDetail` entity + versioned JSON model.

### F-R-2 — [feature] Notification LRU cache + categorize isolate
**Labels:** `sprint-4`, `flutter`, `feature`, `multi-threading`, `caching`

- [ ] `notifications_lru_cache.dart` — `MemoryLruCache<String, NotificationDetail>` cap 50; documented capacity + invalidation.
- [ ] `notifications_categorize_isolate.dart` — `Isolate.spawn` groups inbox by category, sorts by recency, computes unread counts; triggered when inbox > 200.
- [ ] Unit tests for cache eviction + isolate output ordering.

### F-R-3 — [view] `NotificationInboxScreen`
**Labels:** `sprint-4`, `flutter`, `view`

- [ ] Category filter chips (All / Ride / Payment / System / Promo).
- [ ] Swipe to mark-read / archive.
- [ ] Avatar via `cached_network_image` (`memCacheWidth: 96`).
- [ ] Header strip shows BQ-R4 KPI ("Open-rate this week: XX%").
- [ ] Infinite scroll (50-batch lazy load from Hive).
- [ ] Manual QA fully offline.

### F-R-4 — [view] `NotificationPreferencesScreen`
**Labels:** `sprint-4`, `flutter`, `view`

- [ ] Per-category toggle (in-app / push / both / off).
- [ ] Quiet-hours range picker (e.g., 22:00 → 07:00).
- [ ] Edits update SharedPreferences immediately + queue Firestore mirror.
- [ ] Restore-defaults button.

### F-R-5 — [feature] `NotificationActionsSyncWorker` (EvC)
**Labels:** `sprint-4`, `flutter`, `feature`, `eventual-connectivity`

- [ ] Drains `pending_notification_actions` to Firestore on reconnect.
- [ ] Resumes live `Stream`.
- [ ] Reconciles in-flight inbound notifications from the offline window.

### F-R-6 — [bq] BQ-R4 Notification open-rate
**Labels:** `sprint-4`, `flutter`, `bq`

**BQ-R4 (Type 3):** *What proportion of in-app notifications are opened within 1 h, by category and time-of-day?*

`open_rate(category, hour_bucket) = count(notification_opened where openedAt - deliveredAt <= 1h) / count(notification_sent)`

- [ ] App writes `notification_sent` and `notification_opened` to `notification_events`.
- [ ] Power Query rollup by category × hour-bucket.
- [ ] Looker tile: stacked bar per category over the day.

### F-R-7 — [micro-opt] `ReviewsScreen` image-heavy list
**Labels:** `sprint-4`, `flutter`, `micro-opt`

- [ ] Baseline: rasterizer + memory while scrolling ~30 reviews. Screenshot.
- [ ] Apply: `cached_network_image` with `memCacheWidth/Height: 96`, `RepaintBoundary`, `const` star widget.
- [ ] Post-change snapshot.
- [ ] Wiki §6.3 updated.

---

## Kotlin — placeholders (Mauricio / Samara / Andrés)

> Each Kotlin member must also have ≥ 1 of: MT / LS / Cache / EvC.

### K-MA-1..3 — [feature/bq/micro-opt] **TODO Mauricio**
### K-SA-1..3 — [feature/bq/micro-opt] **TODO Samara**
### K-AN-1..3 — [feature/bq/micro-opt] **TODO Andrés**

(One issue per row above. Body to be filled by each member when they pick a topic.)

---

## Summary count

- Team-wide: 6 issues (T-S4-1..T-S4-6).
- Flutter — Jorge: 8 issues (F-J-1..F-J-8).
- Flutter — Martín: 7 issues (F-M-1..F-M-7).
- Flutter — Raúl: 7 issues (F-R-1..F-R-7).
- Kotlin placeholders: 9 issues.
- **Total: 37 issues for Sprint 4.**

> Reminder: every commit must reference an issue (`Refs #<n>`), every PR squash-merged into `develop`, Kanban must move. No commits after **2026-05-23 05:00 GMT-5**.
