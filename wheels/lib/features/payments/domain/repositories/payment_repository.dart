import '../entities/payment_record.dart';
import '../entities/payment_session.dart';

abstract class PaymentRepository {
  Future<PaymentSession> createCheckoutSession({
    required String rideId,
    required String title,
    required double unitPrice,
    required int quantity,
    required String payerEmail,
    required String userId,
    required String passengerId,
  });

  Future<PaymentRecord> getPaymentStatus({
    required String rideId,
    required String passengerId,
  });

  Stream<PaymentRecord?> watchPaymentStatus({
    required String rideId,
    required String passengerId,
  });
}
