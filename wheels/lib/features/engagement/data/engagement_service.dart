import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class EngagementService {
  const EngagementService({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  }) : _firestore = firestore,
       _messaging = messaging;

  static const String _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<void> initializeMessaging() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> registerDeviceToken(String uid) async {
    final token = kIsWeb
        ? await _messaging.getToken(
            vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey,
          )
        : await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion(<String>[token]),
      'lastTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordConnection(String uid) async {
    final now = DateTime.now();
    final localHour = now.hour;
    final dateKey = _buildDateKey(now);
    final timezoneOffsetMinutes = now.timeZoneOffset.inMinutes;

    final userRef = _firestore.collection('users').doc(uid);
    final summaryRef = userRef.collection('engagement').doc('summary');
    final dailyRef = userRef.collection('engagementDaily').doc(dateKey);

    await _firestore.runTransaction((transaction) async {
      transaction.set(dailyRef, {
        'dateKey': dateKey,
        'hours': FieldValue.arrayUnion(<int>[localHour]),
        'lastConnectedAt': FieldValue.serverTimestamp(),
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
      }, SetOptions(merge: true));

      transaction.set(summaryRef, {
        'lastConnectedAt': FieldValue.serverTimestamp(),
        'lastConnectionDateKey': dateKey,
        'lastConnectionHour': localHour,
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(userRef, {
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await _refreshRollingSummary(uid, now);
  }

  Future<void> _refreshRollingSummary(String uid, DateTime now) async {
    final threshold = now.subtract(const Duration(days: 30));
    final thresholdKey = _buildDateKey(threshold);
    final summaryRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('engagement')
        .doc('summary');

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('engagementDaily')
        .where('dateKey', isGreaterThanOrEqualTo: thresholdKey)
        .get();

    final hourCounts = <String, int>{
      for (var hour = 0; hour < 24; hour++) '$hour': 0,
    };

    for (final doc in snapshot.docs) {
      final hours = List<int>.from(
        (doc.data()['hours'] as List<dynamic>? ?? <dynamic>[]).map(
          (dynamic value) => value as int,
        ),
      );
      for (final hour in hours) {
        hourCounts['$hour'] = (hourCounts['$hour'] ?? 0) + 1;
      }
    }

    final preferredHour = _preferredHourFromCounts(hourCounts);
    final totalConnections = hourCounts.values.fold<int>(
      0,
      (runningTotal, entryCount) => runningTotal + entryCount,
    );

    await summaryRef.set({
      'hourCounts': hourCounts,
      'preferredHour': totalConnections == 0 ? null : preferredHour,
      'rollingWindowStartDateKey': thresholdKey,
      'rollingWindowDays': 30,
      'totalConnectionsLast30Days': totalConnections,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _preferredHourFromCounts(Map<String, int> hourCounts) {
    var bestHour = 0;
    var bestCount = -1;

    for (var hour = 0; hour < 24; hour++) {
      final count = hourCounts['$hour'] ?? 0;
      if (count > bestCount) {
        bestCount = count;
        bestHour = hour;
      }
    }

    return bestHour;
  }

  String _buildDateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
