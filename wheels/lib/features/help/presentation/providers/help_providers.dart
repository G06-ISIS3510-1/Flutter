import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/cache/help_articles_lru_cache.dart';
import '../../data/datasources/help_local_datasource.dart';
import '../../data/datasources/help_preferences_local_datasource.dart';
import '../../data/datasources/help_remote_datasource.dart';
import '../../data/isolates/help_search_index_isolate.dart';
import '../../data/repositories/help_repository_impl.dart';
import '../../data/services/help_analytics_service.dart';
import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';
import '../../domain/repositories/help_repository.dart';

// ----- Infrastructure singletons ------------------------------------------

final helpFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final helpArticlesLruCacheProvider = Provider<HelpArticlesLruCache>((ref) {
  final cache = HelpArticlesLruCache();
  ref.onDispose(cache.clear);
  return cache;
});

final helpLocalDataSourceProvider = Provider<HelpLocalDataSource>((ref) {
  final ds = HelpLocalDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

final helpRemoteDataSourceProvider = Provider<HelpRemoteDataSource>((ref) {
  return HelpRemoteDataSource(firestore: ref.watch(helpFirestoreProvider));
});

final helpPreferencesDataSourceProvider =
    Provider<HelpPreferencesLocalDataSource>((ref) {
  return HelpPreferencesLocalDataSource();
});

final helpSearchIsolateProvider = Provider<HelpSearchIsolate>((ref) {
  final isolate = HelpSearchIsolate();
  ref.onDispose(() => isolate.dispose());
  return isolate;
});

final helpRepositoryProvider = Provider<HelpRepository>((ref) {
  return HelpRepositoryImpl(
    localDataSource: ref.watch(helpLocalDataSourceProvider),
    remoteDataSource: ref.watch(helpRemoteDataSourceProvider),
    preferencesDataSource: ref.watch(helpPreferencesDataSourceProvider),
    articlesCache: ref.watch(helpArticlesLruCacheProvider),
  );
});

final helpAnalyticsServiceProvider = Provider<HelpAnalyticsService>((ref) {
  return HelpAnalyticsService(
    firestore: ref.watch(helpFirestoreProvider),
    analytics: ref.watch(firebaseAnalyticsProvider),
  );
});

// ----- Reactive corpus stream --------------------------------------------

final helpArticlesStreamProvider = StreamProvider<List<HelpArticle>>((ref) {
  final repo = ref.watch(helpRepositoryProvider);
  return repo.watchArticles();
});

/// Starts the Firestore -> Hive sync. Kept as a side-effect provider so the
/// subscription is cancelled when no one is listening to the help feature.
final helpRemoteSyncProvider = Provider<StreamSubscription<List<HelpArticle>>>(
  (ref) {
    final repo = ref.watch(helpRepositoryProvider);
    final subscription = repo.startRemoteSync();
    ref.onDispose(subscription.cancel);
    return subscription;
  },
);

/// Keeps the search isolate's corpus aligned with the local stream.
/// Spawns the isolate on the first emit and reissues `updateCorpus` on each
/// subsequent change.
final helpSearchSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<HelpArticle>>>(
    helpArticlesStreamProvider,
    (previous, next) {
      final articles = next.valueOrNull;
      if (articles == null || articles.isEmpty) {
        return;
      }
      ref.read(helpSearchIsolateProvider).updateCorpus(articles);
    },
    fireImmediately: true,
  );
});

// ----- Derived selectors -------------------------------------------------

final helpCategoryCountsProvider = Provider<Map<HelpCategory, int>>((ref) {
  final articles = ref.watch(helpArticlesStreamProvider).valueOrNull ?? const [];
  final counts = <HelpCategory, int>{};
  for (final article in articles) {
    counts[article.category] = (counts[article.category] ?? 0) + 1;
  }
  return counts;
});

final helpMostHelpfulProvider = Provider<List<HelpArticle>>((ref) {
  final articles = ref.watch(helpArticlesStreamProvider).valueOrNull ?? const [];
  final sorted = <HelpArticle>[...articles]
    ..sort((a, b) => b.netHelpfulness.compareTo(a.netHelpfulness));
  return sorted.take(5).toList(growable: false);
});

// ----- Query debounce ----------------------------------------------------

class HelpQueryState {
  const HelpQueryState({required this.raw, required this.debounced});

  final String raw;
  final String debounced;

