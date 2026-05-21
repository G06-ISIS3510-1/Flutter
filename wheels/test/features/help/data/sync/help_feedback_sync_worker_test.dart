import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/help/data/sync/help_feedback_sync_worker.dart';
import 'package:wheels/features/help/domain/entities/help_article.dart';
import 'package:wheels/features/help/domain/entities/help_feedback.dart';
import 'package:wheels/features/help/domain/repositories/help_repository.dart';

class _FakeHelpRepository implements HelpRepository {
  final List<HelpFeedback> pendingFeedback = <HelpFeedback>[];
  final List<HelpBookmark> pendingBookmarks = <HelpBookmark>[];
  final List<String> removedFeedbackIds = <String>[];
  final List<(String, String)> syncedBookmarks = <(String, String)>[];

  @override
  Future<List<HelpFeedback>> loadPendingFeedback() async {
    return List<HelpFeedback>.from(pendingFeedback);
  }

  @override
  Future<void> removePendingFeedback(String feedbackId) async {
    pendingFeedback.removeWhere((f) => f.id == feedbackId);
    removedFeedbackIds.add(feedbackId);
  }

  @override
  Future<List<HelpBookmark>> loadPendingBookmarks() async {
    return List<HelpBookmark>.from(pendingBookmarks);
  }

  @override
  Future<void> markBookmarkSynced({
    required String userId,
    required String articleId,
  }) async {
    pendingBookmarks.removeWhere(
      (b) => b.userId == userId && b.articleId == articleId,
    );
    syncedBookmarks.add((userId, articleId));
  }

  // The worker does not exercise any of the methods below.
  @override
  Future<void> submitFeedback(HelpFeedback feedback) async {
    throw UnimplementedError();
  }

  @override
  Future<HelpFeedbackVote?> loadUserVote({
    required String userId,
    required String articleId,
  }) async {
    return null;
  }

  @override
  Future<void> clearUserVote({
    required String userId,
    required String articleId,
  }) async {}

  @override
  Stream<List<HelpArticle>> watchArticles() => const Stream.empty();

  @override
  Future<HelpArticle?> getArticle(String articleId) async => null;

  @override
  Future<List<HelpArticle>> getCachedArticles() async => const <HelpArticle>[];

  @override
  Future<void> upsertArticle(HelpArticle article) async {}

  @override
  Future<void> upsertArticles(List<HelpArticle> articles) async {}

  @override
  Future<void> clearArticle(String articleId) async {}

  @override
  StreamSubscription<List<HelpArticle>> startRemoteSync() {
    return const Stream<List<HelpArticle>>.empty().listen((_) {});
  }

  @override
  Stream<List<HelpBookmark>> watchBookmarks(String userId) =>
      const Stream.empty();

  @override
  Future<bool> isBookmarked({
    required String userId,
    required String articleId,
  }) async {
    return false;
  }

  @override
  Future<void> toggleBookmark({
    required String userId,
    required String articleId,
  }) async {}

  @override
  Future<String?> loadLastQuery(String userId) async => null;

  @override
  Future<void> saveLastQuery({
    required String userId,
    required String query,
  }) async {}

  @override
  Future<void> clearLastQuery(String userId) async {}
}

HelpFeedback _buildFeedback(String id, HelpFeedbackVote vote) {
  return HelpFeedback(
    id: id,
    articleId: 'article-$id',
    userId: 'user-1',
    vote: vote,
    createdAt: DateTime.utc(2026, 5, 21),
  );
}

HelpBookmark _buildBookmark(String articleId) {
  return HelpBookmark(
    userId: 'user-1',
    articleId: articleId,
    savedAt: DateTime.utc(2026, 5, 21),
    pendingSync: true,
  );
}

