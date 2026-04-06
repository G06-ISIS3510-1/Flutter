class PaymentRecord {
  const PaymentRecord({
    required this.rideId,
    required this.passengerId,
    required this.status,
    this.paymentId,
    this.mpStatus,
    this.transactionAmount,
    this.paymentMethodId,
    this.statusDetail,
  });

  final String rideId;
  final String passengerId;
  final String status;
  final String? paymentId;
  final String? mpStatus;
  final double? transactionAmount;
  final String? paymentMethodId;
  final String? statusDetail;
}