  bool get hasDebouncedQuery => debounced.trim().isNotEmpty;

  HelpQueryState copyWith({String? raw, String? debounced}) {
    return HelpQueryState(
      raw: raw ?? this.raw,
      debounced: debounced ?? this.debounced,
    );
  }

  static const empty = HelpQueryState(raw: '', debounced: '');
}

class HelpQueryNotifier extends StateNotifier<HelpQueryState> {
  HelpQueryNotifier({Duration debounce = const Duration(milliseconds: 300)})
      : _debounce = debounce,
        super(HelpQueryState.empty);

  final Duration _debounce;
  Timer? _timer;

  void update(String value) {
    state = state.copyWith(raw: value);
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      state = state.copyWith(debounced: value.trim());
    });
  }

  void clear() {
    _timer?.cancel();
    state = HelpQueryState.empty;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final helpQueryProvider =
    StateNotifierProvider<HelpQueryNotifier, HelpQueryState>((ref) {
  return HelpQueryNotifier();
});

// ----- Category filter ---------------------------------------------------

final helpCategoryFilterProvider = StateProvider<HelpCategory?>((ref) => null);

// ----- Search results from isolate ---------------------------------------

final helpSearchResultsProvider =
    FutureProvider.autoDispose<List<HelpArticle>>((ref) async {
  final query = ref.watch(helpQueryProvider).debounced;
  if (query.isEmpty) {
    return const <HelpArticle>[];
  }

  // Ensure the isolate is being kept in sync.
  ref.watch(helpSearchSyncProvider);

  final isolate = ref.watch(helpSearchIsolateProvider);
  if (!isolate.isRunning) {
    return const <HelpArticle>[];
  }

  final ids = await isolate.search(query, limit: 20);
  if (ids.isEmpty) {
    return const <HelpArticle>[];
  }

  final repo = ref.watch(helpRepositoryProvider);
  final results = <HelpArticle>[];
  for (final id in ids) {
    final article = await repo.getArticle(id);
    if (article != null) {
      results.add(article);
    }
  }
  return results;
});

// ----- Recently viewed ---------------------------------------------------

class HelpRecentlyViewedNotifier extends StateNotifier<List<String>> {
  HelpRecentlyViewedNotifier() : super(const <String>[]);

  static const int maxEntries = 5;

  void markViewed(String articleId) {
    final next = <String>[
      articleId,
      ...state.where((id) => id != articleId),
    ];
    if (next.length > maxEntries) {
      next.removeRange(maxEntries, next.length);
    }
    state = List<String>.unmodifiable(next);
  }

  void clear() {
    state = const <String>[];
  }
}

final helpRecentlyViewedProvider =
    StateNotifierProvider<HelpRecentlyViewedNotifier, List<String>>((ref) {
  return HelpRecentlyViewedNotifier();
});

final helpRecentlyViewedArticlesProvider = Provider<List<HelpArticle>>((ref) {
  final ids = ref.watch(helpRecentlyViewedProvider);
  if (ids.isEmpty) {
    return const <HelpArticle>[];
  }
  final articles = ref.watch(helpArticlesStreamProvider).valueOrNull ?? const [];
  if (articles.isEmpty) {
    return const <HelpArticle>[];
  }
  final byId = <String, HelpArticle>{
    for (final article in articles) article.id: article,
  };
  final resolved = <HelpArticle>[];
  for (final id in ids) {
    final article = byId[id];
    if (article != null) {
      resolved.add(article);
    }
  }
  return resolved;
});

// ----- Session id for analytics ------------------------------------------

class HelpSessionIdNotifier extends StateNotifier<String> {
  HelpSessionIdNotifier() : super(_generate());

  void rotate() {
    state = _generate();
  }

  static String _generate() {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rng = math.Random();
    final tail = rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'help-$ts-$tail';
  }
}

final helpSessionIdProvider =
    StateNotifierProvider<HelpSessionIdNotifier, String>((ref) {
  return HelpSessionIdNotifier();
});

// ----- Current user id ---------------------------------------------------

String currentHelpUserId() {
  final auth = firebase_auth.FirebaseAuth.instance.currentUser;
  return auth?.uid ?? 'anonymous';
}

@visibleForTesting
HelpQueryState debugBuildHelpQueryState({
  required String raw,
  required String debounced,
}) {
  return HelpQueryState(raw: raw, debounced: debounced);
}
