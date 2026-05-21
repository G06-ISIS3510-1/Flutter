import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Writes Help Center analytics events to:
/// - Firestore `help_events` collection (source of truth for BQ-J4 pipeline)
/// - Firebase Analytics (matches the S3 instrumentation pattern)
///
/// Events:
/// - `help_session_started` once when the HelpCenterScreen mounts.
/// - `help_article_viewed` when an article opens (F-J-5).
/// - `help_contact_support_clicked` when the CTA is tapped.
///
/// The BQ-J4 resolution rate is computed off these as:
///   `1 - count(contact_support_clicked) / count(session_started)` (weekly).
class HelpAnalyticsService {
  HelpAnalyticsService({
    required FirebaseFirestore firestore,
    required FirebaseAnalytics analytics,
  })  : _firestore = firestore,
        _analytics = analytics;

  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;

  static const String _collection = 'help_events';

  Future<void> logSessionStarted({
    required String sessionId,
    required String userId,
  }) {
    return _logEvent(
      name: 'help_session_started',
      sessionId: sessionId,
      userId: userId,
    );
  }

  Future<void> logArticleViewed({
    required String sessionId,
    required String userId,
    required String articleId,
    required String category,
  }) {
    return _logEvent(
      name: 'help_article_viewed',
      sessionId: sessionId,
      userId: userId,
      payload: <String, Object>{
        'article_id': articleId,
        'category': category,
      },
    );
  }

  Future<void> logContactSupportClicked({
    required String sessionId,
    required String userId,
    String? articleId,
    String? query,
  }) {
    final payload = <String, Object>{};
    if (articleId != null && articleId.isNotEmpty) {
      payload['article_id'] = articleId;
    }
    if (query != null && query.trim().isNotEmpty) {
      payload['query'] = query.trim();
    }
    return _logEvent(
      name: 'help_contact_support_clicked',
      sessionId: sessionId,
      userId: userId,
      payload: payload,
    );
  }

  Future<void> _logEvent({
    required String name,
    required String sessionId,
    required String userId,
    Map<String, Object>? payload,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final parameters = <String, Object>{
      'event': name,
      'session_id': sessionId,
      'user_id': userId,
      'timestamp_ms': timestamp.millisecondsSinceEpoch,
      ...?payload,
    };

    try {
      await _firestore.collection(_collection).add(<String, Object>{
        ...parameters,
        'timestamp': Timestamp.fromDate(timestamp),
      });
    } catch (_) {
      // Analytics must never block the help flow.
    }

    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics must never block the help flow.
    }
  }
}
