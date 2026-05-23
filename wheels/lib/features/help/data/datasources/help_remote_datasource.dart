import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';
import '../../domain/entities/help_resolution_rate.dart';

class HelpRemoteDataSource {
  HelpRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _articlesCollection =>
      _firestore.collection('help_articles');

  CollectionReference<Map<String, dynamic>> get _helpEventsCollection =>
      _firestore.collection('help_events');

  /// Fetches BQ-J4 events (session-started and contact-support-clicked) at or
  /// after [windowStart]. The query intentionally filters only by timestamp
  /// to avoid requiring a composite (`event` + `timestamp`) index; the event
  /// name is filtered client-side, which is cheap because the time-bounded
  /// result set is small (last 7 days).
  Future<List<HelpAnalyticsEventRecord>> loadResolutionEventsSince(
    DateTime windowStart,
  ) async {
    final snapshot = await _helpEventsCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart))
        .get();
    final events = <HelpAnalyticsEventRecord>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final event = _readString(data['event']);
      final timestamp = _readTimestamp(data['timestamp']);
      if (event == null || timestamp == null) continue;
      if (event != helpEventSessionStarted &&
          event != helpEventContactSupportClicked) {
        continue;
      }
      events.add(HelpAnalyticsEventRecord(event: event, timestamp: timestamp));
    }
    return events;
  }

  Stream<List<HelpArticle>> watchArticles() {
    return _articlesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(_decodeArticle)
          .whereType<HelpArticle>()
          .toList(growable: false);
    });
  }

  Future<HelpArticle?> getArticle(String articleId) async {
    final snapshot = await _articlesCollection.doc(articleId).get();
    if (!snapshot.exists) {
      return null;
    }
    return _decodeArticle(snapshot);
  }

  HelpArticle? _decodeArticle(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return null;
    }
    try {
      return HelpArticle(
        id: doc.id,
        slug: _readString(data['slug']) ?? doc.id,
        title: _readString(data['title']) ?? 'Untitled',
        summary: _readString(data['summary']) ?? '',
        body: _readString(data['body']) ?? '',
        category: helpCategoryFromStorage(_readString(data['category'])),
        tags: _readStringList(data['tags']),
        updatedAt: _readTimestamp(data['updatedAt']) ?? DateTime.now().toUtc(),
        upvotes: _readInt(data['upvotes']) ?? 0,
        downvotes: _readInt(data['downvotes']) ?? 0,
        heroImageUrl: _readString(data['heroImageUrl']),
      );
    } catch (_) {
      return null;
    }
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  int? _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }
}
