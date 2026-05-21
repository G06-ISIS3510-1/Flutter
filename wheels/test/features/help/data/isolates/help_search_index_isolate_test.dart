import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/help/data/isolates/help_search_index_isolate.dart';
import 'package:wheels/features/help/domain/entities/help_article.dart';

import '../../../../support/help_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HelpSearchIsolate end-to-end', () {
    late HelpSearchIsolate isolate;

    setUp(() {
      isolate = HelpSearchIsolate();
    });

    tearDown(() async {
      await isolate.dispose();
    });

    test('returns ranked ids for a query after start', () async {
      final corpus = <HelpArticle>[
        buildHelpArticle(id: 'refund', title: 'How refunds work', upvotes: 90),
        buildHelpArticle(id: 'verify', title: 'Verifying your account', upvotes: 140),
        buildHelpArticle(id: 'cancel', title: 'Cancelling a ride', upvotes: 150),
      ];

      await isolate.start(corpus);
      final result = await isolate.search('refunds');

      expect(result, contains('refund'));
      expect(result.first, 'refund');
    });

    test('updateCorpus replaces the index with a new corpus', () async {
      final initial = <HelpArticle>[
        buildHelpArticle(id: 'old', title: 'Old article about refunds'),
      ];
      final next = <HelpArticle>[
        buildHelpArticle(id: 'new', title: 'New article about refunds'),
      ];

      await isolate.start(initial);
      final firstResult = await isolate.search('refunds');
      expect(firstResult, <String>['old']);

      await isolate.updateCorpus(next);
      final secondResult = await isolate.search('refunds');
      expect(secondResult, <String>['new']);
    });

    test('search before start returns an empty list', () async {
      final result = await isolate.search('whatever');
      expect(result, isEmpty);
      expect(isolate.isRunning, isFalse);
    });

    test('dispose stops the isolate and subsequent searches return empty', () async {
      await isolate.start(<HelpArticle>[
        buildHelpArticle(id: 'a', title: 'About something'),
      ]);
      await isolate.dispose();

      final result = await isolate.search('something');
      expect(result, isEmpty);
      expect(isolate.isRunning, isFalse);
    });

    test('search honors the limit parameter', () async {
      final corpus = <HelpArticle>[
        for (var i = 0; i < 5; i++)
          buildHelpArticle(id: 'ride-$i', title: 'Ride article number $i'),
      ];

      await isolate.start(corpus);
      final result = await isolate.search('ride', limit: 2);

      expect(result.length, lessThanOrEqualTo(2));
    });
  });
}
