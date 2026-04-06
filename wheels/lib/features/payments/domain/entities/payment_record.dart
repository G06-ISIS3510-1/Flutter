class PaymentRecord {
  const PaymentRecord({
    required this.rideId,
    required this.passengerId,
    required this.paymentStatus,
    this.status,
    this.paymentId,
    this.mpStatus,
    this.transactionAmount,
    this.paymentMethodId,
    this.paymentType,
    this.paymentMode,
    this.paymentProvider,
    this.currency,
    this.statusDetail,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.walletCredited,
    this.walletRefunded,
  });

  final String rideId;
  final String passengerId;
  final String paymentStatus;
  final String? status;
  final String? paymentId;
  final String? mpStatus;
  final double? transactionAmount;
  final String? paymentMethodId;
  final String? paymentType;
  final String? paymentMode;
  final String? paymentProvider;
  final String? currency;
  final String? statusDetail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool? walletCredited;
  final bool? walletRefunded;

  bool get indicatesCardPaymentFlow {
    final normalizedMethodId = paymentMethodId?.trim().toLowerCase();
    final normalizedProvider = paymentProvider?.trim().toLowerCase();
    final normalizedStatusDetail = statusDetail?.trim().toLowerCase();

    if (normalizedMethodId == 'card') {
      return true;
    }

    if (_isCheckoutNotStartedDetail(normalizedStatusDetail)) {
      return normalizedMethodId == 'card';
    }

    if (normalizedProvider == 'mercadopago') {
      return true;
    }

    return paymentId?.trim().isNotEmpty == true;
  }

  String get effectiveStatus {
    final normalizedPaymentStatus = paymentStatus.trim().toLowerCase();
    final normalizedLegacyStatus = status?.trim().toLowerCase();
    final normalizedStatusDetail = statusDetail?.trim().toLowerCase();

    final mappedLegacyStatus = _mapLegacyStatus(normalizedLegacyStatus);
    if (mappedLegacyStatus != null) {
      return mappedLegacyStatus;
    }

    switch (normalizedPaymentStatus) {
      case 'paid':
      case 'approved':
      case 'success':
      case 'sucess':
      case 'accredited':
        return 'approved';
      case 'unpaid':
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'failure':
      case 'failed':
        return _isExpiredDetail(normalizedStatusDetail)
            ? 'expired'
            : 'rejected';
      case 'created':
      case 'not_started':
      case 'initialized':
        return 'created';
      case 'pending':
        if (_isCheckoutNotStartedDetail(normalizedStatusDetail)) {
          return 'created';
        }
        return 'pending';
      case 'expired':
      case 'timeout':
      case 'timed_out':
      case 'payment_timeout':
        return 'expired';
      default:
        return normalizedPaymentStatus;
    }
  }

  bool get isFinal {
    switch (effectiveStatus) {
      case 'approved':
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'expired':
      case 'timeout':
      case 'timed_out':
      case 'failure':
      case 'failed':
        return true;
      default:
        return false;
    }
  }

  static String? _mapLegacyStatus(String? normalizedStatus) {
    switch (normalizedStatus) {
      case 'approved':
      case 'success':
      case 'sucess':
      case 'accredited':
        return 'approved';
      case 'created':
      case 'not_started':
      case 'initialized':
        return 'created';
      case 'pending':
      case 'in_process':
      case 'authorized':
      case 'in_mediation':
        return 'pending';
      case 'expired':
      case 'timeout':
      case 'timed_out':
      case 'payment_timeout':
        return 'expired';
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'failure':
      case 'failed':
      case 'refunded':
      case 'charged_back':
        return 'rejected';
      default:
        return null;
    }
  }

  static bool _isCheckoutNotStartedDetail(String? normalizedStatusDetail) {
    switch (normalizedStatusDetail) {
      case 'card_checkout_not_started':
      case 'payment_method_not_selected':
        return true;
      default:
        return false;
    }
  }

  static bool _isExpiredDetail(String? normalizedStatusDetail) {
    switch (normalizedStatusDetail) {
      case 'timeout_unconfirmed':
      case 'payment_timeout':
        return true;
      default:
        return false;
    }
  }
}
