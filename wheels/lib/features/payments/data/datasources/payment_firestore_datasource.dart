import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_record_model.dart';

class PaymentFirestoreDataSource {
  PaymentFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _paymentDocument(
    String rideId,
    String passengerId,
  ) {
    return _firestore
        .collection('payments')
        .doc(rideId)
        .collection('passengers')
        .doc(passengerId);
  }

  Future<PaymentRecordModel?> getPaymentStatus({
    required String rideId,
    required String passengerId,
  }) async {
    final snapshot = await _paymentDocument(rideId, passengerId).get();
    return _mapSnapshot(snapshot);
  }

  Stream<PaymentRecordModel?> watchPaymentStatus({
    required String rideId,
    required String passengerId,
  }) {
    return _paymentDocument(rideId, passengerId).snapshots().map(_mapSnapshot);
  }

  PaymentRecordModel? _mapSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return PaymentRecordModel.fromFirestore(snapshot);
  }
}
