# Sprint 4 – App Implementation, BQs, Micro-optimization

This wiki documents Sprint 4 of the Wheels project. It builds on Sprint 2 (initial implementation) and Sprint 3 (reliability strategies), and covers the new features, new business questions, new views, micro-optimization work, and the consolidated value proposition.

> **How to read this document.** Each table tags features/BQs/views/strategies with their original sprint (**S2**, **S3**, or **S4**) so the grader can verify Sprint 4 deltas without re-reading prior wikis.

---

## 0. Team and Platform Distribution

Each Flutter member ships **one Sprint 4 feature** that covers **all four strategy columns** (multi-threading, local storage, caching, eventual connectivity) and delivers **two new views**. The Kotlin team mirrors this structure for their three features.

| Member | Platform | Sprint 4 feature | Views (S4, ×2) | New BQ (S4) | Micro-optimization target |
| --- | --- | --- | --- | --- | --- |
| Jorge Bustamante | Flutter | **Help Center & FAQ** | `HelpCenterScreen`, `HelpArticleScreen` | BQ-J4 (Type 3) — % of help sessions resolved without contacting support | `RidesSearchScreen` list rendering |
| Martín Del Gordo | Flutter | **Saved Destinations & Trip Planner** | `SavedDestinationsScreen`, `SavedDestinationDetailScreen` | BQ-M4 (Type 4) — Most-saved destinations across users | `DashboardScreen` cold start + first frame |
| Raúl Insuasty | Flutter | **Smart Notifications & Inbox** | `NotificationInboxScreen`, `NotificationPreferencesScreen` | BQ-R4 (Type 3) — Notification open-rate within 1 h by category | `ReviewsScreen` image-heavy lists |
| Mauricio Urrego | Kotlin | **TODO** | **TODO ×2** | **TODO** | **TODO** |
| Samara Martínez | Kotlin | **TODO** | **TODO ×2** | **TODO** | **TODO** |
| Andrés Neira | Kotlin | **TODO** | **TODO ×2** | **TODO** | **TODO** |

> **Coverage matrix per Flutter feature.** Each row below collects ≥1 strategy in every column — so the grader can verify any of the three features against any single column.

| Member / Feature | Multi-threading | Local Storage | Caching | EvC |
| --- | --- | --- | --- | --- |
| **Jorge — Help Center & FAQ** | `Isolate.spawn` for fuzzy search index + `Stream` for live FAQ updates + `Future.wait` + `async/await` | Hive (articles + bookmarks) + SharedPreferences (last query) | `MemoryLruCache<String, HelpArticle>` cap = 30 + `cached_network_image` for article images | Full offline browse once seeded, queued feedback + bookmarks reconciled on reconnect |
| **Martín — Saved Destinations** | `Isolate.spawn` for haversine distance batch + `Stream` from sqflite watch + `Future.wait` + `compute()` for JSON batches | SQLite (`saved_destinations`) + SharedPreferences (last quick-pick) | `LinkedHashMap<String, double>` cap = 64 LRU for distances + `cached_network_image` for thumbnails | Offline-first writes (`pending_sync=1`), `SavedDestinationsSyncWorker` flushes on reconnect |
| **Raúl — Smart Notifications** | Firestore `Stream` + `Isolate.spawn` for categorization + `Future.wait` + `async/await` | Hive (`notifications_inbox_box_v1`) + SharedPreferences (preferences/quiet hours) | `MemoryLruCache<String, NotificationDetail>` cap = 50 + `cached_network_image` for avatars | Offline browse from Hive, queued mark-read/archive, reconcile on reconnect |

---

## 1. Value Proposition (Sprint 4 — Wiki §2, max 10 pts)

> Draft justification. Edit before delivery if any number changes.

Wheels is a campus-first ride-sharing platform for Uniandes that turns daily commuting between students into a safer, cheaper, and more predictable experience. The value proposition crystallized after the Sprint 2/3 implementation work and is grounded in four pillars that map directly to features and business questions already shipped:

