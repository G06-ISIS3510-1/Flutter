import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels/features/help/data/cache/help_articles_lru_cache.dart';
import 'package:wheels/features/help/data/datasources/help_local_datasource.dart';
import 'package:wheels/features/help/data/datasources/help_preferences_local_datasource.dart';
import 'package:wheels/features/help/data/datasources/help_remote_datasource.dart';
import 'package:wheels/features/help/data/repositories/help_repository_impl.dart';
import 'package:wheels/features/help/domain/entities/help_article.dart';
import 'package:wheels/features/help/domain/entities/help_feedback.dart';
import 'package:wheels/shared/storage/app_hive.dart';

import '../../../../support/help_test_data.dart';

class _FakeHelpRemoteDataSource implements HelpRemoteDataSource {
  _FakeHelpRemoteDataSource();

  final Map<String, HelpArticle> articles = <String, HelpArticle>{};
  int getArticleCalls = 0;
  int watchArticlesCalls = 0;

  @override
  Future<HelpArticle?> getArticle(String articleId) async {
    getArticleCalls += 1;
    return articles[articleId];
  }

  @override
  Stream<List<HelpArticle>> watchArticles() {
    watchArticlesCalls += 1;
    return Stream<List<HelpArticle>>.value(articles.values.toList());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<String> articlesBox;
  late Box<String> bookmarksBox;
  late Box<String> userVotesBox;
  late Box<String> feedbackPendingBox;
  late HelpLocalDataSource local;
  late HelpArticlesLruCache lru;
  late _FakeHelpRemoteDataSource remote;
  late HelpPreferencesLocalDataSource preferences;
  late HelpRepositoryImpl repository;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('help-repo-test');
    Hive.init(hiveDirectory.path);
    articlesBox = await Hive.openBox<String>(AppHiveBoxes.helpArticles);
    bookmarksBox = await Hive.openBox<String>(AppHiveBoxes.helpBookmarks);
    userVotesBox = await Hive.openBox<String>(AppHiveBoxes.helpUserVotes);
    feedbackPendingBox =
        await Hive.openBox<String>(AppHiveBoxes.helpFeedbackPending);
  });

  tearDown(() async {
    await articlesBox.clear();
    await bookmarksBox.clear();
    await userVotesBox.clear();
    await feedbackPendingBox.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await local.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    local = HelpLocalDataSource();
    lru = HelpArticlesLruCache(capacity: 5);
    remote = _FakeHelpRemoteDataSource();
    preferences = HelpPreferencesLocalDataSource();
    repository = HelpRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      preferencesDataSource: preferences,
      articlesCache: lru,
    );
  });

  group('HelpRepositoryImpl.getArticle layered reads', () {
    test('returns the LRU entry first without touching Hive or remote', () async {
      final article = buildHelpArticle(id: 'cached-id', title: 'From LRU');
      lru.put(article);

      final result = await repository.getArticle('cached-id');

      expect(result, isNotNull);
      expect(result!.title, 'From LRU');
      expect(remote.getArticleCalls, 0);
      expect(articlesBox.containsKey('cached-id'), isFalse);
    });

    test('falls back to Hive when LRU misses and repopulates the LRU', () async {
      final article = buildHelpArticle(id: 'hive-id', title: 'From Hive');
      await local.upsertArticle(article);
      lru.clear();

      final result = await repository.getArticle('hive-id');

      expect(result, isNotNull);
      expect(result!.title, 'From Hive');
      expect(remote.getArticleCalls, 0);
      expect(lru.get('hive-id'), isNotNull);
    });

    test('falls back to remote when LRU and Hive miss, then caches result', () async {
      final article = buildHelpArticle(id: 'remote-id', title: 'From Remote');
      remote.articles['remote-id'] = article;

      final result = await repository.getArticle('remote-id');

      expect(result, isNotNull);
      expect(result!.title, 'From Remote');
      expect(remote.getArticleCalls, 1);
      expect(lru.get('remote-id'), isNotNull);
      expect(await local.getArticle('remote-id'), isNotNull);
    });

    test('returns null when neither LRU, Hive, nor remote have the article', () async {
      final result = await repository.getArticle('missing-id');

      expect(result, isNull);
      expect(remote.getArticleCalls, 1);
    });
  });

  group('HelpRepositoryImpl bookmark and last-query passthrough', () {
    test('toggleBookmark adds and then removes', () async {
      await repository.toggleBookmark(userId: 'u', articleId: 'a');
      expect(
        await repository.isBookmarked(userId: 'u', articleId: 'a'),
        isTrue,
      );

      await repository.toggleBookmark(userId: 'u', articleId: 'a');
      expect(
        await repository.isBookmarked(userId: 'u', articleId: 'a'),
        isFalse,
      );
    });

    test('saveLastQuery and loadLastQuery round-trip via SharedPreferences', () async {
      await repository.saveLastQuery(userId: 'u', query: 'card refund');

      expect(await repository.loadLastQuery('u'), 'card refund');
    });

    test('saveLastQuery with empty string clears the entry', () async {
      await repository.saveLastQuery(userId: 'u', query: 'something');
      await repository.saveLastQuery(userId: 'u', query: '   ');

      expect(await repository.loadLastQuery('u'), isNull);
    });
  });

  group('HelpRepositoryImpl feedback persistence', () {
    HelpFeedback buildFeedback({
      String id = 'fb-1',
      String articleId = 'a-1',
      String userId = 'u-1',
      HelpFeedbackVote vote = HelpFeedbackVote.upvote,
    }) {
      return HelpFeedback(
        id: id,
        articleId: articleId,
        userId: userId,
        vote: vote,
        createdAt: DateTime.utc(2026, 5, 21),
      );
    }

    test('submitFeedback persists the user vote AND enqueues to pending', () async {
      await repository.submitFeedback(buildFeedback());

      expect(
        await repository.loadUserVote(userId: 'u-1', articleId: 'a-1'),
        HelpFeedbackVote.upvote,
      );
      expect(await repository.loadPendingFeedback(), hasLength(1));
    });

    test('user vote survives the pending queue being drained', () async {
      await repository.submitFeedback(buildFeedback());

      // Simulate the sync worker draining the queue successfully.
      await repository.removePendingFeedback('fb-1');

      expect(await repository.loadPendingFeedback(), isEmpty);
      expect(
        await repository.loadUserVote(userId: 'u-1', articleId: 'a-1'),
        HelpFeedbackVote.upvote,
      );
    });

    test('changing vote overwrites the persisted user vote', () async {
      await repository.submitFeedback(buildFeedback());
      await repository.submitFeedback(
        buildFeedback(id: 'fb-2', vote: HelpFeedbackVote.downvote),
      );

      expect(
        await repository.loadUserVote(userId: 'u-1', articleId: 'a-1'),
        HelpFeedbackVote.downvote,
      );
    });

    test('clearUserVote removes the persisted entry', () async {
      await repository.submitFeedback(buildFeedback());
      await repository.clearUserVote(userId: 'u-1', articleId: 'a-1');

      expect(
        await repository.loadUserVote(userId: 'u-1', articleId: 'a-1'),
        isNull,
      );
    });
  });
}
