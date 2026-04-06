import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/rides_entity.dart';
import '../models/rides_model.dart';

class RidesRemoteDataSource {
  RidesRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _firestore.collection('payments');

  CollectionReference<Map<String, dynamic>> _applicationsCollection(
    String rideId,
  ) => _ridesCollection.doc(rideId).collection('applications');

  DocumentReference<Map<String, dynamic>> _paymentPassengerDocument(
    String rideId,
    String passengerId,
  ) =>
      _paymentsCollection.doc(rideId).collection('passengers').doc(passengerId);

  Stream<List<RidesEntity>> watchAvailableRides() {
    return _ridesCollection.snapshots().map((snapshot) {
      final rides =
          snapshot.docs
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
          final rides = snapshot.docs.map(RidesModel.fromFirestore).where((
            ride,
          ) {
            return ride.status == 'open' || ride.status == 'in_progress';
          }).toList()..sort((a, b) => a.departureAt.compareTo(b.departureAt));

          if (rides.isEmpty) {
            return null;
          }
          return rides.first;
        });
  }

  Stream<RidesEntity?> watchCurrentPassengerRide(String passengerId) {
    return _ridesCollection
        .where('passengerIds', arrayContains: passengerId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs.map(RidesModel.fromFirestore).where((
            ride,
          ) {
            return ride.status == 'open' || ride.status == 'in_progress';
          }).toList()..sort((a, b) => a.departureAt.compareTo(b.departureAt));

          if (rides.isEmpty) {
            return null;
          }
          return rides.first;
        });
  }

  Stream<List<RideApplicationEntity>> watchRideApplications(String rideId) {
    return _applicationsCollection(rideId).snapshots().map((snapshot) {
      final applications =
          snapshot.docs.map(RideApplicationModel.fromFirestore).toList()
            ..sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
      return applications;
    });
  }

  Stream<RideApplicationEntity?> watchPassengerApplication({
    required String rideId,
    required String passengerId,
  }) {
    return _applicationsCollection(rideId).doc(passengerId).snapshots().map((
      snapshot,
    ) {
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
    required RidePaymentOption paymentOption,
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
      paymentOption: paymentOption,
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
    final paymentRef = _paymentPassengerDocument(rideId, passengerId);

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
        throw const RideFailure('This ride is no longer accepting passengers.');
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
        paymentStatus: RidePassengerPaymentStatus.pending,
        paymentMethod: ride.acceptsCardPayments
            ? RidePassengerPaymentMethod.pendingSelection
            : RidePassengerPaymentMethod.bankTransfer,
        isPaymentLocked: false,
        appliedAt: DateTime.now(),
      );
      transaction.set(applicationRef, application.toFirestore());
      transaction.set(
        paymentRef,
        _paymentDocumentData(
          rideId: rideId,
          passengerId: passengerId,
          paymentMethod: application.paymentMethod,
          paymentStatus: application.paymentStatus,
          isPaymentLocked: application.isPaymentLocked,
          paymentStatusSource:
              application.paymentStatusSource ?? 'application_created',
        ),
        SetOptions(merge: true),
      );
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

  Future<void> updatePassengerPaymentStatus({
    required String rideId,
    required String passengerId,
    required RidePassengerPaymentMethod paymentMethod,
    required RidePassengerPaymentStatus paymentStatus,
    required bool isPaymentLocked,
    required String paymentStatusSource,
  }) async {
    final applicationRef = _applicationsCollection(rideId).doc(passengerId);
    final paymentRef = _paymentPassengerDocument(rideId, passengerId);
    final batch = _firestore.batch();

    batch.update(applicationRef, <String, dynamic>{
      'paymentMethod': paymentMethod.storageValue,
      'paymentStatus': paymentStatus.storageValue,
      'isPaymentLocked': isPaymentLocked,
      'paymentStatusSource': paymentStatusSource,
      'paymentUpdatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      paymentRef,
      _paymentDocumentData(
        rideId: rideId,
        passengerId: passengerId,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        isPaymentLocked: isPaymentLocked,
        paymentStatusSource: paymentStatusSource,
      ),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> confirmCardRidePayments({required String rideId}) async {
    final applicationsSnapshot = await _applicationsCollection(rideId).get();
    if (applicationsSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final document in applicationsSnapshot.docs) {
      batch.update(document.reference, <String, dynamic>{
        'paymentMethod': RidePassengerPaymentMethod.card.storageValue,
        'paymentStatus': RidePassengerPaymentStatus.paid.storageValue,
        'isPaymentLocked': true,
        'paymentStatusSource': 'mercado_pago',
        'paymentUpdatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        _paymentPassengerDocument(rideId, document.id),
        _paymentDocumentData(
          rideId: rideId,
          passengerId: document.id,
          paymentMethod: RidePassengerPaymentMethod.card,
          paymentStatus: RidePassengerPaymentStatus.paid,
          isPaymentLocked: true,
          paymentStatusSource: 'mercado_pago',
        ),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Map<String, dynamic> _paymentDocumentData({
    required String rideId,
    required String passengerId,
    required RidePassengerPaymentMethod paymentMethod,
    required RidePassengerPaymentStatus paymentStatus,
    required bool isPaymentLocked,
    required String paymentStatusSource,
  }) {
    return <String, dynamic>{
      'rideId': rideId,
      'passengerId': passengerId,
      'status': _paymentRecordStatus(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        paymentStatusSource: paymentStatusSource,
      ),
      'paymentMethodId': paymentMethod.storageValue,
      'isPaymentLocked': isPaymentLocked,
      'paymentStatus': paymentStatus.storageValue,
      'paymentStatusSource': paymentStatusSource,
      'statusDetail': _paymentStatusDetail(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        paymentStatusSource: paymentStatusSource,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _paymentRecordStatus({
    required RidePassengerPaymentMethod paymentMethod,
    required RidePassengerPaymentStatus paymentStatus,
    required String paymentStatusSource,
  }) {
    switch (paymentStatus) {
      case RidePassengerPaymentStatus.paid:
        return 'approved';
      case RidePassengerPaymentStatus.unpaid:
        return 'rejected';
      case RidePassengerPaymentStatus.pending:
        final normalizedSource = paymentStatusSource.trim().toLowerCase();
        if (paymentMethod == RidePassengerPaymentMethod.card &&
            normalizedSource == 'passenger_selection') {
          return 'created';
        }
        if (paymentMethod == RidePassengerPaymentMethod.pendingSelection) {
          return 'created';
        }
        return 'pending';
    }
  }

  String _paymentStatusDetail({
    required RidePassengerPaymentMethod paymentMethod,
    required RidePassengerPaymentStatus paymentStatus,
    required String paymentStatusSource,
  }) {
    if (paymentStatus == RidePassengerPaymentStatus.paid) {
      return paymentStatusSource == 'mercado_pago'
          ? 'card_payment_confirmed'
          : 'payment_confirmed_manually';
    }
    if (paymentStatus == RidePassengerPaymentStatus.unpaid) {
      return paymentStatusSource == 'ride_completion_auto'
          ? 'payment_not_completed_before_ride_finished'
          : 'payment_marked_unpaid';
    }
    if (paymentMethod == RidePassengerPaymentMethod.pendingSelection) {
      return 'payment_method_not_selected';
    }
    if (paymentMethod == RidePassengerPaymentMethod.card) {
      return paymentStatusSource == 'passenger_selection'
          ? 'card_checkout_not_started'
          : 'card_payment_pending_confirmation';
    }
    return 'awaiting_manual_transfer_confirmation';
  }
}
