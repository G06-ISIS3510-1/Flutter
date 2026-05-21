import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wheels/features/help/data/datasources/help_local_datasource.dart';
import 'package:wheels/features/help/data/models/help_article_model.dart';
import 'package:wheels/features/help/data/models/help_bookmark_model.dart';
import 'package:wheels/features/help/domain/entities/help_feedback.dart';
import 'package:wheels/shared/storage/app_hive.dart';

import '../../../../support/help_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<String> articlesBox;
  late Box<String> bookmarksBox;
  late HelpLocalDataSource dataSource;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('help-local-test');
    Hive.init(hiveDirectory.path);
    articlesBox = await Hive.openBox<String>(AppHiveBoxes.helpArticles);
    bookmarksBox = await Hive.openBox<String>(AppHiveBoxes.helpBookmarks);
  });

  tearDown(() async {
    await articlesBox.clear();
    await bookmarksBox.clear();
    await dataSource.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  setUp(() {
    dataSource = HelpLocalDataSource();
  });

  group('HelpLocalDataSource articles', () {
    test('loadArticles returns empty list when box is empty', () async {
      final articles = await dataSource.loadArticles();
      expect(articles, isEmpty);
    });

    test('upsertArticle persists and getArticle retrieves it', () async {
      final article = buildHelpArticle(id: 'a-1', title: 'Verifying email');

      await dataSource.upsertArticle(article);
      final restored = await dataSource.getArticle('a-1');

      expect(restored, isNotNull);
      expect(restored!.title, 'Verifying email');
      expect(articlesBox.get('a-1'), isNotNull);
    });

    test('upsertArticles persists a batch and loadArticles returns all', () async {
      await dataSource.upsertArticles([
        buildHelpArticle(id: 'a-1', title: 'Alpha'),
        buildHelpArticle(id: 'a-2', title: 'Beta'),
        buildHelpArticle(id: 'a-3', title: 'Gamma'),
      ]);

      final articles = await dataSource.loadArticles();

      expect(articles, hasLength(3));
      expect(articles.map((a) => a.id), containsAll(<String>['a-1', 'a-2', 'a-3']));
    });

    test('invalid Hive payload is dropped when loading the corpus', () async {
      await dataSource.upsertArticle(buildHelpArticle(id: 'valid'));
      await articlesBox.put('corrupt-id', '{not valid json');

      final articles = await dataSource.loadArticles();

      expect(articles, hasLength(1));
      expect(articles.single.id, 'valid');
      expect(articlesBox.containsKey('corrupt-id'), isFalse);
    });

    test('invalid Hive payload is dropped when getArticle is called', () async {
      await articlesBox.put('corrupt-id', '{also not valid');

      final result = await dataSource.getArticle('corrupt-id');

      expect(result, isNull);
      expect(articlesBox.containsKey('corrupt-id'), isFalse);
    });

    test('decodable payload from a previous run is restored as the matching entity', () async {
      final model = HelpArticleModel.fromEntity(buildHelpArticle(id: 'pre-existing'));
      await articlesBox.put('pre-existing', jsonEncode(model.toJson()));

      final restored = await dataSource.getArticle('pre-existing');

      expect(restored, isNotNull);
      expect(restored!.id, 'pre-existing');
    });

    test('deleteArticle removes the Hive entry', () async {
      await dataSource.upsertArticle(buildHelpArticle(id: 'gone'));
      await dataSource.deleteArticle('gone');

      expect(await dataSource.getArticle('gone'), isNull);
      expect(articlesBox.containsKey('gone'), isFalse);
    });
  });

  group('HelpLocalDataSource bookmarks', () {
    test('toggle/upsert and read bookmarks per user', () async {
      final bookmark = HelpBookmark(
        articleId: 'a-1',
        userId: 'u-1',
        savedAt: DateTime.utc(2026, 5, 20),
        pendingSync: true,
      );

      await dataSource.upsertBookmark(bookmark);
      final bookmarks = await dataSource.loadBookmarks('u-1');

      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.articleId, 'a-1');
      expect(
        await dataSource.isBookmarked(userId: 'u-1', articleId: 'a-1'),
        isTrue,
      );
    });

    test('bookmarks from another user are not returned', () async {
      await dataSource.upsertBookmark(
        HelpBookmark(
          articleId: 'a-1',
          userId: 'u-1',
          savedAt: DateTime.utc(2026, 5, 20),
          pendingSync: true,
        ),
      );
      await dataSource.upsertBookmark(
        HelpBookmark(
          articleId: 'a-2',
          userId: 'u-2',
          savedAt: DateTime.utc(2026, 5, 20),
          pendingSync: true,
        ),
      );

      final byUserOne = await dataSource.loadBookmarks('u-1');
      final byUserTwo = await dataSource.loadBookmarks('u-2');

      expect(byUserOne.map((b) => b.articleId), <String>['a-1']);
      expect(byUserTwo.map((b) => b.articleId), <String>['a-2']);
    });

    test('invalid bookmark payload is dropped during load', () async {
      await dataSource.upsertBookmark(
        HelpBookmark(
          articleId: 'a-good',
          userId: 'u-1',
          savedAt: DateTime.utc(2026, 5, 20),
          pendingSync: false,
        ),
      );
      await bookmarksBox.put('bookmark:u-1:a-broken', '{not json}');

      final bookmarks = await dataSource.loadBookmarks('u-1');

      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.articleId, 'a-good');
      expect(bookmarksBox.containsKey('bookmark:u-1:a-broken'), isFalse);
    });

    test(
      'decodable bookmark from a previous run is restored as the matching entity',
      () async {
        final model = HelpBookmarkModel.fromEntity(
          HelpBookmark(
            articleId: 'a-pre',
            userId: 'u-1',
            savedAt: DateTime.utc(2026, 5, 20),
            pendingSync: true,
          ),
        );
        await bookmarksBox.put('bookmark:u-1:a-pre', jsonEncode(model.toJson()));

        final bookmarks = await dataSource.loadBookmarks('u-1');

        expect(bookmarks, hasLength(1));
        expect(bookmarks.single.articleId, 'a-pre');
      },
    );
  });
}