1. **Trusted community over open marketplace.** Through institutional login and the backend-driven Driver Reliability Score (S2, S3), the app filters interactions to verified peers and penalizes unreliable behavior automatically. BQs Q6 (cancellations), Q10 (post-ride rating adoption), and the Sprint 3 BQ on ride open-time give us measurable trust signals.
2. **Resilient by design.** Sprint 3 added eventual-connectivity strategies on every critical screen (search, details, dashboard, payment, create-ride, active-ride, wallet, withdrawal). Users can plan and recover work even on the unreliable Uniandes mobile networks — competitors in this niche generally fail closed.
3. **Insight-driven product loop.** A single analytics pipeline (Firestore → Power Query → Looker Studio) powers all BQs in a unified dashboard. This lets us tune ranking, notifications, and reliability scoring with live behavioral evidence instead of guesswork (S2 BQs answer "who", S3 BQs answer "when/how often", S4 BQs answer "what users prefer and what monetizes").
4. **Sticky engagement and reduced churn.** Sprint 4 adds three engagement multipliers — *Help Center & FAQ* (Jorge) so onboarding friction stops at the first article instead of at a support ticket, *Saved Destinations* (Martín) so frequent routes become one-tap actions, and *Smart Notifications & Inbox* (Raúl) so users don't lose context across sessions. Together they raise repeat-use without raising operational cost.

**Revenue model (planned, not yet billed):** transactional commission on completed paid rides (already routed via Mercado Pago), and a future *Wheels Pro* tier for drivers that unlocks deeper earnings analytics and notification targeting. Collected data so far (rides, cancellations, ratings, search queries, saved destinations, notification open events, help-session resolution) is the moat that keeps the loop honest.

---

## 2. Sprint 4 Deliverable Overview

| Wiki section | Sprint 4 requirement | Owner | Status |
| --- | --- | --- | --- |
| §1 Value proposition | 10 pts | Jorge (draft) | ⚠️ Draft, review with team |
| §3 Sprint 4 features (6 features, each with ≥2 views and 4-column coverage) | 80 pts | All members | 🔲 Flutter spec'd, Kotlin TODO |
| §4 Sprint 4 new views (≥6 across platforms) | 15 pts | All members | 🔲 Flutter spec'd, Kotlin TODO |
| §5 Sprint 4 new BQs (6 new BQs in one Looker dashboard) | 20 pts | All members + Martín (pipeline) | 🔲 Flutter spec'd, Kotlin TODO |
| §6 Micro-optimization (profiler before/after) | 40 pts | All members | 🔲 To execute |
| §9 Consolidated feature list (S2 + S3 + S4) | bloqueante | Jorge | ⚠️ Drafted |
| §10–§14 Consolidated EvC / Local Storage / Multi-threading / Caching | bloqueante | Jorge | ⚠️ Drafted |
| §15 Distribution (APK + Firebase) | bloqueante | TBD | 🔲 TODO |
| §16 Ethics video | 46 pts | TBD | 🔲 TODO |

---

## 3. Sprint 4 — New Features (max 80 pts)

Each Flutter feature below exercises **all four** strategy columns (Multi-threading, Local Storage, Caching, EvC) and ships **two new views**.

### 3.1 Flutter (Jorge, Martín, Raúl)

#### Feature F-S4-1 — Help Center & FAQ (Jorge)

**New views (×2).**
- `lib/features/help/presentation/screens/help_center_screen.dart` — search bar (debounced 300 ms), category grid (Account, Payments, Rides, Safety, Drivers), "Recently viewed" strip, "Most helpful" list, and an explicit "Contact support" CTA.
- `lib/features/help/presentation/screens/help_article_screen.dart` — article body with embedded images, "was this helpful? 👍 / 👎" feedback row, "Related articles" list, and a back-to-search action.

