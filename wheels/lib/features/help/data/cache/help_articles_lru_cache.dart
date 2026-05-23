import '../../../../shared/cache/memory_lru_cache.dart';
import '../../domain/entities/help_article.dart';

/// In-memory LRU cache for `HelpArticle` instances keyed by `articleId`.
///
/// **Capacity:** 30 entries. A help session typically visits 3–8 articles
/// (search → main article → related → back). 30 keeps the entire session hot
/// across back-navigations and "related article" taps without bloating
/// memory. Articles are small structs (~2 KB each), so the worst-case
/// footprint stays under 100 KB.
///
/// **Eviction:** least-recently-used. `get` promotes the accessed entry to
/// most-recent; `put` evicts the least-recent entry when capacity is exceeded.
///
/// **Invalidation:**
/// - Any Firestore update for an `articleId` triggers `invalidate(articleId)`
///   so the next read repopulates the cache from Hive (or remote).
/// - `clear()` is called when the user signs out or the article corpus is
///   reseeded with a new corpus version.
class HelpArticlesLruCache {
  HelpArticlesLruCache({int capacity = defaultCapacity})
    : _cache = MemoryLruCache<String, HelpArticle>(maxEntries: capacity);

  static const int defaultCapacity = 30;

  final MemoryLruCache<String, HelpArticle> _cache;

  HelpArticle? get(String articleId) => _cache.get(articleId);

  void put(HelpArticle article) => _cache.put(article.id, article);

  void invalidate(String articleId) => _cache.remove(articleId);

  void clear() => _cache.clear();

  bool contains(String articleId) => _cache.containsKey(articleId);
}
