# Wheels Offline Persistence and Eventual Connectivity Guide

## Purpose

This document explains the offline-capable and eventual-connectivity-related behaviors currently implemented in the Flutter application. It is intended to serve as a practical engineering reference for:

- teammates who need to understand the current reliability design,
- reviewers who want to know how offline behavior works,
- future contributors who may extend the same flows,
- QA members validating behavior under unstable or unavailable connectivity.

The document is written from the perspective of the current repository state and focuses on the implementation actually present in `lib/`.

## Scope

This guide covers:

- eventual connectivity concepts used by the app,
- the local persistence mechanisms added for offline-capable features,
- the current storage boxes and cache keys used by Hive and SharedPreferences,
- the user-facing flows for:
  - `CreateRideScreen`
  - `ActiveRideScreen`
  - `WalletScreen`
  - `WithdrawalRequestScreen`
  - `RideDetailsScreen`
  - `RidesSearchScreen`
- the supporting tests added for local cache and persistence behavior,
- tradeoffs, limitations, and extension points.

This guide does not attempt to document every feature in the application. It only covers the sections that are relevant to resilience, local persistence, cached reads, deferred synchronization, and related validation.

## High-Level Design Goals

The offline and eventual connectivity work in Wheels was designed around the following goals:

- prevent users from losing work when the network disappears,
- allow the app to continue reading useful information when the backend is temporarily unavailable,
- make synchronization behavior explicit instead of silent,
- avoid unsafe optimistic behavior in sensitive flows such as withdrawals,
- keep local persistence simple and inspectable,
- maintain compatibility with the existing Feature-First Clean Architecture.

## Conceptual Model

The app uses a mix of four complementary strategies:

1. **Online-first with cached fallback**
   - The app first tries to load fresh remote data.
   - If the network is unavailable or the request fails, it attempts to restore the last known snapshot stored locally.

2. **Offline draft persistence**
   - Form-like flows store the user input locally while the user edits fields.
   - If the app closes or connectivity disappears, the user can recover the in-progress data later.

3. **Deferred synchronization**
   - Some actions are captured locally and retried later rather than being lost.
   - This is used when the action is important but small enough to defer safely.

4. **Cache invalidation on decode failure**
   - If a persisted JSON payload cannot be decoded, the app removes it.
   - This prevents corrupted local data from repeatedly breaking the same screen.

## Architectural Context

The project follows a pragmatic Feature-First Clean Architecture:

- `presentation/`
  - screens
  - providers
  - widgets
- `domain/`
  - entities
  - repository contracts
- `data/`
  - models
  - datasources
  - repository implementations

The eventual connectivity work follows the same structure:

- persistence models live in `data/models/`,
- persistence adapters live in `data/datasources/`,
- screens orchestrate the behavior,
- providers expose datasources where needed,
- the storage bootstrap happens in shared infrastructure.

## Storage Technologies

The app currently uses a combination of:

- **Hive**
  - used for structured local cache and draft storage,
  - stores JSON-encoded string snapshots in named boxes.

- **SharedPreferences**
  - used in existing cache flows and legacy compatibility paths,
  - still present in search cache and ride details legacy read path.

- **In-memory LRU cache**
  - used for ride details,
  - reduces repeated parsing and storage access during short-lived navigation cycles.

## Current Storage Inventory

### Hive boxes

Defined in:

- `lib/shared/storage/app_hive.dart`

Current boxes:

| Box constant | Box name |
| --- | --- |
| `AppHiveBoxes.rideDetailsCache` | `ride_details_cache_box_v1` |
| `AppHiveBoxes.dashboardCache` | `dashboard_cache_box_v1` |
| `AppHiveBoxes.withdrawalRequestDrafts` | `withdrawal_request_drafts_box_v1` |
| `AppHiveBoxes.activeRidePendingActions` | `active_ride_pending_actions_box_v1` |
| `AppHiveBoxes.walletSummaryCache` | `wallet_summary_cache_box_v1` |
| `AppHiveBoxes.createRideDrafts` | `create_ride_drafts_box_v1` |

### Shared keys

Also defined in:

- `lib/shared/storage/app_hive.dart`

Current keys:

| Key constant | Key value |
| --- | --- |
| `AppHiveKeys.latestRideDetails` | `latest_ride_details` |
| `AppHiveKeys.latestDashboard` | `latest_dashboard` |
| `AppHiveKeys.latestWalletSummary` | `latest_wallet_summary` |

### SharedPreferences keys still used in the codebase

| Key | Purpose |
| --- | --- |
| `rides_search_cache_v1` | stores the latest successful rides search snapshot |
| `ride_details_cache_v1` | legacy ride details snapshot key used for migration/fallback |

## File Inventory

### Ride persistence and offline support

| File | Role |
| --- | --- |
| `lib/features/rides/data/models/local_create_ride_draft_model.dart` | ride creation draft snapshot model |
| `lib/features/rides/data/datasources/create_ride_draft_local_datasource.dart` | local draft persistence adapter for ride creation |
| `lib/features/rides/data/models/local_pending_ride_status_action_model.dart` | deferred ride status action model |
| `lib/features/rides/data/datasources/active_ride_pending_action_local_datasource.dart` | local store for pending ride status changes |
| `lib/features/rides/data/models/local_ride_search_cache_model.dart` | search cache model |
| `lib/features/rides/data/datasources/rides_search_local_datasource.dart` | search cache persistence adapter |
| `lib/features/rides/data/models/local_ride_details_cache_model.dart` | ride details cache model |
| `lib/features/rides/data/datasources/ride_details_local_datasource.dart` | ride details cache adapter with memory + Hive + legacy prefs path |

### Wallet persistence and offline support

| File | Role |
| --- | --- |
| `lib/features/wallet/data/models/local_wallet_summary_cache_model.dart` | wallet summary snapshot model |
| `lib/features/wallet/data/datasources/wallet_summary_local_datasource.dart` | wallet summary local cache adapter |
| `lib/features/wallet/data/models/local_withdrawal_request_draft_model.dart` | withdrawal form draft model |
| `lib/features/wallet/data/datasources/withdrawal_request_draft_local_datasource.dart` | withdrawal draft persistence adapter |

### Screens that consume the persistence layer

| File | Role |
| --- | --- |
| `lib/features/rides/presentation/screens/create_ride_screen.dart` | create ride flow, uses current location and remote creation |
| `lib/features/rides/presentation/screens/active_ride_screen.dart` | active ride lifecycle and payment closure logic |
| `lib/features/rides/presentation/screens/rides_search_screen.dart` | search with cached fallback |
| `lib/features/rides/presentation/screens/ride_details_screen.dart` | ride details with cache fallback |
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | wallet summary read flow |
| `lib/features/wallet/presentation/screens/withdrawal_request_screen.dart` | withdrawal request flow with draft persistence |

### Tests added around offline persistence and cache

| File | Role |
| --- | --- |
| `test/support/ride_test_data.dart` | fixtures used by cache tests |
| `test/features/rides/data/models/local_ride_search_cache_model_test.dart` | search cache model tests |
| `test/features/rides/data/models/local_ride_details_cache_model_test.dart` | ride details cache model tests |
| `test/features/rides/data/datasources/rides_search_local_datasource_test.dart` | search cache datasource tests |
| `test/features/rides/data/datasources/ride_details_local_datasource_test.dart` | ride details datasource tests |