**What it does and why it is new.** No FAQ existed before Sprint 4. The Help Center reduces support load and acts as the entry point for BQ-J4 (proportion of help sessions that resolve without escalating to "contact support"). It is fully offline-readable once seeded.

##### Multi-threading strategy (rubric: Stream 5 + Isolates 10 + Future 5 + Future+handler+async/await 10 = 30 pts)

- **`Isolate.spawn`** builds a fuzzy search index over all cached articles on first launch (or when the article corpus changes); subsequent searches dispatch the query into the isolate and receive a ranked list of `articleId`s. The isolate exchanges `SendPort`/`ReceivePort` messages with the UI isolate; only the resulting score-sorted ids cross the boundary.
- **`Stream<List<HelpArticle>>`** subscribed to Firestore `help_articles` for live FAQ updates and editorial fixes.
- **`Future.wait`** loads in parallel: cached articles (Hive), user bookmarks (Hive), categories (Hive), and last search query (SharedPreferences).
- **`async/await` + per-source handler** wraps individual article fetches and feedback submissions, surfacing error/loading state to the UI without coupling sources.

##### Local storage strategy (rubric: Hive 5 + SharedPreferences 5 = 10 pts)

- **Hive box `help_articles_box_v1`** stores the article corpus (titles, slugs, bodies in Markdown, category, last-updated timestamp, image URLs). Indexed in-memory by category and slug.
- **Hive box `help_bookmarks_box_v1`** stores user bookmarks (article id, savedAt, `pending_sync` flag).
- **Hive list `pending_help_feedback`** queues offline "was this helpful?" votes.
- **SharedPreferences key `help_last_query:<userId>`** stores the last typed query so the user resumes where they left off.

##### Caching strategy (rubric: LRU 10 + image library 5 = 15 pts)

- **`MemoryLruCache<String, HelpArticle>`** from `lib/shared/cache/memory_lru_cache.dart` with `capacity = 30`. Justification: a help session typically visits 3–8 articles; 30 keeps the entire session hot across back-navigations and any related-article taps without bloating memory. `get()` promotes to most-recent; `put()` evicts least-recent when over capacity. Invalidation: any Firestore update for an article id evicts the entry; on re-read the fresh body is re-cached.
- **`cached_network_image`** for embedded article images with `memCacheWidth: 800` and a `placeholder` widget for graceful loading.

##### Eventual connectivity strategy

- Once the article corpus is seeded into Hive, the entire Help Center is **fully browsable offline** (search, read, related articles, bookmarks).
- "Was this helpful?" votes and new bookmarks are written to local Hive immediately and queued into `pending_help_feedback` / `pending_help_bookmarks`; `HelpFeedbackSyncWorker` flushes them on reconnect with retry-with-backoff.
- Article updates from the Firestore stream merge into Hive only when online; offline reads stay on the last known good version.

##### Files to create

- `lib/features/help/domain/entities/help_article.dart`
- `lib/features/help/domain/entities/help_category.dart`
- `lib/features/help/domain/entities/help_feedback.dart`
- `lib/features/help/data/models/help_article_model.dart`
- `lib/features/help/data/datasources/help_local_datasource.dart` (Hive)
- `lib/features/help/data/datasources/help_remote_datasource.dart` (Firestore)
- `lib/features/help/data/datasources/help_preferences_local_datasource.dart` (SharedPreferences)
- `lib/features/help/data/cache/help_articles_lru_cache.dart`
- `lib/features/help/data/isolates/help_search_index_isolate.dart`
- `lib/features/help/data/sync/help_feedback_sync_worker.dart`
- `lib/features/help/data/seed/help_articles_seed.dart` (initial corpus of ~20 markdown articles)
- `lib/features/help/data/repositories/help_repository_impl.dart`
- `lib/features/help/presentation/providers/help_providers.dart`
- `lib/features/help/presentation/screens/help_center_screen.dart`
- `lib/features/help/presentation/screens/help_article_screen.dart`
- `lib/features/help/presentation/widgets/help_category_card.dart`
- `lib/features/help/presentation/widgets/help_article_tile.dart`
- Register Hive boxes in `lib/shared/storage/app_hive.dart`
- Add `cached_network_image` to `pubspec.yaml`
- Add routes in `lib/router/app_routes.dart` + `app_router.dart`

