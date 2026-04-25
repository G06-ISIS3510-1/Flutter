import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trust_model.dart';

class TrustRemoteDataSource {
  TrustRemoteDataSource({
    required FirebaseFirestore firestore,
    http.Client? client,
  }) : _firestore = firestore,
       _client = client ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;

  static final Uri _getTrustScoreUri = Uri.parse(
    'https://us-central1-wheels-fd8c0.cloudfunctions.net/getTrustScore',
  );
  static const Duration _requestTimeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  Future<TrustModel> getTrustData(String userId) async {
    try {
      return await _fetchTrustFromFunction(userId);
    } catch (_) {
      return _fetchTrustFromFirestore(userId);
    }
  }

  Future<TrustModel> _fetchTrustFromFunction(String userId) async {
    final response = await _client
        .get(
          _getTrustScoreUri.replace(
            queryParameters: <String, String>{'userId': userId},
          ),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TrustRemoteException(
        'Trust function is unavailable.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final jsonMap = _decodeMap(response.body);
    final success = jsonMap['success'];
    if (success is bool && !success) {
      throw TrustRemoteException(
        'Trust function returned an unsuccessful response.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final payload = _unwrapPayload(jsonMap);
    return TrustModel.fromJson(payload);
  }

  Future<TrustModel> _fetchTrustFromFirestore(String userId) async {
    final userFuture = _usersCollection.doc(userId).get();
    final driverRidesFuture = _ridesCollection
        .where('driverId', isEqualTo: userId)
        .get();
    final passengerRidesFuture = _ridesCollection
        .where('passengerIds', arrayContains: userId)
        .get();

    final userSnapshot = await userFuture;
    final driverRidesSnapshot = await driverRidesFuture;
    final passengerRidesSnapshot = await passengerRidesFuture;

    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final ridesById = <String, _RideSnapshotData>{};
    for (final ride in driverRidesSnapshot.docs) {
      ridesById[ride.id] = _RideSnapshotData(
        data: ride.data(),
        userRelation: _RideUserRelation.driver,
      );
    }
    for (final ride in passengerRidesSnapshot.docs) {
      ridesById.putIfAbsent(
        ride.id,
        () => _RideSnapshotData(
          data: ride.data(),
          userRelation: _RideUserRelation.passenger,
        ),
      );
    }

    var completedRides = 0;
    var cancelledRides = 0;
    var activeRides = 0;

    for (final rideData in ridesById.values) {
      final status = _readString(rideData.data['status']);
      switch (status) {
        case 'completed':
          completedRides++;
          break;
        case 'cancelled':
          cancelledRides++;
          break;
        case 'open':
        case 'in_progress':
          activeRides++;
          break;
      }
    }

    var approvedPayments = 0;
    var pendingPayments = 0;
    var failedPayments = 0;
    final paymentCounters = await Future.wait(
      ridesById.entries.map(
        (entry) => _loadPaymentCountersForRide(
          rideId: entry.key,
          userId: userId,
          relation: entry.value.userRelation,
        ),
      ),
    );
    for (final counters in paymentCounters) {
      approvedPayments += counters.approvedPayments;
      pendingPayments += counters.pendingPayments;
      failedPayments += counters.failedPayments;
    }

    final totalRides = ridesById.length;
    final totalPayments = approvedPayments + pendingPayments + failedPayments;
    final createdAt =
        _readDateTime(userData['createdAt']) ??
        _readDateTime(userData['updatedAt']) ??
        DateTime.now();
    final role = _readString(userData['role']) ?? 'passenger';

    return TrustModel(
      userId: userId,
      role: role,
      accountCreatedAt: createdAt,
      totalRides: totalRides,
      completedRides: completedRides,
      cancelledRides: cancelledRides,
      activeRides: activeRides,
      totalPayments: totalPayments,
      approvedPayments: approvedPayments,
      pendingPayments: pendingPayments,
      failedPayments: failedPayments,
      score: _calculateScore(
        totalRides: totalRides,
        completedRides: completedRides,
        cancelledRides: cancelledRides,
        approvedPayments: approvedPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        accountCreatedAt: createdAt,
      ),
      rewardPoints: _calculateRewardPoints(
        completedRides: completedRides,
        approvedPayments: approvedPayments,
        cancelledRides: cancelledRides,
        failedPayments: failedPayments,
        accountCreatedAt: createdAt,
        totalRides: totalRides,
      ),
    );
  }

  static int _calculateScore({
    required int totalRides,
    required int completedRides,
    required int cancelledRides,
    required int approvedPayments,
    required int pendingPayments,
    required int failedPayments,
    required DateTime accountCreatedAt,
  }) {
    var score = 68;
    final completionRate = totalRides == 0 ? 0.0 : completedRides / totalRides;
    final accountAgeDays = DateTime.now().difference(accountCreatedAt).inDays;

    score += (completedRides * 3).clamp(0, 18).toInt();
    score += (approvedPayments * 2).clamp(0, 12).toInt();
    score += (((accountAgeDays ~/ 30) * 2).clamp(0, 10)).toInt();

    if (totalRides >= 5 && completionRate >= 0.9) {
      score += 6;
    }
    if (approvedPayments >= 3 && pendingPayments == 0 && failedPayments == 0) {
      score += 4;
    }
    if (totalRides == 0) {
      score -= 6;
    }

    score -= (cancelledRides * 8).clamp(0, 24).toInt();
    score -= (failedPayments * 10).clamp(0, 20).toInt();
    score -= (pendingPayments * 2).clamp(0, 8).toInt();

    return score.clamp(45, 99).toInt();
  }

  static int _calculateRewardPoints({
    required int completedRides,
    required int approvedPayments,
    required int cancelledRides,
    required int failedPayments,
    required DateTime accountCreatedAt,
    required int totalRides,
  }) {
    final accountAgeDays = DateTime.now().difference(accountCreatedAt).inDays;
    final maturityPoints = (((accountAgeDays ~/ 30) * 2).clamp(0, 20)).toInt();
    final completionBonus = totalRides >= 3 && cancelledRides == 0 ? 20 : 0;
    final points =
        (completedRides * 5) +
        (approvedPayments * 3) +
        maturityPoints +
        completionBonus -
        (cancelledRides * 4) -
        (failedPayments * 6);

    return points < 0 ? 0 : points.toInt();
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }
    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<_PaymentCounters> _loadPaymentCountersForRide({
    required String rideId,
    required String userId,
    required _RideUserRelation relation,
  }) async {
    final passengersCollection = _firestore
        .collection('payments')
        .doc(rideId)
        .collection('passengers');

    if (relation == _RideUserRelation.passenger) {
      final snapshot = await passengersCollection.doc(userId).get();
      if (!snapshot.exists) {
        return const _PaymentCounters();
      }
      return _classifyPayments([snapshot.data() ?? <String, dynamic>{}]);
    }

    final snapshot = await passengersCollection.get();
    final records =
        snapshot.docs.map((document) => document.data()).toList(growable: false);
    return _classifyPayments(records);
  }

  _PaymentCounters _classifyPayments(List<Map<String, dynamic>> payments) {
    var approved = 0;
    var pending = 0;
    var failed = 0;

    for (final data in payments) {
      final paymentStatus = _readString(data['paymentStatus']);
      final status = _readString(data['status']);
      if (paymentStatus == 'paid' || status == 'approved') {
        approved++;
        continue;
      }
      if (paymentStatus == 'unpaid' || status == 'rejected') {
        failed++;
        continue;
      }
      pending++;
    }

    return _PaymentCounters(
      approvedPayments: approved,
      pendingPayments: pending,
      failedPayments: failed,
    );
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Trust response is not a JSON object.');
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    for (final key in const <String>['data', 'trust', 'result']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return json;
  }
}

class _PaymentCounters {
  const _PaymentCounters({
    this.approvedPayments = 0,
    this.pendingPayments = 0,
    this.failedPayments = 0,
  });

  final int approvedPayments;
  final int pendingPayments;
  final int failedPayments;
}

class _RideSnapshotData {
  const _RideSnapshotData({required this.data, required this.userRelation});

  final Map<String, dynamic> data;
  final _RideUserRelation userRelation;
}

enum _RideUserRelation { driver, passenger }

class TrustRemoteException implements Exception {
  const TrustRemoteException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}
