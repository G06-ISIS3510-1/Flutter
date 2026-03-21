import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_record_model.dart';

class PaymentFirestoreDataSource {
  PaymentFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<PaymentRecordModel?> watchPaymentStatus(String rideId) {
    return _firestore.collection('payments').doc(rideId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return PaymentRecordModel.fromFirestore(snapshot);
    });
  }
}