void main() {
  group('HelpFeedbackSyncWorker', () {
    late _FakeHelpRepository repo;
    late StreamController<bool> connectivity;
    late List<HelpFeedback> flushedFeedback;
    late List<HelpBookmark> flushedBookmarks;
    late HelpFeedbackSyncWorker worker;

    setUp(() {
      repo = _FakeHelpRepository();
      connectivity = StreamController<bool>.broadcast();
      flushedFeedback = <HelpFeedback>[];
      flushedBookmarks = <HelpBookmark>[];
    });

    tearDown(() async {
      await worker.dispose();
      await connectivity.close();
    });

    test('drains both queues when connectivity transitions to online', () async {
      repo.pendingFeedback.addAll(<HelpFeedback>[
        _buildFeedback('f1', HelpFeedbackVote.upvote),
        _buildFeedback('f2', HelpFeedbackVote.downvote),
      ]);
      repo.pendingBookmarks.addAll(<HelpBookmark>[
        _buildBookmark('a1'),
        _buildBookmark('a2'),
        _buildBookmark('a3'),
      ]);

      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async => flushedFeedback.add(f),
        flushBookmark: (b) async => flushedBookmarks.add(b),
        sleeper: (_) async {},
      );

      worker.start();
      // Initial drain runs immediately even before the stream emits.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(flushedFeedback.length, 2);
      expect(flushedBookmarks.length, 3);
      expect(repo.pendingFeedback, isEmpty);
      expect(repo.pendingBookmarks, isEmpty);
      expect(repo.removedFeedbackIds, containsAll(<String>['f1', 'f2']));
      expect(
        repo.syncedBookmarks.map((t) => t.$2),
        containsAll(<String>['a1', 'a2', 'a3']),
      );
    });

    test('triggers a fresh drain when connectivity flips offline -> online',
        () async {
      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async => flushedFeedback.add(f),
        flushBookmark: (b) async => flushedBookmarks.add(b),
        sleeper: (_) async {},
      );

      worker.start();
      // Initial drain finds nothing.
      await Future<void>.delayed(Duration.zero);

      // A vote happens while offline.
      repo.pendingFeedback.add(_buildFeedback('f-offline', HelpFeedbackVote.upvote));

      // Simulate offline pulse first, then online.
      connectivity.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(flushedFeedback, isEmpty);

      connectivity.add(true);
      // give the listener a tick + the drain future to complete
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(flushedFeedback.length, 1);
      expect(flushedFeedback.single.id, 'f-offline');
      expect(repo.pendingFeedback, isEmpty);
    });

    test('retries with backoff and keeps the item in the queue on persistent failure',
        () async {
      repo.pendingFeedback.add(_buildFeedback('f-retry', HelpFeedbackVote.upvote));

      var attempts = 0;
      final delays = <Duration>[];
      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async {
          attempts += 1;
          throw StateError('network down (attempt $attempts)');
        },
        flushBookmark: (b) async {},
        sleeper: (delay) async {
          delays.add(delay);
        },
        maxRetries: 3,
        initialRetryDelay: const Duration(milliseconds: 10),
      );

      final stats = await worker.drain();

      expect(attempts, 3);
      expect(delays, <Duration>[
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 20),
      ]);
      expect(stats.feedbackFailed, 1);
      expect(stats.feedbackSynced, 0);
      // The failed entry must stay in the queue for the next attempt.
      expect(repo.pendingFeedback.single.id, 'f-retry');
      expect(repo.removedFeedbackIds, isEmpty);
    });

    test('succeeds on a transient failure followed by a successful retry',
        () async {
      repo.pendingFeedback.add(_buildFeedback('f-transient', HelpFeedbackVote.upvote));

      var attempts = 0;
      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async {
          attempts += 1;
          if (attempts < 2) {
            throw StateError('transient');
          }
          flushedFeedback.add(f);
        },
        flushBookmark: (b) async {},
        sleeper: (_) async {},
        initialRetryDelay: const Duration(milliseconds: 1),
      );

      final stats = await worker.drain();

      expect(attempts, 2);
      expect(stats.feedbackSynced, 1);
      expect(stats.feedbackFailed, 0);
      expect(repo.pendingFeedback, isEmpty);
      expect(flushedFeedback.single.id, 'f-transient');
    });

    test('concurrent drain calls coalesce (second call is a no-op)', () async {
      repo.pendingFeedback.add(_buildFeedback('f-conc', HelpFeedbackVote.upvote));

      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          flushedFeedback.add(f);
        },
        flushBookmark: (b) async {},
        sleeper: (_) async {},
      );

      final firstFuture = worker.drain();
      final secondFuture = worker.drain();
      final results = await Future.wait(<Future<HelpFeedbackSyncStats>>[
        firstFuture,
        secondFuture,
      ]);

      // One of the drains saw the work, the other one short-circuited.
      final totalProcessed = results
          .map((s) => s.feedbackSynced + s.feedbackFailed)
          .reduce((a, b) => a + b);
      expect(totalProcessed, 1);
      expect(flushedFeedback.length, 1);
    });

    test('isRunning reflects start/dispose', () async {
      worker = HelpFeedbackSyncWorker(
        repository: repo,
        connectivityStream: connectivity.stream,
        flushFeedback: (f) async => flushedFeedback.add(f),
        flushBookmark: (b) async => flushedBookmarks.add(b),
        sleeper: (_) async {},
      );

      expect(worker.isRunning, isFalse);
      worker.start();
      expect(worker.isRunning, isTrue);
      await worker.dispose();
      expect(worker.isRunning, isFalse);
    });
  });
}