---

#### Feature F-S4-2 — Saved Destinations & Trip Planner (Martín)

**New views (×2).**
- `lib/features/saved_destinations/presentation/screens/saved_destinations_screen.dart` — CRUD list of favorite destinations sorted by recency / use count; quick-add from current location; swipe-to-delete.
- `lib/features/saved_destinations/presentation/screens/saved_destination_detail_screen.dart` — single destination view with usage stats, route preview, and an action button that prefills `CreateRideScreen` / `RidesSearchScreen`.

**Multi-threading.** `Isolate.spawn` for haversine batch + `Stream<List<SavedDestination>>` from local repo + `Future.wait` bootstrap + `compute()` for sync-batch JSON.
**Local storage.** SQLite table `saved_destinations` with indexes + `UNIQUE(user_id, address)`; SharedPreferences for last quick-pick.
**Caching.** `LinkedHashMap<String, double>` cap = 64 LRU keyed by `<destinationId>:<100m-bucket>`; `cached_network_image` for thumbnails.
**EvC.** Offline-first writes with `pending_sync = 1`; `SavedDestinationsSyncWorker` flushes to Firestore on reconnect (LWW by `last_used_at`).

---

#### Feature F-S4-3 — Smart Notifications & Inbox (Raúl)

**New views (×2).**
- `lib/features/notifications/presentation/screens/notification_inbox_screen.dart` — categorized list, filter chips, swipe-to-mark-read, badge, infinite scroll.
- `lib/features/notifications/presentation/screens/notification_preferences_screen.dart` — per-category opt-in/opt-out, quiet-hours, push vs in-app toggle.

**Multi-threading.** Firestore `Stream<NotificationEvent>` + `Isolate.spawn` for categorization when inbox > 200 + `Future.wait` for bootstrap + `async/await` per-source for mutations.
**Local storage.** Hive `notifications_inbox_box_v1` (last 200), Hive list `pending_notification_actions`, SharedPreferences `notification_preferences:<userId>`.
**Caching.** `MemoryLruCache<String, NotificationDetail>` cap = 50 + `cached_network_image` for avatars (`memCacheWidth/Height = 96`).
**EvC.** Offline-first inbox read; queued mark-read/archive/snooze flushed by `NotificationActionsSyncWorker`; live `Stream` resumes on reconnect.

---

### 3.2 Kotlin (TODO — Mauricio, Samara, Andrés)

| ID | Member | Feature name | Views (×2) | EvC | MT | Local storage | Caching |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K-S4-1 | Mauricio | **TODO** | **TODO ×2** | **TODO** | **TODO** | **TODO** | **TODO** |
| K-S4-2 | Samara | **TODO** | **TODO ×2** | **TODO** | **TODO** | **TODO** | **TODO** |
| K-S4-3 | Andrés | **TODO** | **TODO ×2** | **TODO** | **TODO** | **TODO** | **TODO** |

> **Constraint for the Kotlin team.** Mirror the Flutter coverage: every Kotlin feature should also cover all four columns. Kotlin rubric preferences: multi-threading uses nested coroutines with `Dispatchers.IO` + `Dispatchers.Main`; local-storage prefers Room/SQLite (10 pts); caching prefers `LruCache`/`ArrayMap` with documented capacity/eviction (10 pts); image cache via Glide/Coil/Picasso (5 pts).

---

## 4. Sprint 4 — New Views (max 15 pts)