## Shared Project-Level Resilience Infrastructure

The repository now has a small but meaningful shared infrastructure layer that multiple features rely on. Even when each feature owns its own local datasource, the behavior is not isolated. A few shared building blocks shape how the whole project degrades when connectivity disappears.

### Connectivity service

Defined in:

- `lib/shared/providers/connectivity_provider.dart`

This service exposes two complementary capabilities:

- `hasConnection()`
  - a point-in-time connectivity check used before sensitive writes and refreshes,
- `watchConnection()`
  - a stream used by screens and providers that need to react to connectivity transitions.

The Riverpod layer exposes:

- `connectivityServiceProvider`
- `connectivityStatusProvider`

In practice, this means the app is not limited to "check once during startup." Screens can:

- detect that the device is offline before attempting a write,
- react when the connection comes back,
- refresh pending or stale state after reconnection.

This matters because several flows in the repo are intentionally designed around reconnection:

- payment status verification,
- ride history fallback recovery,
- dashboard refresh after cache fallback,
- withdrawal draft preservation when submit cannot be completed.

### Memory LRU cache

Defined in:

- `lib/shared/cache/memory_lru_cache.dart`

This is a small in-memory least-recently-used cache used to avoid repeated decode work and repeated storage reads during short-lived navigation sequences. The implementation is intentionally minimal:

- `get()` promotes hits to the most-recently-used position,
- `put()` evicts the oldest entry when the capacity is exceeded,
- `remove()` and `clear()` support explicit invalidation.

Although it is currently used in a narrow way, it is architecturally important because it adds a third layer between:

- live remote state,
- persisted local snapshot,
- ephemeral in-memory reuse.

That layered approach is visible in the ride details flow and dashboard support classes.

### App-wide Hive bootstrap

Defined in:

- `lib/shared/storage/app_hive.dart`

This file is the central inventory of currently opened Hive boxes. It is also the easiest place to inspect when diagnosing:

- merge regressions,
- missing box initialization,
- accidental storage naming drift,
- forgotten local persistence bootstrap.

The current design deliberately keeps box names centralized so that feature work does not silently invent ad hoc storage names spread across unrelated files.

## Additional Features With Local Persistence or Graceful Degradation

The app's resilience story is broader than the ride creation and wallet draft work. Other parts of the repo also implement important fallback behavior and should be part of the system-level documentation.

## Dashboard

### Why the dashboard matters

The dashboard is the home summary of the app, so its failure mode matters more than many secondary screens. A broken dashboard makes the app feel unavailable even if individual flows still work.

### Related files

- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart`
- `lib/features/dashboard/data/models/dashboard_model.dart`

### Strategy used

- online-first load,
- local snapshot restoration,
- Hive persistence,
- small in-memory cache,
- explicit fallback UI state.

### How it works

The dashboard screen restores the latest locally saved dashboard snapshot first. After that, it attempts a live refresh. This produces a noticeably better user experience than starting from an empty loading shell every time.

Operationally, the flow is:

1. `_initializeDashboard()` runs.
2. `_restoreLatestDashboard()` tries local recovery.
3. If local cache exists, the screen paints useful content immediately.
4. `_refreshDashboard()` checks connectivity before attempting remote work.
5. If online, it loads fresh data and overwrites the local snapshot.
6. If offline or the refresh fails, it keeps the restored snapshot visible and marks the state as fallback.

### What gets loaded concurrently

The dashboard provider layer shows another important project-wide pattern: concurrent guarded loading.

For drivers, the dashboard combines:

- current driver ride,
- wallet summary.

For passengers, it combines:

- current passenger ride,
- passenger application,
- payment record.

The provider code uses guarded futures so that one failing branch does not necessarily destroy the whole dashboard state model. That is an important resilience design decision because a "partial dashboard" is often better than a hard failure.

### Dashboard cache semantics

The dashboard local datasource uses a layered read strategy:

1. in-memory cache,
2. Hive box,
3. legacy `SharedPreferences` fallback and migration path.

This is important for two reasons:

- repeated navigation within one app session is faster,
- old persisted data from earlier storage strategies can still be migrated forward.

### User-visible behavior

The dashboard screen does not pretend cached data is live. It tracks whether it is showing fallback content and can notify the user when live data returns. That honesty is good product behavior and aligns with the rest of the repo's resilience strategy.

## Payments

### Why payments are special

Payments are one of the highest-risk flows in the app. Unlike a ride search or dashboard card, payment state must be conservative. The repo reflects that by using local persistence only for verification continuity, not for fabricating payment success.

### Related files

- `lib/features/payments/presentation/providers/payment_provider.dart`
- `lib/features/payments/presentation/screens/payment_screen.dart`
- `lib/features/payments/data/datasources/payment_local_datasource.dart`
- `lib/features/payments/data/models/local_payment_verification_cache_model.dart`

### Strategy used

- online-only checkout creation,
- pending verification cache,
- reconnection refresh,
- deep-link-aware recovery,
- Firestore stream observation for eventual confirmation.

### Payment flow safety model

The payment provider refuses to start checkout when the device is offline. That is the correct choice. Unlike a ride draft, a remote payment session cannot be safely "invented later" on the client.

So the payment flow draws a clear boundary:

- checkout creation is online-only,
- payment confirmation is eventually consistent,
- local persistence is used only to remember that verification is pending.

### Pending verification cache

The local payment cache stores a lightweight marker that includes:

- `rideId`,
- `passengerId`,
- `markedAt`,
- a user-facing message,
- optional `checkoutCreatedAt`,
- optional `expiresAt`.

This is a good example of disciplined local persistence: the app stores only the minimum information needed to continue the UX after interruption.

### Why this cache exists

Payment confirmation is not instantaneous in all paths. The user may:

- leave the app,
- return from a payment provider deep link,
- lose connectivity while backend reconciliation is still pending,
- reopen the app before Firestore finishes reflecting the final status.

Without a local "pending verification" artifact, the app would feel unreliable even if the backend eventually resolved the transaction correctly.

### Reconnection behavior

The payment screen listens to `connectivityStatusProvider`. When the app transitions from offline to online, it triggers `refreshStatus(allowMissingRecord: true)`.

That matters because the payment flow is explicitly eventual:

- the user may have already completed an external checkout step,
- the backend may need time to write the payment record,
- the app should retry status observation when connectivity returns.

### Lifecycle awareness

The payment screen also refreshes when the app resumes from the background. That is another subtle but important resilience detail. Payment flows often cross app boundaries, so "resume" is a meaningful synchronization point.

### What the app does not do

The current implementation intentionally does not:

- mark a payment approved from local cache alone,
- bypass remote verification,
- hide the difference between "pending" and "approved."

That conservative posture is exactly what we want in a financial flow.

## Ride History

### Why ride history belongs in this document

Ride history is not a draft-based flow, but it is still part of the app's offline and resilience story because it implements a real cached fallback with explicit UI messaging.

### Related files

- `lib/features/ride_history/presentation/providers/ride_history_providers.dart`
- `lib/features/ride_history/presentation/screens/ride_history_screen.dart`
- `lib/features/ride_history/data/repositories/ride_history_repository_impl.dart`
- `lib/features/ride_history/data/datasources/ride_history_local_datasource.dart`

### Strategy used

- read cached history first,
- refresh from remote when online,
- persist remote results into local SQLite,
- surface whether the user is seeing cached data,
- keep retry available when online.

### Storage choice

Ride history uses `sqflite`, not Hive. That is meaningful because it shows the project does not force one storage mechanism onto every problem.

SQLite is a sensible choice here because ride history is:

- list-oriented,
- ordered,
- user-scoped,
- naturally modeled as rows with stable fields,
- a better fit for incremental local record storage than single-snapshot JSON blobs.

### Load behavior

The notifier loads cached history first, exposing it immediately if available. If the device is online, it then tries to fetch fresh history from the remote source. If remote loading fails and cached entries exist, it returns the cached state with `hasRemoteError = true`.

That gives the UI enough information to say something more nuanced than "error":

- there is usable data,
- but it may be stale,
- and a retry can still be offered.

### User-visible behavior

The ride history screen includes:

- a stale notice when cached data is being shown,
- a separate load error notice when there is no cache,
- an offline-aware empty state,
- a retry affordance when reconnection is possible.

This is a strong pattern that other screens can copy because it cleanly separates:

- no data,
- stale cached data,
- hard failure.

## Cross-Feature Patterns Found in the Repository

Looking at the project as a whole, the resilience work follows a few recurring patterns.

### Pattern 1: Online-only commits for sensitive operations

Examples:

- payment checkout creation,
- withdrawal request submission.

The repository consistently avoids pretending that sensitive financial actions can be queued blindly offline. Instead, it preserves user input or verification context, then asks the user to reconnect before the true remote commit.

### Pattern 2: Local preservation of user effort

Examples:

- create ride draft,
- withdrawal request draft.

The design goal here is not offline completion of every feature. It is preventing frustration and lost work.

### Pattern 3: Cached fallback for read-heavy screens

Examples:

- dashboard,
- wallet summary,
- rides search,
- ride details,
- ride history.

These screens prefer showing the last known good state rather than collapsing into empty UI whenever the backend is unavailable.

### Pattern 4: Migration-aware local datasources

Examples:

- dashboard local datasource,
- ride details local datasource.

The codebase includes logic to read legacy `SharedPreferences` payloads and move them into Hive-backed storage. That shows the project is already thinking about storage evolution, not just initial implementation.

### Pattern 5: Honest offline messaging

Across the repo, the better implementations avoid silent fallback. Instead they expose some combination of:

- stale cache notices,
- restored draft banners,
- retry buttons,
- snackbars describing what happened,
- messaging that distinguishes local state from confirmed remote state.

That honesty reduces confusion and makes the app easier to trust.

## Recommended Documentation View of the Whole Project

If we describe the repository at a system level rather than by individual issue, the current app can be understood as having four resilience layers:

1. **Connectivity awareness**
   - shared detection of offline vs online state through providers and one-shot checks.

2. **Local persistence**
   - Hive, SharedPreferences, and SQLite used according to feature shape.

3. **UI recovery**
   - restored forms, cached snapshots, stale notices, and retry affordances.

4. **Eventual reconciliation**
   - reconnection refresh, pending verification markers, and deferred ride action semantics.

This broader framing is useful because it shows that the repository is not implementing isolated tricks. It is gradually building a coherent reliability model.

## Screen-by-Screen Behavior

## CreateRideScreen

### Goal

The ride creation flow should allow the user to recover in-progress form data and reduce frustration if the app is interrupted or connectivity becomes unstable.

### Strategy used

- offline draft persistence,
- deferred synchronization-ready design,
- local JSON snapshot persisted through Hive.

### Related files

- `lib/features/rides/presentation/screens/create_ride_screen.dart`
- `lib/features/rides/data/models/local_create_ride_draft_model.dart`
- `lib/features/rides/data/datasources/create_ride_draft_local_datasource.dart`

### Core behavior

The create ride flow stores the current form state locally under a cache identifier derived from the current user. The local snapshot contains the key parts of the form:

- origin
- destination
- departure date
- departure time
- estimated duration
- selected seats
- price
- payment option
- notes
- draft metadata such as `savedAt`
- `pendingSync` flag when applicable

### Why a draft is used instead of immediate optimistic creation

Creating a ride is a write to shared remote state. If the app wrote local “fake rides” into the visible marketplace without confirmation, that could produce misleading or unsafe behavior. A local draft is safer because:

- it preserves the user’s effort,
- it avoids showing unconfirmed rides to other users,
- it keeps the remote truth authoritative.

### Draft save flow

1. The screen initializes.
2. The screen restores any stored draft associated with the current user.
3. The text controllers listen for changes.
4. A debounce timer is used before persisting the latest form snapshot.
5. The resulting draft is encoded to JSON and stored in the `createRideDrafts` Hive box.

### Draft restore flow

1. The screen computes a `cacheId`.
2. The local datasource loads the JSON snapshot from Hive.
3. The JSON payload is decoded on a background isolate using `compute`.
4. If decoding succeeds, the form fields are repopulated.
5. If decoding fails, the draft is cleared and ignored.

### Pending synchronization concept

The create ride draft model supports a `pendingSync` concept so that a failed publish attempt does not need to be discarded. This is a foundation for eventual synchronization behavior:

- the user can retry later,
- the app does not lose the intended ride payload,
- the UI can tell the user that the publication is pending rather than completed.

### Safety properties

- no draft means no local clutter,
- corrupted draft means delete and continue,
- draft belongs to one user context through the cache id,
- no remote marketplace mutation occurs until the backend call succeeds.

### Practical UX implications

- users recover their work after interruption,
- the form no longer feels fragile,
- the user experience is more resilient in bad network conditions,
- there is still a clear distinction between a saved draft and a published ride.

## ActiveRideScreen

### Goal

The active ride screen handles critical ride lifecycle state. Some actions must survive temporary network problems without silently disappearing.

### Strategy used

- pending local action persistence,
- online-first execution,
- deferred sync for selected ride status transitions,
- explicit pending state rather than silent retry.

### Related files

- `lib/features/rides/presentation/screens/active_ride_screen.dart`
- `lib/features/rides/data/models/local_pending_ride_status_action_model.dart`
- `lib/features/rides/data/datasources/active_ride_pending_action_local_datasource.dart`

### Actions in scope

The deferred synchronization support is meant for ride status actions that can be represented safely as a single pending state transition:

- start ride,
- cancel ride.

The finish ride flow is intentionally more conservative because it also touches payment status decisions and post-ride consistency.

### Pending action model

The local pending action records:

- `rideId`
- target status
- created or saved time
- any metadata needed to understand the intended action

This keeps the deferred action explicit and local.

### Local persistence mechanism

The pending action is:

- encoded to JSON,
- stored in Hive under the `activeRidePendingActions` box,
- keyed by `rideId`.

### Synchronization behavior

When the app detects that an action cannot be completed immediately, it stores the pending action rather than dropping it. The screen can then:

- restore the pending action on reopen,
- display a pending sync notice,
- retry later,
- allow discarding if needed.

### Why not make everything offline

Not every ride lifecycle operation should become an offline-first write. In particular, finishing a ride touches:

- passenger payment status
- card/manual transfer distinctions
- ride completion state

Those are more sensitive and should remain strongly tied to remote confirmation unless the design is expanded carefully.

### Bug fix note

During later review, a real bug was corrected in the ride completion flow:

- passenger payment updates now use `application.passengerId` instead of the application document id,
- the completion loop persists final payment status for all relevant passengers,
- the success message was updated to better match the actual behavior.

This matters because event-driven deferred flows are only trustworthy if they maintain correct identifiers and write targets.

### User-facing implication

The active ride screen should favor clarity over hidden behavior:

- if something is pending, the user should know,
- if the ride finished, payment status updates should be consistent,
- if a lifecycle action cannot be completed immediately, it should be recoverable.

## WalletScreen

### Goal

The wallet should continue to provide useful information even when the network is not currently available.

### Strategy used

- online-first with cached fallback,
- snapshot persistence,
- explicit cached-data presentation.

### Related files

- `lib/features/wallet/presentation/screens/wallet_screen.dart`
- `lib/features/wallet/data/models/local_wallet_summary_cache_model.dart`
- `lib/features/wallet/data/datasources/wallet_summary_local_datasource.dart`

### Local snapshot contents

The wallet snapshot stores a local version of:

- available balance
- pending withdrawal balance
- total earned
- saved timestamp
- version metadata

### Persistence flow

1. The screen or provider loads live wallet data when possible.
2. If a valid remote response is received, the local snapshot is refreshed.
3. If the network is unavailable later, the app may restore the last saved snapshot.

### Why wallet uses snapshot instead of draft

Wallet is a read-heavy flow, not a user-generated form. The important resilience property is:

- keep showing the last known state,

not:

- preserve in-progress input.

### Bug fix note

The withdrawal flow review led to a related wallet safety improvement:

- the withdrawal screen no longer proceeds as if wallet data were guaranteed,
- instead it waits for the wallet summary `AsyncValue`,
- this avoids exposing a financial form before the relevant balance has been loaded.

### UX expectations

For financial data, cached fallback should be:

- helpful,
- clearly distinguishable from live data,
- never used as a basis for unsafe optimistic remote commits.

## WithdrawalRequestScreen

### Goal

The withdrawal form should preserve user effort locally, but the financial submission itself must remain online-only.

### Strategy used

- offline draft persistence,
- online-only final commit,
- explicit connectivity check before submission,
- validation against the currently loaded wallet summary.

### Related files

- `lib/features/wallet/presentation/screens/withdrawal_request_screen.dart`
- `lib/features/wallet/data/models/local_withdrawal_request_draft_model.dart`
- `lib/features/wallet/data/datasources/withdrawal_request_draft_local_datasource.dart`

### Why this flow is different from Create Ride

Create Ride is a publish action into marketplace state. Withdrawal is a financial request. That means the cost of an incorrect optimistic behavior is higher.

So the design is intentionally conservative:

- the form itself is recoverable offline,
- the request is not submitted offline,
- the app tells the user when a draft was saved because connectivity was missing.

### Draft content

The local draft stores:

- amount text
- bank name
- account type
- account number
- account holder name
- `savedAt`
- version metadata

### Restore behavior

On open:

1. The screen builds a user-specific draft key.
2. The local datasource reads the stored JSON snapshot.
3. If a meaningful draft exists, fields are restored.
4. A notice card is shown so the user knows the data came from local persistence.

### Draft UX

The screen exposes explicit draft actions:

- save draft now,
- discard draft.

This is important because silent persistence can feel surprising if the user is not aware of it.

### Submission flow

The submission path includes:

1. form validation,
2. connectivity check,
3. amount parsing,
4. balance comparison,
5. controller submission.

If there is no connection:

- the form is persisted,
- a snackbar informs the user that submission requires internet,
- the draft is kept for later.

### Why balance validation matters

The screen validates that the requested amount:

- is at least the minimum withdrawal amount,
- does not exceed `walletSummary.availableBalance`.

This prevents a class of invalid requests from reaching the backend.

### Error handling behavior

The screen uses `walletSummaryAsync.when(...)` so that:

- loading is explicit,
- error is explicit,
- access is denied cleanly if the wallet cannot be retrieved or the user is not a driver.

This is safer than rendering a partially-informed form.

## Ride Search Cache

### Goal

Ride search should remain useful when the user cannot reach Firestore or the search cannot be repeated live.

### Strategy used

- save the latest successful search,
- restore the last known results,
- use a versioned JSON snapshot.

### Related files

- `lib/features/rides/data/models/local_ride_search_cache_model.dart`
- `lib/features/rides/data/datasources/rides_search_local_datasource.dart`

### Key behaviors

- current version is validated,
- selected date is normalized to a date-only value,
- unsupported or malformed payloads throw format exceptions,
- invalid stored cache is removed automatically.

### Why date-only normalization is important

The search filter is conceptually day-based. Preserving an arbitrary hour in the filter would create unnecessary instability in cache comparisons and round-trips.

### Storage choice

This cache still uses `SharedPreferences` rather than Hive. That is acceptable here because:

- it stores only a single latest snapshot,
- the payload is already JSON-encoded,
- the shape is simple,
- compatibility cost is low.

## Ride Details Cache

### Goal

Ride details should load quickly and still be available when the live backend read is unavailable.

### Strategy used

- LRU in-memory cache,
- Hive persistence,
- legacy SharedPreferences migration path.

### Related files

- `lib/features/rides/data/models/local_ride_details_cache_model.dart`
- `lib/features/rides/data/datasources/ride_details_local_datasource.dart`
- `lib/shared/cache/memory_lru_cache.dart`

### Read order

The ride details datasource follows a layered read order:

1. memory cache,
2. Hive,
3. legacy SharedPreferences,
4. null.

### Why memory cache first

Memory cache helps repeated in-session navigation:

- no disk hit,
- no JSON decode,
- no unnecessary churn.

### Why Hive second

Hive acts as the durable local source:

- survives app restarts,
- supports longer-lived fallback,
- allows removing corrupted entries individually.

### Legacy migration path

If Hive has no entry, the datasource can still read the old `ride_details_cache_v1` SharedPreferences key, validate it, then move it into Hive and clear the old value.

This prevents old users from losing the cache immediately after storage strategy evolution.

### Expiration semantics

The model exposes `isExpired`, which:

- rejects stale entries older than the defined max age,
- also rejects unrealistic future timestamps beyond tolerance.

That protects the app from obviously broken local timestamps.

## Storage Schema Notes

## Create ride draft schema

The create ride draft model is versioned and represented as JSON. While the exact fields are defined in code, conceptually the schema includes:

```json
{
  "version": 1,
  "savedAt": "2026-04-25T03:00:00.000Z",
  "origin": "Campus Uniandes - Main Gate",
  "destination": "Cedritos",
  "dateText": "25/04/2026",
  "timeText": "18:30",
  "durationText": "35",
  "availableSeats": 3,
  "priceText": "12000",
  "paymentOption": "card",
  "notes": "Please be on time",
  "pendingSync": false
}
```

## Pending ride status action schema

Conceptually:

```json
{
  "version": 1,
  "rideId": "ride-123",
  "targetStatus": "in_progress",
  "savedAt": "2026-04-25T03:10:00.000Z"
}
```

## Wallet summary cache schema

Conceptually:

```json
{
  "version": 1,
  "savedAt": "2026-04-25T03:15:00.000Z",
  "availableBalance": 48000,
  "pendingWithdrawalBalance": 10000,
  "totalEarned": 122000
}
```

## Withdrawal request draft schema

Conceptually:

```json
{
  "version": 1,
  "savedAt": "2026-04-25T03:20:00.000Z",
  "amountText": "15000",
  "bankName": "Bancolombia",
  "accountType": "savings",
  "accountNumber": "1234567890",
  "accountHolderName": "Martin Del Gordo"
}
```

## Design Tradeoffs

## Why JSON strings inside Hive boxes

The current implementation stores JSON-encoded strings inside Hive boxes rather than strongly typed Hive adapters.

Advantages:

- fast to implement,
- easy to inspect during debugging,
- no generated adapters,
- consistent with compute-based encode/decode helpers,
- easier to share logic with non-Hive storage styles.

Tradeoffs:

- no compile-time schema validation at storage layer,
- manual version handling is required,
- corruption is only detected at decode time.

## Why compute is used for encode/decode

The local datasources use `compute` for snapshot encoding/decoding in several places.

Advantages:

- avoids pushing JSON-heavy work onto the UI isolate,
- scales better for richer models,
- reinforces the multi-threading strategy described in sprint documentation.

Tradeoffs:

- slightly more ceremony,
- more surface area for test setup,
- only worthwhile for sufficiently structured payloads.

## Why not use SQLite for these flows

SQLite would be reasonable for more complex synchronization queues, but current flows mostly need:

- one latest snapshot,
- one draft per user,
- one pending action per ride.

Hive and SharedPreferences are enough for the current scope with lower complexity.

## Why not sync withdrawals offline

Financial flows require stronger correctness guarantees. Allowing offline submission would risk:

- duplicate requests,
- inconsistent balances,
- misleading UI states,
- hard-to-explain reconciliation behavior.

So the chosen design is:

- draft offline,
- submit online only.

## Why not publish rides offline as if they were live

Publishing a ride affects other users and shared marketplace state. Showing a locally-created ride as fully published before remote confirmation could mislead the marketplace.

So the safer strategy is:

- persist intent locally,
- confirm publication only after remote success.

## UI Communication Principles

Offline-capable features must be honest with the user. The app should distinguish:

- live data,
- cached data,
- restored draft,
- pending synchronization.

The UI patterns used in the repo support that by surfacing:

- snackbars,
- notice cards,
- retry actions,
- clear/discard actions.

## Error Handling Patterns

Across the persistence layer, invalid local data is treated as disposable. The common pattern is:

1. read raw string from local storage,
2. attempt decode,
3. if decode fails:
   - clear the local entry,
   - return `null`.

This is a pragmatic choice:

- it avoids repeated crashes or stuck states,
- it keeps the app moving,
- it assumes remote regeneration or user input is preferable to preserving corrupted data.

## Testing Strategy

The repository now includes a first set of tests focused on local cache and persistence correctness.

## What is covered

### Search cache model tests

Covered behaviors:

- selected date serialization as date-only,
- normalized deserialization,
- unsupported sort rejection,
- versioned cache round-trip,
- invalid result item rejection.

### Ride details model tests

Covered behaviors:

- round-trip JSON conversion,
- ride id consistency validation,
- `matchesRide`,
- `isExpired` for old entries,
- `isExpired` for future timestamps,
- `isExpired` for fresh snapshots.

### Search datasource tests

Covered behaviors:

- null when no cache exists,
- save and restore success path,
- invalid cached payload clears storage,
- explicit clear removes saved cache,
- blank string behaves as empty cache.

### Ride details datasource tests

Covered behaviors:

- null when there is no memory, Hive, or prefs cache,
- save to Hive and restore,
- memory cache hit precedence,
- invalid Hive payload removal,
- legacy SharedPreferences migration into Hive,
- dropping mismatched legacy cache,
- loading legacy latest snapshot,
- clear removing both memory and Hive data.

## Why these tests matter

Offline behavior tends to fail in subtle ways:

- stale payload shapes,
- version mismatches,
- incorrect fallback assumptions,
- silent corruption,
- shared state leaking between runs.

The tests provide confidence in the most fundamental layer: local persistence primitives.

## Manual QA Guide

The following manual scenarios can be used by QA or teammates.

## Create ride draft scenarios

### Scenario CR-01

- Screen: `CreateRideScreen`
- Starting condition: user is signed in as driver
- Action: start filling origin, destination, date, time, price, notes
- Interrupt: close the app before publishing
- Expected:
  - draft is restored on reopen,
  - notice or restored state appears if implemented in UI,
  - user input is not lost.

### Scenario CR-02

- Starting condition: form partially filled
- Action: keep typing for several fields
- Expected:
  - no visible lag,
  - draft save debounce avoids excessive writes,
  - reopening the screen restores the latest state.

### Scenario CR-03

- Starting condition: no internet
- Action: attempt to publish
- Expected:
  - the app does not pretend the ride is published,
  - the draft remains available,
  - user gets a clear message.

### Scenario CR-04

- Starting condition: corrupted draft payload injected into local storage
- Action: open the screen
- Expected:
  - no crash,
  - corrupted draft is ignored and cleared.

## Active ride pending action scenarios

### Scenario AR-01

- Starting condition: active ride in `open`
- Action: attempt `Start Ride` when network is unstable
- Expected:
  - intended state transition is not silently lost,
  - pending state can be restored,
  - user receives clear feedback.

### Scenario AR-02

- Starting condition: pending action exists locally
- Action: reopen `ActiveRideScreen`
- Expected:
  - screen restores the pending action,
  - UI reflects pending synchronization.

### Scenario AR-03

- Starting condition: pending action exists, network returns
- Action: trigger retry
- Expected:
  - local action is synchronized,
  - pending state is cleared if successful.

### Scenario AR-04

- Starting condition: finish ride with mixed passenger payment methods
- Action: confirm ride completion
- Expected:
  - manual transfer passengers get final status persisted,
  - card-related passengers do not use the wrong identifier,
  - status message matches the actual outcome.

## Wallet snapshot scenarios

### Scenario WS-01

- Starting condition: successful wallet load
- Action: refresh wallet while online
- Expected:
  - local snapshot is updated.

### Scenario WS-02

- Starting condition: previously saved wallet snapshot exists
- Action: open wallet without connection
- Expected:
  - last known snapshot is shown,
  - app does not crash on missing network.

### Scenario WS-03

- Starting condition: corrupted wallet snapshot
- Action: open wallet
- Expected:
  - invalid cache is ignored/cleared,
  - screen falls back to live load or error state.

## Withdrawal draft scenarios

### Scenario WD-01

- Starting condition: driver opens withdrawal form
- Action: enter amount, bank name, account number, account holder
- Interrupt: close the app
- Expected:
  - form data is restored on reopen,
  - restored draft notice appears.

### Scenario WD-02

- Starting condition: no internet
- Action: try to submit valid draft
- Expected:
  - form is preserved,
  - no remote submission occurs,
  - user sees message that connection is required.

### Scenario WD-03

- Starting condition: available balance lower than amount
- Action: submit
- Expected:
  - validation blocks the request,
  - user sees balance-related message.

### Scenario WD-04

- Starting condition: wallet summary fails to load
- Action: open screen
- Expected:
  - loading or error state is shown,
  - form is not shown as if balance were known.

## Search cache scenarios

### Scenario SC-01

- Starting condition: perform successful search online
- Action: lose connection and reopen search
- Expected:
  - last successful search can be restored,
  - filters and results are coherent.

### Scenario SC-02

- Starting condition: malformed search cache
- Action: load cached search
- Expected:
  - local cache is cleared,
  - app returns `null` instead of crashing.

## Ride details cache scenarios

### Scenario RD-01

- Starting condition: ride details already loaded once
- Action: open same ride again in same session
- Expected:
  - memory cache hit used,
  - faster restoration path.

### Scenario RD-02

- Starting condition: ride details cached in Hive
- Action: cold restart app and open same ride offline
- Expected:
  - Hive cache can restore details if used by screen logic.

### Scenario RD-03

- Starting condition: legacy SharedPreferences cache exists
- Action: load ride details
- Expected:
  - legacy cache migrates to Hive,
  - old key is removed.

## Implementation Notes by File

## `create_ride_draft_local_datasource.dart`

Main characteristics:

- uses Hive box `AppHiveBoxes.createRideDrafts`,
- stores encoded JSON strings,
- background decode and encode with `compute`,
- clears invalid stored payloads,
- keys are namespaced as `create_ride_draft:<cacheId>`.

Implication:

- one user can have an isolated draft key,
- multiple user contexts can coexist safely if needed.

## `active_ride_pending_action_local_datasource.dart`

Main characteristics:

- uses Hive box `AppHiveBoxes.activeRidePendingActions`,
- stores one action per ride id,
- background decode and encode with `compute`,
- clears invalid pending action payloads.

Implication:

- the ride id is the natural identity of a pending lifecycle transition.

## `wallet_summary_local_datasource.dart`

Main characteristics:

- uses Hive box `AppHiveBoxes.walletSummaryCache`,
- fixed key `AppHiveKeys.latestWalletSummary`,
- stores latest snapshot only,
- decode failure clears the cache.

Implication:

- the design optimizes for "latest known wallet" rather than a historical wallet timeline.

## `withdrawal_request_draft_local_datasource.dart`

Main characteristics:

- uses Hive box `AppHiveBoxes.withdrawalRequestDrafts`,
- uses caller-provided `cacheId`,
- background decode/encode with `compute`,
- invalid payload clears itself.

Implication:

- draft identity can be tied to the current authenticated driver.

## `rides_search_local_datasource.dart`

Main characteristics:

- uses SharedPreferences,
- fixed key `rides_search_cache_v1`,
- background encode/decode with `compute`,
- invalid cache clears itself.

Implication:

- only one latest search is stored,
- enough for offline restore but not a full recent-search history.

## `ride_details_local_datasource.dart`

Main characteristics:

- checks in-memory LRU first,
- then Hive,
- then legacy SharedPreferences,
- migrates old cache into Hive,
- clears corrupted entries.

Implication:

- strong layered fallback,
- backward compatibility,
- better performance for repeated reads.

## Known Limitations

The current implementation is intentionally pragmatic, not a full offline sync engine.

Known limitations include:

- there is no general-purpose synchronization queue across all features,
- drafts and snapshots are mostly per-screen and per-use-case,
- conflict resolution is minimal,
- wallet snapshot does not yet represent multiple users or version history,
- search cache stores only the latest search,
- ride creation draft behavior is safer than optimistic, but not a complete background publisher,
- active ride deferred sync intentionally avoids broader payment reconciliation automation,
- withdrawal remains online-only for final commit.

## Recommended Future Work

The current design provides a good base for future evolution.

Possible next steps:

1. consolidate offline notice UI into reusable shared widgets,
2. add more widget tests around restored draft and cached fallback banners,
3. add tests for the new draft and pending-action datasources,
4. add timestamp presentation for cached wallet data,
5. build a small generic synchronization queue abstraction for deferred writes,
6. add conflict metadata to pending actions,
7. extend wallet snapshot documentation with freshness indicators,
8. add analytics around draft recovery and deferred sync retries,
9. add retention policy for stale drafts,
10. add dev tooling for inspecting local persistence state.

## Extension Guidelines

When adding a new offline-capable flow, follow these steps:

1. classify the flow:
   - read fallback,
   - form draft,
   - deferred write,
   - hybrid.

2. choose the risk profile:
   - can the action be optimistic,
   - must it remain online-only,
   - does the user need explicit status communication.

3. define the local model:
   - version field,
   - saved time,
   - stable identity,
   - semantic fields only.

4. define the datasource:
   - clear invalid data on decode failure,
   - isolate-heavy encode/decode if payload is non-trivial,
   - use namespaced keys when user scoping matters.

5. define the screen behavior:
   - restore at startup,
   - autosave if needed,
   - display restored/cached/pending state,
   - let the user discard or retry where appropriate.

6. define testing:
   - save,
   - load,
   - clear,
   - invalid payload,
   - state restoration,
   - fallback behavior.

## Troubleshooting Guide

## Symptom: Draft does not restore

Checklist:

- verify the current user matches the original cache id,
- verify Hive box is opened during app startup,
- verify the screen actually calls restore during `initState`,
- verify the draft has meaningful data,
- verify decode is not clearing a corrupted payload.

## Symptom: Cached wallet never appears

Checklist:

- verify `walletSummaryLocalDataSource` is wired into the screen/provider path,
- verify the latest online wallet success actually saves a snapshot,
- verify the snapshot decode succeeds,
- verify UI distinguishes error from cached fallback.

## Symptom: Search cache restores wrong date

Checklist:

- remember that search date is stored as date-only,
- ensure tests expect date normalization,
- ensure UI does not assume time precision in search filters.

## Symptom: Ride details cache loads stale data

Checklist:

- inspect `isExpired`,
- verify whether the screen respects cache age,
- verify whether a newer remote read is available but not being preferred,
- inspect the in-memory cache lifecycle.

## Symptom: Withdrawal request submits invalid amount

Checklist:

- confirm wallet summary has finished loading,
- confirm `amount > availableBalance` validation is still present,
- confirm form validator and final submit guard are both in place.

## Symptom: Active ride completion writes wrong payment record

Checklist:

- verify `application.passengerId` is used,
- verify not mixing passenger application id with passenger identity,
- verify card/manual transfer status logic still matches the business rules.

## Coding Conventions Used in These Flows

Patterns consistently used:

- small local datasource classes,
- JSON versioned models,
- background encode/decode helpers,
- `null` return for no cache / cleared invalid cache,
- UI built around explicit `AsyncValue` branches,
- `mounted` checks after async gaps before using `context`.

These are worth preserving to keep the codebase predictable.

## Suggested Reviewer Reading Order

If a reviewer wants to understand the feature set quickly, the recommended order is:

1. `lib/shared/storage/app_hive.dart`
2. `lib/features/rides/data/datasources/create_ride_draft_local_datasource.dart`
3. `lib/features/rides/data/datasources/active_ride_pending_action_local_datasource.dart`
4. `lib/features/wallet/data/datasources/wallet_summary_local_datasource.dart`
5. `lib/features/wallet/data/datasources/withdrawal_request_draft_local_datasource.dart`
6. `lib/features/rides/presentation/screens/create_ride_screen.dart`
7. `lib/features/rides/presentation/screens/active_ride_screen.dart`
8. `lib/features/wallet/presentation/screens/wallet_screen.dart`
9. `lib/features/wallet/presentation/screens/withdrawal_request_screen.dart`
10. persistence-related tests under `test/features/rides/data/`

## Summary

The current eventual connectivity and local persistence implementation in Wheels is intentionally pragmatic:

- it protects user effort,
- it keeps local state explicit,
- it avoids unsafe optimistic behavior in sensitive flows,
- it adds test coverage to foundational cache logic,
- it fits cleanly into the project’s feature-first structure.

The result is not a full offline-first platform, but it is a strong and defensible reliability layer for the current sprint scope.

## Detailed Operational Flows

This section expands the previous screen-by-screen summary with more operational detail. The purpose is to make the runtime behavior easier to reason about during debugging, QA sessions, demos, and future refactors.

## CreateRideScreen operational flow

### Initialization sequence

When `CreateRideScreen` starts, the screen performs several responsibilities close together:

1. it creates text controllers for notes, date, time, duration, and price,
2. it schedules current-location prefill through `CurrentLocationService`,
3. it restores draft state if the feature branch with draft support is active,
4. it waits for user edits before attempting any publish action.

From a resilience perspective, the important point is that "populate the form" and "publish the ride" are clearly separated. This keeps recovery simple and avoids accidental writes to shared state before the form is really ready.

### Data ownership inside the form

The ride creation form mixes three categories of state:

- controller-based text fields,
- primitive in-memory selections such as payment option or available seats,
- derived display values such as estimated earnings.

Only the first two categories should be part of a local draft. Derived display values can always be recomputed from the underlying inputs, so they should not be persisted as source-of-truth state.

### Failure modes that matter here

The main failure modes for this screen are:

- app process closes while the user is still typing,
- connectivity is lost before or during the publish attempt,
- a malformed local draft is restored,
- current location lookup fails,
- the user reaches the screen in a partially authenticated or invalid session state.

The offline draft strategy does not solve every one of those directly, but it lowers the overall fragility of the flow by preserving the most expensive user effort: the input itself.

### Suggested maintenance rule

If new fields are added to `CreateRideScreen`, reviewers should ask:

- is this field part of the user's intent and therefore worth persisting?
- or is it derived and better recomputed?

That rule helps keep drafts small, stable, and meaningful.

## ActiveRideScreen operational flow

### Runtime responsibilities

`ActiveRideScreen` does more than show a ride card. It effectively coordinates:

- ride lifecycle state,
- passenger application data,
- post-ride payment status decisions,
- ride completion flow,
- group chat navigation,
- external navigation launch,
- deferred local ride status actions.

This is why the screen deserves special care in documentation. It is a convergence point between multiple features.

### Why the active ride flow is delicate

A lifecycle screen becomes risky when it mixes:

- writes to the ride document,
- reads from passenger applications,
- writes to payment state,
- UX promises about what "finished" means.

Any identifier mismatch or premature assumption can cause user-facing inconsistency. That is exactly why the earlier bug fix around `application.passengerId` matters so much.

### Finish ride flow in detail

The finish flow conceptually performs:

1. fetch card payment status information if card payments are enabled,
2. build a passenger review/payment decision modal,
3. gather the final statuses the user confirmed,
4. write each passenger's final payment status,
5. clear local controller state,
6. update the ride status to `completed`,
7. navigate away if needed.

The important engineering point here is ordering:

- payment status must be persisted before claiming the ride is completed,
- identifiers must map to real passenger records,
- UI success text should match what was truly persisted.

### Deferred actions versus completion

It is tempting to imagine that every ride action should support the same offline behavior. In practice, the screen already demonstrates why selective scope is healthier:

- `start ride` and `cancel ride` can reasonably be represented as one target state,
- `finish ride` contains richer side effects and therefore needs stricter treatment.

This distinction is good architecture, not an inconsistency.

## WalletScreen operational flow

### Runtime expectations

The wallet flow should answer three questions quickly:

- how much money is available right now,
- how much is pending,
- how much has been earned in total.

If the remote backend cannot answer that momentarily, the app still benefits from showing the last known summary, but it must do so honestly.

### Why wallet fallback is still conservative

The wallet snapshot is useful because it reduces dead ends. However, the snapshot is still only a snapshot. That means:

- it is appropriate for reading,
- it is inappropriate as sole evidence for financial mutations,
- it should not create the illusion of real-time certainty.

This is why the withdrawal flow was updated to require a properly loaded wallet state rather than proceeding directly with whatever happens to be on screen.

### Example of good cached-data communication

An ideal wallet cached-state message should communicate:

- this balance is the most recently stored summary,
- it may not reflect the latest backend change,
- refresh will happen when connectivity is restored.

Even if the exact wording evolves, that communication principle should remain stable.

## WithdrawalRequestScreen operational flow

### Runtime responsibilities

This screen coordinates several layers at once:

- driver-access gating,
- wallet summary loading,
- local form draft persistence,
- user-facing draft recovery controls,
- connectivity check,
- business validation,
- remote request submission,
- post-submit cleanup.

Because these responsibilities are layered, the screen can look long. That is acceptable as long as each step remains explicit and ordered.

### Why the screen now waits for wallet summary

Previously, one of the biggest risks in this flow was that the form could be shown before the balance context was truly ready. That creates two problems:

- the user can start a financial action without the relevant numbers,
- validation must then guess or defer essential business checks.

By forcing the screen through `walletSummaryAsync.when(...)`, the flow now guarantees that:

- loading is visible,
- errors are visible,
- the balance context is present before the form becomes actionable.

### Draft restore semantics

The restored draft in this screen is intentionally user-visible. The reason is trust:

- bank data is sensitive,
- silently restoring it could surprise users,
- explicit notice plus discard control makes the behavior safer and easier to understand.

### Offline submission semantics

The offline branch of `_submit` does not attempt a dangerous "queued financial request." Instead, it:

1. persists the latest draft,
2. tells the user internet is required,
3. leaves the form recoverable for later.

This is the correct compromise between resilience and correctness.

## Persistence Data Lifecycle Summary

The application now has multiple persistence artifacts, and each one follows a slightly different lifecycle.

### Draft lifecycle

Examples:

- create ride draft,
- withdrawal request draft.

Generic lifecycle:

1. no persisted data,
2. user input becomes meaningful,
3. debounce writes snapshot,
4. app interruption occurs,
5. screen restores snapshot,
6. user either:
   - resumes editing,
   - explicitly discards,
   - or completes the remote action successfully.

### Snapshot lifecycle

Examples:

- wallet summary,
- search cache,
- ride details cache.

Generic lifecycle:

1. live data loads successfully,
2. app stores latest snapshot,
3. later remote load is unavailable,
4. local snapshot is restored,
5. future successful live load replaces the previous one.

### Pending action lifecycle

Examples:

- active ride status transition.

Generic lifecycle:

1. action requested,
2. remote write cannot complete,
3. action saved locally,
4. action restored later,
5. retry occurs,
6. local artifact is cleared once remote truth matches intent.

## More Detailed QA Matrix

The earlier manual scenarios remain useful. This table adds a more explicit mapping between scenario type, expected local artifact, and expected user-visible behavior.

| Scenario family | Local artifact expected | User-visible signal | Remote write expected immediately |
| --- | --- | --- | --- |
| Create ride while editing | create ride draft | restored form or draft state | No |
| Create ride publish fails | create ride draft / pending draft state | feedback that work was preserved | No |
| Active ride start/cancel offline | pending ride status action | pending sync notice | No |
| Wallet load succeeds | wallet snapshot | normal wallet content | N/A |
| Wallet load fails after prior success | wallet snapshot fallback | cached-data style state | N/A |
| Withdrawal editing | withdrawal draft | restored draft notice | No |
| Withdrawal submit offline | withdrawal draft kept | snackbar about needing internet | No |
| Search success | latest search cache | cached search available later | N/A |
| Ride details viewed | ride details cache + possible memory hit | faster repeat view / offline fallback | N/A |

## Failure Analysis Guidance

When an offline-capable screen misbehaves, it helps to classify the failure before changing code.

### Category 1: storage bootstrap failure

Symptoms:

- Hive box not found,
- local datasource throws before decode,
- all local fallbacks appear empty unexpectedly.

Checklist:

- verify `initializeAppHive()` runs during app startup,
- verify all relevant boxes are opened,
- verify the current branch did not drop a box during merge resolution.

### Category 2: decode and schema mismatch

Symptoms:

- local state disappears unexpectedly,
- cache always clears itself,
- old stored data no longer restores after a model change.

Checklist:

- verify `version` handling,
- verify field names still match JSON keys,
- verify migration strategy if shape changed,
- verify tests cover both valid and malformed payloads.

### Category 3: UI restoration mismatch

Symptoms:

- datasource restores correctly but screen fields remain empty,
- restored state exists internally but is not reflected visually,
- notice card shows stale metadata.

Checklist:

- verify controllers are updated,
- verify primitive screen state like dropdown values is also restored,
- verify `setState` occurs after restoration,
- verify the restore path runs only after widgets are mounted.

### Category 4: async gap correctness

Symptoms:

- analyzer warnings about `BuildContext` after `await`,
- occasional runtime issues after leaving a screen mid-request.

Checklist:

- verify `if (!mounted) return;` after async gaps,
- verify snackbars or navigation only happen when the widget is still alive,
- verify no stale closure is using old context assumptions.

## Engineering Guidance for Documentation Updates

This document should evolve whenever any of the following changes happen:

- a new Hive box is introduced,
- a draft or cache model adds/removes fields,
- a deferred action gains broader scope,
- a screen changes from online-only to cached fallback,
- a storage technology changes,
- a significant bug fix changes the semantics of synchronization or recovery.

In practice, the cheapest rule is:

- if a PR changes offline persistence behavior, it should update this guide.

## Suggested Future Sections if the Team Wants Even More Depth

If the team wants this document to grow further, the most useful additions would be:

- a sequence-diagram section for each screen,
- screenshots of restored draft states,
- sample corrupted payload examples,
- a storage migration history section,
- a per-feature test coverage table,
- a mapping between wiki claims and concrete repo files,
- a release checklist for offline-capable flows,
- a postmortem section documenting bugs already found and fixed.

## Quick Reference Checklist

- Create ride input should not be lost.
- Active ride status changes should be recoverable when feasible.
- Wallet reads should degrade gracefully.
- Withdrawal forms should be recoverable offline.
- Withdrawal submission must remain online-only.
- Invalid local cache should clear itself instead of crashing the app.
- User-facing offline behavior should be explicit, not silent.
- Sensitive flows should prefer correctness over cleverness.

## Appendix A: Current Offline-Relevant Files

```text
lib/shared/storage/app_hive.dart
lib/shared/cache/memory_lru_cache.dart
lib/shared/providers/connectivity_provider.dart

