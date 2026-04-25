import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ride_history_entity.dart';

class RideHistoryModel extends RideHistoryEntity {
  const RideHistoryModel({
    required super.rideId,
    required super.userId,
    required super.userRole,
    required super.driverName,
    required super.origin,
    required super.destination,
    required super.departureAt,
    required super.pricePerSeat,
    required super.status,
    required super.totalSeats,
    required super.savedAt,
  });

  factory RideHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
    String userRole,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final now = DateTime.now();

    DateTime parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      return now;
    }

    return RideHistoryModel(
      rideId: doc.id,
      userId: userId,
      userRole: userRole,
      driverName: (data['driverName'] as String?) ?? '',
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      departureAt: parseDate(data['departureAt']),
      pricePerSeat: (data['pricePerSeat'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String?) ?? 'open',
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 1,
      savedAt: now,
    );
  }

  factory RideHistoryModel.fromSqlite(Map<String, dynamic> row) {
    return RideHistoryModel(
      rideId: row['rideId'] as String,
      userId: row['userId'] as String,
      userRole: row['userRole'] as String,
      driverName: row['driverName'] as String,
      origin: row['origin'] as String,
      destination: row['destination'] as String,
      departureAt: DateTime.fromMillisecondsSinceEpoch(
        row['departureAt'] as int,
      ),
      pricePerSeat: row['pricePerSeat'] as int,
      status: row['status'] as String,
      totalSeats: row['totalSeats'] as int,
      savedAt: DateTime.fromMillisecondsSinceEpoch(row['savedAt'] as int),
    );
  }

  Map<String, dynamic> toSqlite() {
    return <String, dynamic>{
      'rideId': rideId,
      'userId': userId,
      'userRole': userRole,
      'driverName': driverName,
      'origin': origin,
      'destination': destination,
      'departureAt': departureAt.millisecondsSinceEpoch,
      'pricePerSeat': pricePerSeat,
      'status': status,
      'totalSeats': totalSeats,
      'savedAt': savedAt.millisecondsSinceEpoch,
    };
  }
}
