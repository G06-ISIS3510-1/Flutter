import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/help/data/isolates/help_search_index.dart';
import 'package:wheels/features/help/domain/entities/help_category.dart';

import '../../../../support/help_test_data.dart';

void main() {
  group('runHelpSearchQuery — small corpus', () {
    final corpus = <dynamic>[
      buildHelpArticle(
        id: 'verify-email',
        title: 'Verifying your Uniandes account',
        category: HelpCategory.account,
        upvotes: 140,
      ),
      buildHelpArticle(
        id: 'refund',
        title: 'How refunds work',
        category: HelpCategory.payments,
        upvotes: 90,
      ),
      buildHelpArticle(
        id: 'pickup-zones',
        title: 'Setting your preferred pickup zones',
        category: HelpCategory.drivers,
        upvotes: 80,
      ),
      buildHelpArticle(
        id: 'cancel-ride',
        title: 'Cancelling a ride before departure',
        category: HelpCategory.rides,
        upvotes: 150,
      ),
      buildHelpArticle(
        id: 'verify-car',
        title: 'Verifying you are getting into the right car',
        category: HelpCategory.safety,
        upvotes: 175,
      ),
    ].cast();

    late HelpSearchIndexData index;

    setUp(() {
      index = buildHelpSearchIndex(corpus.cast());
    });

    test('returns empty list for empty query', () {
      expect(runHelpSearchQuery(index, '', 20), isEmpty);
      expect(runHelpSearchQuery(index, '   ', 20), isEmpty);
    });

    test('returns empty list for limit <= 0', () {
      expect(runHelpSearchQuery(index, 'verify', 0), isEmpty);
      expect(runHelpSearchQuery(index, 'verify', -1), isEmpty);
    });

    test('exact token match in title ranks above other fields', () {
      final result = runHelpSearchQuery(index, 'refunds', 20);

      expect(result, contains('refund'));
      expect(result.first, 'refund');
    });

    test('multiple title hits — tie-break uses upvotes', () {
      // Both "verify-email" and "verify-car" have "verifying" in title.
      // "verify-car" has more upvotes (175 vs 140), so it ranks first.
      final result = runHelpSearchQuery(index, 'verifying', 20);

      expect(result, containsAll(<String>['verify-email', 'verify-car']));
      expect(result.first, 'verify-car');
    });

    test('prefix match ranks below exact match but still returns', () {
      // "cancell" should prefix-match "cancelling".
      final result = runHelpSearchQuery(index, 'cancell', 20);

      expect(result, contains('cancel-ride'));
    });

    test('typo within Levenshtein bound still ranks the article', () {
      // "verifyng" (missing one char) should fuzzy-match "verifying".
      final result = runHelpSearchQuery(index, 'verifyng', 20);

      expect(result.isNotEmpty, isTrue);
      expect(
        result.any((id) => id == 'verify-email' || id == 'verify-car'),
        isTrue,
      );
    });

    test('query that does not match any article returns empty', () {
      final result = runHelpSearchQuery(index, 'xyzzy', 20);
      expect(result, isEmpty);
    });

    test('limit caps the number of returned ids', () {
      // "ride" matches several articles via title/tag/body.
      final result = runHelpSearchQuery(index, 'ride', 2);
      expect(result.length, lessThanOrEqualTo(2));
    });

    test('tag tokens contribute to score', () {
      // All seed articles share the tags ["demo", "test"] via the helper.
      final result = runHelpSearchQuery(index, 'demo', 20);
      expect(result.length, corpus.length);
    });
  });

  group('tokenization edge cases', () {
    test('diacritics are normalized so accented query matches plain index', () {
      final corpus = <dynamic>[
        buildHelpArticle(id: 'tildes', title: 'Cancelacion de viaje'),
      ].cast<dynamic>();
      final index = buildHelpSearchIndex(corpus.cast());

      final result = runHelpSearchQuery(index, 'cancelación', 20);
      expect(result, <String>['tildes']);
    });

    test('1-character tokens are dropped', () {
      final corpus = <dynamic>[
        buildHelpArticle(id: 'short', title: 'a b'),
      ].cast<dynamic>();
      final index = buildHelpSearchIndex(corpus.cast());

      final result = runHelpSearchQuery(index, 'a', 20);
      expect(result, isEmpty);
    });
  });
}