| ID | Platform | View | Member |
| --- | --- | --- | --- |
| V-S4-1 | Flutter | `HelpCenterScreen` | Jorge |
| V-S4-2 | Flutter | `HelpArticleScreen` | Jorge |
| V-S4-3 | Flutter | `SavedDestinationsScreen` | Martín |
| V-S4-4 | Flutter | `SavedDestinationDetailScreen` | Martín |
| V-S4-5 | Flutter | `NotificationInboxScreen` | Raúl |
| V-S4-6 | Flutter | `NotificationPreferencesScreen` | Raúl |
| V-S4-7..12 | Kotlin | **TODO** | Mauricio / Samara / Andrés (≥1 each) |

---

## 5. Sprint 4 — New Business Questions (max 20 pts)

All Sprint 4 BQs are powered by the same analytics pipeline used in Sprint 2/3 (Firestore → Power Query → Looker Studio) and visualized in the **same single Looker Studio dashboard**.

| ID | BQ | Type | Member | Implementation view | Data source |
| --- | --- | --- | --- | --- | --- |
| BQ-J4 | What proportion of Help Center sessions resolve without escalating to "contact support"? | 3 | Jorge | `HelpCenterScreen` footer banner + Looker tile | `help_events`: `help_session_started`, `help_article_viewed`, `help_contact_support_clicked` |
| BQ-M4 | Which destinations do users most frequently save as favorites? | 4 | Martín | `SavedDestinationsScreen` "Trending" section + Looker tile | `users/{uid}/saved_destinations` (collection group) |
| BQ-R4 | What proportion of in-app notifications are opened within 1 h, by category and time-of-day? | 3 | Raúl | Inbox header strip + Looker tile (stacked bar) | `notification_events`: `notification_sent`, `notification_opened` |
| BQ-K4-1..3 | **TODO** | TODO | Mauricio / Samara / Andrés | **TODO** | **TODO** |

**No overlap with prior sprints.** S2: new users/week (Jorge), peak time (Martín), cancellation rate (Andrés), rating adoption (Mauricio), top drivers (Raúl), frequent destinations of a user (Samara). S3: ride distribution by day/time (Martín, Raúl), feedback engagement (Mauricio), rides per day (Jorge), Rides-Near-Me weekly usage (Samara), ride open-time (Andrés). Sprint 4 touches new entities (help articles, saved destinations, notifications) and asks new aggregations.

---

## 6. Micro-optimization (max 40 pts)

Each Flutter member picks one existing screen (S2/S3), profiles it **before** any change, applies a focused optimization, profiles it **again**, and includes both screenshots + code snippets in this section. Use **Flutter DevTools → Performance** on a release build, on a real Android device.

### 6.1 Jorge — `RidesSearchScreen` list rendering

- Target: median frame ≤ 16 ms, P95 ≤ 25 ms, scrolling 100+ rides.
- Plan: `RepaintBoundary` per tile + `const` constructors + `provider.select` narrowed rebuild + `ListView.builder` with `itemExtent`.
- Deliverables: baseline screenshot, code diff, post-change screenshot, numeric improvement in this section.

### 6.2 Martín — `DashboardScreen` cold start

- Target: time-to-first-meaningful-paint on Dashboard.
- Plan: deferred non-critical providers via `addPostFrameCallback`, `precacheImage`, `RepaintBoundary`, `Selector` for the balance widget.
- Deliverables: cold-start trace before/after.

### 6.3 Raúl — `ReviewsScreen` image-heavy list

- Target: rasterizer time + memory while scrolling ~30 reviews.
- Plan: `cached_network_image` w/ `memCacheWidth/Height = 96` + `RepaintBoundary` + `const` star widget.
- Deliverables: rasterizer + memory before/after.

### 6.4 Mauricio / Samara / Andrés — TODO

| Member | Target screen | Strategy | Status |
| --- | --- | --- | --- |
| Mauricio | **TODO** | **TODO** | **TODO** |
| Samara | **TODO** | **TODO** | **TODO** |
| Andrés | **TODO** | **TODO** | **TODO** |

