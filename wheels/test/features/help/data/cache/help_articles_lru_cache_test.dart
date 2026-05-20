import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/help/data/cache/help_articles_lru_cache.dart';

import '../../../../support/help_test_data.dart';

void main() {
  group('HelpArticlesLruCache', () {
    test('returns null on miss', () {
      final cache = HelpArticlesLruCache(capacity: 3);

      expect(cache.get('missing'), isNull);
    });

    test('put then get returns the cached article', () {
      final cache = HelpArticlesLruCache(capacity: 3);
      final article = buildHelpArticle(id: 'a-1');

      cache.put(article);

      expect(cache.get('a-1'), isNotNull);
      expect(cache.get('a-1')!.id, 'a-1');
      expect(cache.contains('a-1'), isTrue);
    });

    test('evicts least-recently-used entry when capacity is exceeded', () {
      final cache = HelpArticlesLruCache(capacity: 2);
      final a = buildHelpArticle(id: 'a');
      final b = buildHelpArticle(id: 'b');
      final c = buildHelpArticle(id: 'c');

      cache.put(a);
      cache.put(b);
      cache.get('a'); // a is now most-recently-used
      cache.put(c); // evicts b

      expect(cache.get('a'), isNotNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNotNull);
    });

    test('invalidate removes a single entry without touching the rest', () {
      final cache = HelpArticlesLruCache(capacity: 3);
      cache.put(buildHelpArticle(id: 'a'));
      cache.put(buildHelpArticle(id: 'b'));

      cache.invalidate('a');

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNotNull);
    });

    test('clear empties the whole cache', () {
      final cache = HelpArticlesLruCache(capacity: 3);
      cache.put(buildHelpArticle(id: 'a'));
      cache.put(buildHelpArticle(id: 'b'));

      cache.clear();

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });

    test('default capacity is 30', () {
      expect(HelpArticlesLruCache.defaultCapacity, 30);
    });
  });
}