lib/features/rides/data/models/local_create_ride_draft_model.dart
lib/features/rides/data/models/local_pending_ride_status_action_model.dart
lib/features/rides/data/models/local_ride_search_cache_model.dart
lib/features/rides/data/models/local_ride_details_cache_model.dart

lib/features/rides/data/datasources/create_ride_draft_local_datasource.dart
lib/features/rides/data/datasources/active_ride_pending_action_local_datasource.dart
lib/features/rides/data/datasources/rides_search_local_datasource.dart
lib/features/rides/data/datasources/ride_details_local_datasource.dart

lib/features/wallet/data/models/local_wallet_summary_cache_model.dart
lib/features/wallet/data/models/local_withdrawal_request_draft_model.dart

lib/features/wallet/data/datasources/wallet_summary_local_datasource.dart
lib/features/wallet/data/datasources/withdrawal_request_draft_local_datasource.dart

lib/features/dashboard/data/models/dashboard_model.dart
lib/features/dashboard/data/datasources/dashboard_local_datasource.dart
lib/features/dashboard/presentation/providers/dashboard_providers.dart
lib/features/dashboard/presentation/screens/dashboard_screen.dart

lib/features/payments/data/models/local_payment_verification_cache_model.dart
lib/features/payments/data/datasources/payment_local_datasource.dart
lib/features/payments/presentation/providers/payment_provider.dart
lib/features/payments/presentation/screens/payment_screen.dart

