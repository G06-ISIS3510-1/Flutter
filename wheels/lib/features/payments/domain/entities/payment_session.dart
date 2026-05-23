class PaymentSession {
  const PaymentSession({
    required this.preferenceId,
    required this.initPoint,
    this.sandboxInitPoint,
  });

  final String preferenceId;
  final String initPoint;
  final String? sandboxInitPoint;
}