---

## 7. Sprint 4 — Existing Functionalities With Required Updates

Carry-over fixes from Viva-Voce 2/3 feedback:

- [ ] **TODO** — list any feedback received in S3 oral exam that requires re-implementation in S4.

---

## 8. Distribution — APK + Firebase App Distribution

> **Hard requirement.** Failure to deliver this on time = 0 in deliverable and oral exam.

- [ ] Build signed APK (`./gradlew assembleRelease` from `wheels/android/`).
- [ ] Firebase App Distribution invitation name pattern `isis3510-<team>-flutter-Sprint4`.
- [ ] Add TA gmails.
- [ ] Verify install on a real device.
- [ ] Trial user with usable seed data.

---

## 9. Consolidated Feature List (S2 + S3 + S4)

### Flutter

| № | Sprint | Feature | Description |
| - | --- | --- | --- |
| 1 | S2 | Trust and Fairness Score Calculation | Computes trust score from cancellations, punctuality, etc. |
| 2 | S2 | Register and login | Account creation and authentication. |
| 3 | S2 | Payment Gateway Integration (Mercado Pago) | External payment system for ride payments. |
| 4 | S3 | Resilient Ride Search Restoration | Restores last successful ride search offline. |
| 5 | **S4** | **Help Center & FAQ (Jorge)** | **Fully offline-readable knowledge base with isolate-based fuzzy search, Firestore Stream, LRU article cache, `cached_network_image`.** |
| 6 | **S4** | **Saved Destinations & Trip Planner (Martín)** | **SQLite-backed favorites with offline-first writes, deferred Firestore sync, isolate haversine batch, LRU distance cache.** |
| 7 | **S4** | **Smart Notifications & Inbox (Raúl)** | **Inbox + preferences with `Isolate.spawn` categorization, Firestore Stream, Hive + SharedPreferences, LRU detail cache, `cached_network_image`.** |

### Kotlin

| № | Sprint | Feature | Description |
| - | --- | --- | --- |
| 1..13 | S2/S3 | (see Sprint 3 wiki) | |
| 14 | **S4** | **TODO (Mauricio)** | **TODO** |
| 15 | **S4** | **TODO (Samara)** | **TODO** |
| 16 | **S4** | **TODO (Andrés)** | **TODO** |

---

## 10. Consolidated Business Questions (S2 + S3 + S4)

| № | Sprint | BQ | Type | Responsible |
| - | --- | --- | --- | --- |
| 1..12 | S2/S3 | (see Sprint 3 wiki) | | |
| **13** | **S4** | **BQ-J4. Help Center session resolution rate.** | **3** | **Jorge** |
| **14** | **S4** | **BQ-M4. Top saved destinations across users.** | **4** | **Martín** |
| **15** | **S4** | **BQ-R4. Notification open-rate within 1 h, by category and time-of-day.** | **3** | **Raúl** |
| **16..18** | **S4** | **TODO** | **TODO** | **Mauricio / Samara / Andrés** |

---

## 11. Consolidated Eventual Connectivity Strategies

| № | Sprint | Scenario | System response | Member |
| - | --- | --- | --- | --- |
| 1..21 | S2/S3 | (see Sprint 3 wiki) | | |
| **22** | **S4** | **No connectivity on Help Center** | **Full offline browsing from Hive; isolate search runs locally; feedback + bookmarks queued + flushed by `HelpFeedbackSyncWorker` on reconnect.** | **Jorge** |
| **23** | **S4** | **No connectivity on Help Article** | **Read from Hive; embedded images from `cached_network_image` cache.** | **Jorge** |
| **24** | **S4** | **No connectivity on Saved Destinations CRUD** | **Offline-first SQLite writes with `pending_sync = 1`; flushed by `SavedDestinationsSyncWorker` (LWW).** | **Martín** |
| **25** | **S4** | **No connectivity on Saved Destination Detail** | **Stats from local SQLite + cached ride history.** | **Martín** |
| **26** | **S4** | **No connectivity on Notification Inbox** | **Offline-first read; mark-read/archive/snooze queued; `NotificationActionsSyncWorker` flushes on reconnect.** | **Raúl** |
| **27** | **S4** | **No connectivity on Notification Preferences** | **SharedPreferences immediate; queued Firestore mirror sync.** | **Raúl** |
| **28..30** | **S4** | **TODO Kotlin** | **TODO** | **Mauricio / Samara / Andrés** |

