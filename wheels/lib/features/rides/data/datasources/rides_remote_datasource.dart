import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/rides_entity.dart';
import '../models/rides_model.dart';

class RidesRemoteDataSource {
  RidesRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> _applicationsCollection(
    String rideId,
  ) => _ridesCollection.doc(rideId).collection('applications');

  Stream<List<RidesEntity>> watchAvailableRides() {
    return _ridesCollection.snapshots().map((snapshot) {
      final rides = snapshot.docs
          .map(RidesModel.fromFirestore)
          .where((ride) => ride.status == 'open')
          .toList()
        ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
      return rides;
    });
  }

  Stream<RidesEntity?> watchRide(String rideId) {
    return _ridesCollection.doc(rideId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return RidesModel.fromFirestore(snapshot);
    });
  }

  Stream<RidesEntity?> watchCurrentDriverRide(String driverId) {
    return _ridesCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs.map(RidesModel.fromFirestore).where((ride) {
            return ride.status == 'open' || ride.status == 'in_progress';
          }).toList()
            ..sort((a, b) => a.departureAt.compareTo(b.departureAt));

          if (rides.isEmpty) {
            return null;
          }
          return rides.first;
        });
  }

  Stream<List<RideApplicationEntity>> watchRideApplications(String rideId) {
    return _applicationsCollection(
      rideId,
    ).snapshots().map((snapshot) {
      final applications = snapshot.docs
          .map(RideApplicationModel.fromFirestore)
          .toList()
        ..sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
      return applications;
    });
  }

  Stream<RideApplicationEntity?> watchPassengerApplication({
    required String rideId,
    required String passengerId,
  }) {
    return _applicationsCollection(
      rideId,
    ).doc(passengerId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return RideApplicationModel.fromFirestore(snapshot);
    });
  }

  Future<RidesEntity> createRide({
    required String driverId,
    required String driverName,
    required String driverEmail,
    required String origin,
    required String destination,
    required DateTime departureAt,
    required int estimatedDurationMinutes,
    required int totalSeats,
    required int pricePerSeat,
    required String notes,
  }) async {
    final document = _ridesCollection.doc();
    final now = DateTime.now();
    final ride = RidesModel(
      id: document.id,
      driverId: driverId,
      driverName: driverName,
      driverEmail: driverEmail,
      origin: origin,
      destination: destination,
      departureAt: departureAt,
      estimatedDurationMinutes: estimatedDurationMinutes,
      totalSeats: totalSeats,
      availableSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      status: 'open',
      notes: notes,
      passengerIds: const <String>[],
      createdAt: now,
      updatedAt: now,
    );

    await document.set(ride.toFirestore());
    return ride;
  }

  Future<void> applyToRide({
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
  }) async {
    final rideRef = _ridesCollection.doc(rideId);
    final applicationRef = _applicationsCollection(rideId).doc(passengerId);

    await _firestore.runTransaction((transaction) async {
      final rideSnapshot = await transaction.get(rideRef);
      if (!rideSnapshot.exists) {
        throw const RideFailure(
          'This ride is no longer available. Please refresh and try again.',
        );
      }

      final ride = RidesModel.fromFirestore(rideSnapshot);
      if (ride.driverId == passengerId) {
        throw const RideFailure('You cannot apply to your own ride.');
      }
      if (ride.status != 'open') {
        throw const RideFailure(
          'This ride is no longer accepting passengers.',
        );
      }
      if (!ride.hasAvailableSeats) {
        throw const RideFailure('This ride is already full.');
      }

      final applicationSnapshot = await transaction.get(applicationRef);
      if (applicationSnapshot.exists) {
        return;
      }

      transaction.update(rideRef, <String, dynamic>{
        'availableSeats': ride.availableSeats - 1,
        'passengerIds': FieldValue.arrayUnion(<String>[passengerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final application = RideApplicationModel(
        id: passengerId,
        rideId: rideId,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerEmail: passengerEmail,
        status: 'applied',
        appliedAt: DateTime.now(),
      );
      transaction.set(applicationRef, application.toFirestore());
    });
  }

  Future<void> updateRideStatus({
    required String rideId,
    required String status,
  }) {
    return _ridesCollection.doc(rideId).update(<String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