lib/features/ride_history/data/models/ride_history_model.dart
lib/features/ride_history/data/datasources/ride_history_local_datasource.dart
lib/features/ride_history/data/repositories/ride_history_repository_impl.dart
lib/features/ride_history/presentation/providers/ride_history_providers.dart
lib/features/ride_history/presentation/screens/ride_history_screen.dart

lib/features/rides/presentation/screens/create_ride_screen.dart
lib/features/rides/presentation/screens/active_ride_screen.dart
lib/features/rides/presentation/screens/rides_search_screen.dart
lib/features/rides/presentation/screens/ride_details_screen.dart
lib/features/wallet/presentation/screens/wallet_screen.dart
lib/features/wallet/presentation/screens/withdrawal_request_screen.dart

test/support/ride_test_data.dart
test/features/rides/data/models/local_ride_search_cache_model_test.dart
test/features/rides/data/models/local_ride_details_cache_model_test.dart
test/features/rides/data/datasources/rides_search_local_datasource_test.dart
test/features/rides/data/datasources/ride_details_local_datasource_test.dart
```

## Appendix B: Decision Matrix

| Flow | Local persistence | Deferred sync | Online-only final commit | Cached fallback |
| --- | --- | --- | --- | --- |
| Create ride | Yes | Partial foundation | Yes | No |
| Active ride status | Yes | Yes | Depends on action | No |
| Dashboard | Yes | No | N/A | Yes |
| Payments | Minimal pending marker | Yes, for verification refresh | Yes | Partial status continuity |
| Ride history | Yes | No | N/A | Yes |
| Wallet summary | Yes | No | N/A | Yes |
| Withdrawal request | Yes | No | Yes | N/A |
| Ride search | Yes | No | N/A | Yes |
| Ride details | Yes | No | N/A | Yes |

## Appendix C: Engineering Principles Used

- Preserve user effort whenever safe.
- Prefer explicit state over magical retries.
- Use local persistence for resilience, not illusion.
- Treat malformed cache as disposable.
- Keep financial flows conservative.
- Keep identifiers correct in multi-entity writes.
- Add tests around persistence boundaries.
- Communicate cache state honestly to the user.

## Appendix D: Suggested Next Documentation Files

Future docs that would complement this one:

- `docs/payment-state-machine.md`
- `docs/cache-and-storage-inventory.md`
- `docs/manual-qa-offline-checklist.md`
- `docs/firebase-distribution-guide.md`
- `docs/analytics-pipeline-overview.md`