---

## 12. Consolidated Local Storage Strategies

| № | Sprint | Platform | Strategy | Storage | Member |
| - | --- | --- | --- | --- | --- |
| 1..11 | S2/S3 | (see Sprint 3 wiki) | | | |
| **12** | **S4** | **Flutter** | **Help articles offline corpus** | **Hive (`help_articles_box_v1`)** | **Jorge** |
| **13** | **S4** | **Flutter** | **Help bookmarks** | **Hive (`help_bookmarks_box_v1`)** | **Jorge** |
| **14** | **S4** | **Flutter** | **Help last query** | **SharedPreferences (`help_last_query:<userId>`)** | **Jorge** |
| **15** | **S4** | **Flutter** | **Saved Destinations relational store** | **SQLite (`saved_destinations`)** | **Martín** |
| **16** | **S4** | **Flutter** | **Saved Destinations quick-pick** | **SharedPreferences (`saved_destinations_last_pick:<userId>`)** | **Martín** |
| **17** | **S4** | **Flutter** | **Notification inbox durable store** | **Hive (`notifications_inbox_box_v1`)** | **Raúl** |
| **18** | **S4** | **Flutter** | **Notification preferences** | **SharedPreferences (`notification_preferences:<userId>`)** | **Raúl** |
| **19** | **S4** | **Flutter** | **Notification pending actions queue** | **Hive list (`pending_notification_actions`)** | **Raúl** |
| **20..22** | **S4** | **Kotlin** | **TODO** | **TODO** | **Mauricio / Samara / Andrés** |

---

## 13. Consolidated Multi-threading and Asynchronous Processing

| № | Sprint | Platform | Strategy | Member |
| - | --- | --- | --- | --- |
| 1..8 | S2/S3 | (see Sprint 3 wiki) | | |
| **9** | **S4** | **Flutter** | **Help: `Isolate.spawn` fuzzy-search index** | **Jorge** |
| **10** | **S4** | **Flutter** | **Help: Firestore `Stream<List<HelpArticle>>`** | **Jorge** |
| **11** | **S4** | **Flutter** | **Help: `Future.wait` bootstrap + `async/await` per-source** | **Jorge** |
| **12** | **S4** | **Flutter** | **Saved Destinations: `Isolate.spawn` haversine batch** | **Martín** |
| **13** | **S4** | **Flutter** | **Saved Destinations: `Stream<List<SavedDestination>>` from local repo** | **Martín** |
| **14** | **S4** | **Flutter** | **Saved Destinations: `Future.wait` + `compute()` for sync batches** | **Martín** |
| **15** | **S4** | **Flutter** | **Notifications: Firestore `Stream<NotificationEvent>`** | **Raúl** |
| **16** | **S4** | **Flutter** | **Notifications: `Isolate.spawn` categorization at > 200 entries** | **Raúl** |
| **17** | **S4** | **Flutter** | **Notifications: `Future.wait` bootstrap + `async/await` per-source** | **Raúl** |
| **18..20** | **S4** | **Kotlin** | **TODO** | **Mauricio / Samara / Andrés** |

---

## 14. Consolidated Caching Strategies

