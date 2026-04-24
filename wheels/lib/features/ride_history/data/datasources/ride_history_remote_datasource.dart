import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_history_model.dart';

class RideHistoryRemoteDataSource {
  RideHistoryRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _limit = 20;

  Future<List<RideHistoryModel>> fetchHistory(String userId) async {
    // Driver rides and passenger rides are independent — fetch concurrently
    final results = await Future.wait([
      _fetchAsDriver(userId),
      _fetchAsPassenger(userId),
    ]);

    final merged = [...results[0], ...results[1]];

    final seen = <String>{};
    final unique =
        merged.where((entry) => seen.add(entry.rideId)).toList()
          ..sort((a, b) => b.departureAt.compareTo(a.departureAt));

    return unique;
  }

  Future<List<RideHistoryModel>> _fetchAsDriver(String userId) async {
    final snapshot = await _firestore
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .limit(_limit)
        .get();

    return snapshot.docs
        .map((doc) => RideHistoryModel.fromFirestore(doc, userId, 'driver'))
        .toList();
  }

  Future<List<RideHistoryModel>> _fetchAsPassenger(String userId) async {
    final snapshot = await _firestore
        .collection('rides')
        .where('passengerIds', arrayContains: userId)
        .limit(_limit)
        .get();

    return snapshot.docs
        .map((doc) => RideHistoryModel.fromFirestore(doc, userId, 'passenger'))
        .toList();
  }
}
