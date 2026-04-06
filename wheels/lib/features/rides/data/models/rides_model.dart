import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/rides_entity.dart';

class RidesModel extends RidesEntity {
  const RidesModel({
    required super.id,
    required super.driverId,
    required super.driverName,
    required super.driverEmail,
    required super.origin,
    required super.destination,
    required super.departureAt,
    required super.estimatedDurationMinutes,
    required super.totalSeats,
    required super.availableSeats,
    required super.pricePerSeat,
    required super.paymentOption,
    required super.status,
    required super.notes,
    required super.passengerIds,
    required super.createdAt,
    required super.updatedAt,
    super.driverRating,
    super.reviewCount,
    super.onTimeRate,
    super.verifiedByUniversity,
  });

  factory RidesModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final now = DateTime.now();

    DateTime parseDate(Object? value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return now;
    }

    return RidesModel(
      id: document.id,
      driverId: (data['driverId'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? 'Wheels Driver',
      driverEmail: (data['driverEmail'] as String?) ?? '',
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      departureAt: parseDate(data['departureAt']),
      estimatedDurationMinutes:
          (data['estimatedDurationMinutes'] as num?)?.toInt() ?? 30,
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 1,
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      pricePerSeat: (data['pricePerSeat'] as num?)?.toInt() ?? 0,
      paymentOption: ridePaymentOptionFromStorage(
        data['paymentOption'] as String?,
      ),
      status: (data['status'] as String?) ?? 'open',
      notes: (data['notes'] as String?) ?? '',
      passengerIds:
          ((data['passengerIds'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 5,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      onTimeRate: (data['onTimeRate'] as num?)?.toInt() ?? 100,
      verifiedByUniversity: (data['verifiedByUniversity'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'origin': origin,
      'destination': destination,
      'originSearch': origin.toLowerCase(),
      'destinationSearch': destination.toLowerCase(),
      'departureAt': Timestamp.fromDate(departureAt),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'paymentOption': paymentOption.storageValue,
      'status': status,
      'notes': notes,
      'passengerIds': passengerIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'driverRating': driverRating,
      'reviewCount': reviewCount,
      'onTimeRate': onTimeRate,
      'verifiedByUniversity': verifiedByUniversity,
    };
  }
}

class RideApplicationModel extends RideApplicationEntity {
  const RideApplicationModel({
    required super.id,
    required super.rideId,
    required super.passengerId,
    required super.passengerName,
    required super.passengerEmail,
    required super.status,
    required super.paymentStatus,
    required super.paymentMethod,
    required super.isPaymentLocked,
    required super.appliedAt,
    super.paymentStatusSource,
    super.paymentUpdatedAt,
  });

  factory RideApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final appliedAt = data['appliedAt'];

    return RideApplicationModel(
      id: document.id,
      rideId: (data['rideId'] as String?) ?? '',
      passengerId: (data['passengerId'] as String?) ?? '',
      passengerName: (data['passengerName'] as String?) ?? 'Passenger',
      passengerEmail: (data['passengerEmail'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'applied',
      paymentStatus: ridePassengerPaymentStatusFromStorage(
        data['paymentStatus'] as String?,
      ),
      paymentMethod: ridePassengerPaymentMethodFromStorage(
        data['paymentMethod'] as String?,
      ),
      isPaymentLocked: (data['isPaymentLocked'] as bool?) ?? false,
      appliedAt: appliedAt is Timestamp ? appliedAt.toDate() : DateTime.now(),
      paymentStatusSource: data['paymentStatusSource'] as String?,
      paymentUpdatedAt: data['paymentUpdatedAt'] is Timestamp
          ? (data['paymentUpdatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'status': status,
      'paymentStatus': paymentStatus.storageValue,
      'paymentMethod': paymentMethod.storageValue,
      'isPaymentLocked': isPaymentLocked,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'paymentStatusSource': paymentStatusSource,
      'paymentUpdatedAt': paymentUpdatedAt == null
          ? null
          : Timestamp.fromDate(paymentUpdatedAt!),
    };
  }
}