| № | Sprint | Platform | Strategy | Data Structure | Member |
| - | --- | --- | --- | --- | --- |
| 1..7 | S2/S3 | (see Sprint 3 wiki) | | | |
| **8** | **S4** | **Flutter** | **Help article LRU cache** | **`MemoryLruCache<String, HelpArticle>` cap = 30, LRU, invalidation on Firestore update** | **Jorge** |
| **9** | **S4** | **Flutter** | **Help article image cache** | **`cached_network_image` `memCacheWidth = 800`** | **Jorge** |
| **10** | **S4** | **Flutter** | **Saved Destinations distance cache** | **`LinkedHashMap<String, double>` cap = 64 LRU, key `<destId>:<100m-bucket>`** | **Martín** |
| **11** | **S4** | **Flutter** | **Saved Destinations thumbnail cache** | **`cached_network_image` matched to render size** | **Martín** |
| **12** | **S4** | **Flutter** | **Notification detail LRU cache** | **`MemoryLruCache<String, NotificationDetail>` cap = 50, LRU, invalidation on read/archive** | **Raúl** |
| **13** | **S4** | **Flutter** | **Notification avatar image cache** | **`cached_network_image` `memCacheWidth/Height = 96`** | **Raúl** |
| **14..16** | **S4** | **Kotlin** | **TODO** | **TODO** | **Mauricio / Samara / Andrés** |

---

## 15. Sprint 4 — Repo Hygiene Checklist (process competence)

> **If these are missing, the deliverable scores 0 and no member can present the oral exam.**

- [ ] Sprint 4 milestone created in GitHub Issues.
- [ ] One issue per new feature, view, BQ, and micro-optimization task.
- [ ] Every issue assigned to its owner and tagged with the Sprint 4 milestone.
- [ ] Every Sprint 4 commit pushed via a PR (squash + merge), referencing its issue.
- [ ] Kanban board reflects the Sprint 4 issues (To Do / In Progress / Review / Done).
- [ ] All members make commits before the deadline.
- [ ] No commit after deadline (UTC equivalent: **2026-05-23 10:00 UTC**).
- [ ] PR `develop → main` opened after S4 work is merged, before deadline.

---

## 16. Ethics Video (max 46 pts)

- [ ] **TODO** — assign owner, define script, record, link here.

---

## 17. Repo Links

- Flutter: https://github.com/G06-ISIS3510-1/Flutter
- Kotlin: https://github.com/G06-ISIS3510-1/Kotlin

---

## 18. Contribution Table (Sprint 4)

| Member | Sprint 4 contributions |
| :--- | :--- |
| Jorge Bustamante | • Designed Sprint 4 plan and Wiki structure.<br>• Implemented **Help Center & FAQ** with Hive corpus + bookmarks + last-query SharedPreferences, `Isolate.spawn` fuzzy-search index, Firestore Stream, LRU article cache, `cached_network_image`.<br>• Implemented BQ-J4 (Type 3) end-to-end through the analytics pipeline.<br>• Delivered two new views: `HelpCenterScreen`, `HelpArticleScreen`.<br>• Micro-optimized `RidesSearchScreen` list rendering. |
| Martín Del Gordo | • Implemented **Saved Destinations & Trip Planner** with SQLite + SharedPreferences, offline-first writes, deferred Firestore sync, isolate distance batch, LRU distance cache, `cached_network_image`.<br>• Implemented BQ-M4 (Type 4) via the analytics pipeline.<br>• Delivered two new views: `SavedDestinationsScreen`, `SavedDestinationDetailScreen`.<br>• Micro-optimized `DashboardScreen` cold-start. |
| Raúl Insuasty | • Implemented **Smart Notifications & Inbox** with `Isolate.spawn` categorization, Firestore Stream, Hive + SharedPreferences, LRU detail cache, `cached_network_image`.<br>• Implemented BQ-R4 (Type 3) end-to-end through the analytics pipeline.<br>• Delivered two new views: `NotificationInboxScreen`, `NotificationPreferencesScreen`.<br>• Micro-optimized `ReviewsScreen` images. |
| Mauricio | **TODO** |
| Samara | **TODO** |
| Andrés | **TODO** |
