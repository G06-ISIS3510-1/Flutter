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
  });

  Future<PaymentRecord> getPaymentStatus(String rideId);

  Stream<PaymentRecord?> watchPaymentStatus(String rideId);
}
