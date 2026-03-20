import '../../domain/entities/payment_record.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_firestore_datasource.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl({
    required PaymentRemoteDataSource remoteDataSource,
    required PaymentFirestoreDataSource firestoreDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _firestoreDataSource = firestoreDataSource;

  final PaymentRemoteDataSource _remoteDataSource;
  final PaymentFirestoreDataSource _firestoreDataSource;

  @override
  Future<PaymentSession> createCheckoutSession({
    required String rideId,
    required String title,
    required double unitPrice,
    required int quantity,
    required String payerEmail,
    required String userId,
  }) {
    return _remoteDataSource.createPreference(
      rideId: rideId,
      title: title,
      unitPrice: unitPrice,
      quantity: quantity,
      payerEmail: payerEmail,
      userId: userId,
    );
  }

  @override
  Future<PaymentRecord> getPaymentStatus(String rideId) {
    return _remoteDataSource.getPaymentStatus(rideId);
  }

  @override
  Stream<PaymentRecord?> watchPaymentStatus(String rideId) {
    return _firestoreDataSource.watchPaymentStatus(rideId);
  }
}
