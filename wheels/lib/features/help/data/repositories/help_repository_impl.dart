import 'dart:async';

import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_feedback.dart';
import '../../domain/repositories/help_repository.dart';
import '../cache/help_articles_lru_cache.dart';
import '../datasources/help_feedback_pending_local_datasource.dart';
import '../datasources/help_local_datasource.dart';
import '../datasources/help_preferences_local_datasource.dart';
import '../datasources/help_remote_datasource.dart';

class HelpRepositoryImpl implements HelpRepository {
  HelpRepositoryImpl({
    required HelpLocalDataSource localDataSource,
    required HelpRemoteDataSource remoteDataSource,
    required HelpPreferencesLocalDataSource preferencesDataSource,
    required HelpArticlesLruCache articlesCache,
    HelpFeedbackPendingLocalDataSource feedbackPendingDataSource =
        const HelpFeedbackPendingLocalDataSource(),
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _preferences = preferencesDataSource,
       _articlesCache = articlesCache,
       _feedbackPending = feedbackPendingDataSource;

  final HelpLocalDataSource _local;
  final HelpRemoteDataSource _remote;
  final HelpPreferencesLocalDataSource _preferences;
  final HelpArticlesLruCache _articlesCache;
  final HelpFeedbackPendingLocalDataSource _feedbackPending;

  @override
  Stream<List<HelpArticle>> watchArticles() {
    return _local.watchArticles().map((articles) {
      for (final article in articles) {
        _articlesCache.put(article);
      }
      return articles;
    });
  }

  @override
  Future<HelpArticle?> getArticle(String articleId) async {
    final cached = _articlesCache.get(articleId);
    if (cached != null) {
      return cached;
    }

    final local = await _local.getArticle(articleId);
    if (local != null) {
      _articlesCache.put(local);
      return local;
    }

    final remote = await _remote.getArticle(articleId);
    if (remote == null) {
      return null;
    }

    await _local.upsertArticle(remote);
    _articlesCache.put(remote);
    return remote;
  }

  @override
  Future<List<HelpArticle>> getCachedArticles() {
    return _local.loadArticles();
  }

  @override
  Future<void> upsertArticle(HelpArticle article) async {
    await _local.upsertArticle(article);
    _articlesCache.put(article);
  }

  @override
  Future<void> upsertArticles(List<HelpArticle> articles) async {
    await _local.upsertArticles(articles);
    for (final article in articles) {
      _articlesCache.put(article);
    }
  }

  @override
  Future<void> clearArticle(String articleId) async {
    await _local.deleteArticle(articleId);
    _articlesCache.invalidate(articleId);
  }

  @override
  StreamSubscription<List<HelpArticle>> startRemoteSync() {
    return _remote.watchArticles().listen((articles) async {
      if (articles.isEmpty) {
        return;
      }
      for (final article in articles) {
        _articlesCache.invalidate(article.id);
      }
      await _local.upsertArticles(articles);
    });
  }

  @override
  Stream<List<HelpBookmark>> watchBookmarks(String userId) {
    return _local.watchBookmarks(userId);
  }

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String articleId,
  }) {
    return _local.isBookmarked(userId: userId, articleId: articleId);
  }

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String articleId,
  }) async {
    final already = await _local.isBookmarked(
      userId: userId,
      articleId: articleId,
    );
    if (already) {
      await _local.deleteBookmark(userId: userId, articleId: articleId);
      return;
    }
    await _local.upsertBookmark(
      HelpBookmark(
        userId: userId,
        articleId: articleId,
        savedAt: DateTime.now().toUtc(),
        pendingSync: true,
      ),
    );
  }

  @override
  Future<List<HelpBookmark>> loadPendingBookmarks() {
    return _local.loadPendingBookmarks();
  }

  @override
  Future<void> markBookmarkSynced({
    required String userId,
    required String articleId,
  }) {
    return _local.markBookmarkSynced(userId: userId, articleId: articleId);
  }

  @override
  Future<void> submitFeedback(HelpFeedback feedback) async {
    // Persist the user's vote first so the UI can restore it across
    // navigations even after the pending queue is drained by the worker.
    await _local.saveUserVote(
      userId: feedback.userId,
      articleId: feedback.articleId,
      vote: feedback.vote,
    );
    await _feedbackPending.enqueue(feedback);
  }

  @override
  Future<HelpFeedbackVote?> loadUserVote({
    required String userId,
    required String articleId,
  }) {
    return _local.loadUserVote(userId: userId, articleId: articleId);
  }

  @override
  Future<void> clearUserVote({
    required String userId,
    required String articleId,
  }) {
    return _local.clearUserVote(userId: userId, articleId: articleId);
  }

  @override
  Future<List<HelpFeedback>> loadPendingFeedback() {
    return _feedbackPending.loadPending();
  }

  @override
  Future<void> removePendingFeedback(String feedbackId) {
    return _feedbackPending.remove(feedbackId);
  }

  @override
  Future<String?> loadLastQuery(String userId) {
    return _preferences.loadLastQuery(userId);
  }

  @override
  Future<void> saveLastQuery({
    required String userId,
    required String query,
  }) {
    return _preferences.saveLastQuery(userId: userId, query: query);
  }

  @override
  Future<void> clearLastQuery(String userId) {
    return _preferences.clearLastQuery(userId);
  }
}
