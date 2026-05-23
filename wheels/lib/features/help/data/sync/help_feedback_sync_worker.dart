import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/help_feedback.dart';
import '../../domain/repositories/help_repository.dart';

typedef HelpFeedbackFlusher = Future<void> Function(HelpFeedback feedback);
typedef HelpBookmarkFlusher = Future<void> Function(HelpBookmark bookmark);
typedef HelpSyncSleeper = Future<void> Function(Duration delay);

class HelpFeedbackSyncStats {
  const HelpFeedbackSyncStats({
    required this.feedbackSynced,
    required this.feedbackFailed,
    required this.bookmarksSynced,
    required this.bookmarksFailed,
  });

  final int feedbackSynced;
  final int feedbackFailed;
  final int bookmarksSynced;
  final int bookmarksFailed;

  int get total => feedbackSynced + feedbackFailed + bookmarksSynced + bookmarksFailed;
  bool get hasWork => total > 0;

  @override
  String toString() {
    return 'HelpFeedbackSyncStats('
        'feedback=$feedbackSynced ok / $feedbackFailed failed, '
        'bookmarks=$bookmarksSynced ok / $bookmarksFailed failed)';
  }
}

/// Drains the pending help-feedback and pending-bookmark queues into Firestore
/// whenever connectivity becomes available again. Uses idempotent retry with
/// exponential backoff (default: 3 retries, starting at 500 ms, doubling each
/// attempt).
///
/// Production wiring uses the [HelpFeedbackSyncWorker.firestore] factory.
/// Tests pass custom flushers + a custom sleeper so the backoff loop runs
/// instantly under a fake connectivity stream.
class HelpFeedbackSyncWorker {
  HelpFeedbackSyncWorker({
    required HelpRepository repository,
    required Stream<bool> connectivityStream,
    required HelpFeedbackFlusher flushFeedback,
    required HelpBookmarkFlusher flushBookmark,
    HelpSyncSleeper? sleeper,
    int maxRetries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 500),
  })  : _repository = repository,
        _connectivity = connectivityStream,
        _flushFeedback = flushFeedback,
        _flushBookmark = flushBookmark,
        _sleeper = sleeper ?? _defaultSleeper,
        _maxRetries = maxRetries,
        _initialRetryDelay = initialRetryDelay;

  factory HelpFeedbackSyncWorker.firestore({
    required HelpRepository repository,
    required Stream<bool> connectivityStream,
    required FirebaseFirestore firestore,
    HelpSyncSleeper? sleeper,
    int maxRetries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 500),
  }) {
    return HelpFeedbackSyncWorker(
      repository: repository,
      connectivityStream: connectivityStream,
      flushFeedback: (feedback) => firestore
          .collection('help_feedback')
          .doc(feedback.id)
          .set(<String, Object>{
            'id': feedback.id,
            'article_id': feedback.articleId,
            'user_id': feedback.userId,
            'vote': feedback.vote.storageValue,
            'note': feedback.note ?? '',
            'created_at': Timestamp.fromDate(feedback.createdAt),
            'synced_at': FieldValue.serverTimestamp(),
          }),
      flushBookmark: (bookmark) => firestore
          .collection('users')
          .doc(bookmark.userId)
          .collection('help_bookmarks')
          .doc(bookmark.articleId)
          .set(<String, Object>{
            'article_id': bookmark.articleId,
            'user_id': bookmark.userId,
            'saved_at': Timestamp.fromDate(bookmark.savedAt),
            'synced_at': FieldValue.serverTimestamp(),
          }),
      sleeper: sleeper,
      maxRetries: maxRetries,
      initialRetryDelay: initialRetryDelay,
    );
  }

  final HelpRepository _repository;
  final Stream<bool> _connectivity;
  final HelpFeedbackFlusher _flushFeedback;
  final HelpBookmarkFlusher _flushBookmark;
  final HelpSyncSleeper _sleeper;
  final int _maxRetries;
  final Duration _initialRetryDelay;

  StreamSubscription<bool>? _subscription;
  bool _running = false;
  bool _draining = false;

  bool get isRunning => _running;

  /// Starts listening for connectivity changes. Also kicks off an initial
  /// drain attempt in case the device is already online when the worker
  /// boots.
  void start() {
    if (_running) return;
    _running = true;
    _subscription = _connectivity.listen((isOnline) {
      if (isOnline) {
        unawaited(drain());
      }
    });
    unawaited(drain());
  }

  Future<void> dispose() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Public so callers (and tests) can trigger a flush directly without
  /// waiting for the stream.
  Future<HelpFeedbackSyncStats> drain() async {
    if (_draining) {
      return const HelpFeedbackSyncStats(
        feedbackSynced: 0,
        feedbackFailed: 0,
        bookmarksSynced: 0,
        bookmarksFailed: 0,
      );
    }
    _draining = true;
    try {
      final feedbackStats = await _drainFeedback();
      final bookmarkStats = await _drainBookmarks();
      final stats = HelpFeedbackSyncStats(
        feedbackSynced: feedbackStats.synced,
        feedbackFailed: feedbackStats.failed,
        bookmarksSynced: bookmarkStats.synced,
        bookmarksFailed: bookmarkStats.failed,
      );
      if (stats.hasWork) {
        debugPrint('[HelpFeedbackSyncWorker] $stats');
      }
      return stats;
    } finally {
      _draining = false;
    }
  }

  Future<_DrainCounts> _drainFeedback() async {
    final pending = await _repository.loadPendingFeedback();
    var synced = 0;
    var failed = 0;
    for (final feedback in pending) {
      final ok = await _runWithBackoff(() => _flushFeedback(feedback));
      if (ok) {
        await _repository.removePendingFeedback(feedback.id);
        synced += 1;
      } else {
        failed += 1;
      }
    }
    return _DrainCounts(synced: synced, failed: failed);
  }

  Future<_DrainCounts> _drainBookmarks() async {
    final pending = await _repository.loadPendingBookmarks();
    var synced = 0;
    var failed = 0;
    for (final bookmark in pending) {
      final ok = await _runWithBackoff(() => _flushBookmark(bookmark));
      if (ok) {
        await _repository.markBookmarkSynced(
          userId: bookmark.userId,
          articleId: bookmark.articleId,
        );
        synced += 1;
      } else {
        failed += 1;
      }
    }
    return _DrainCounts(synced: synced, failed: failed);
  }

  Future<bool> _runWithBackoff(Future<void> Function() action) async {
    var delay = _initialRetryDelay;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await action();
        return true;
      } catch (error, stackTrace) {
        debugPrint(
          '[HelpFeedbackSyncWorker] flush attempt $attempt/$_maxRetries '
          'failed: $error',
        );
        if (attempt == _maxRetries) {
          FlutterError.dumpErrorToConsole(
            FlutterErrorDetails(exception: error, stack: stackTrace),
          );
          return false;
        }
        await _sleeper(delay);
        delay *= 2;
      }
    }
    return false;
  }

  static Future<void> _defaultSleeper(Duration delay) => Future<void>.delayed(delay);
}

class _DrainCounts {
  const _DrainCounts({required this.synced, required this.failed});

  final int synced;
  final int failed;
}
