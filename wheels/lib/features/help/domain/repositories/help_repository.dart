import 'dart:async';

import '../entities/help_article.dart';
import '../entities/help_feedback.dart';

abstract class HelpRepository {
  Stream<List<HelpArticle>> watchArticles();

  Future<HelpArticle?> getArticle(String articleId);

  Future<List<HelpArticle>> getCachedArticles();

  Future<void> upsertArticle(HelpArticle article);

  Future<void> upsertArticles(List<HelpArticle> articles);

  Future<void> clearArticle(String articleId);

  StreamSubscription<List<HelpArticle>> startRemoteSync();

  Stream<List<HelpBookmark>> watchBookmarks(String userId);

  Future<bool> isBookmarked({required String userId, required String articleId});

  Future<void> toggleBookmark({
    required String userId,
    required String articleId,
  });

  Future<List<HelpBookmark>> loadPendingBookmarks();

  Future<void> markBookmarkSynced({
    required String userId,
    required String articleId,
  });

  Future<void> submitFeedback(HelpFeedback feedback);

  Future<HelpFeedbackVote?> loadUserVote({
    required String userId,
    required String articleId,
  });

  Future<void> clearUserVote({
    required String userId,
    required String articleId,
  });

  Future<List<HelpFeedback>> loadPendingFeedback();

  Future<void> removePendingFeedback(String feedbackId);

  Future<String?> loadLastQuery(String userId);

  Future<void> saveLastQuery({required String userId, required String query});

  Future<void> clearLastQuery(String userId);
}
