class AppFormatter {
  const AppFormatter._();

  static const double _mercadoPagoBaseRate = 0.0329;
  static const double _mercadoPagoVatRate = 0.19;
  static const double _mercadoPagoFixedFeeCop = 952;

  static String cop(num? value) {
    final roundedValue = (value ?? 0).round();
    final isNegative = roundedValue.isNegative;
    final digits = roundedValue.abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final reverseIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    final prefix = isNegative ? '-COP ' : 'COP ';
    return '$prefix$buffer';
  }

  static double mercadoPagoCardFee(num? amount) {
    final normalizedAmount = (amount ?? 0).toDouble();
    if (normalizedAmount <= 0) {
      return 0;
    }

    final baseCommission = normalizedAmount * _mercadoPagoBaseRate;
    final vatOnCommission = baseCommission * _mercadoPagoVatRate;

    return baseCommission + vatOnCommission + _mercadoPagoFixedFeeCop;
  }

  static double mercadoPagoCardNet(num? amount) {
    final normalizedAmount = (amount ?? 0).toDouble();
    if (normalizedAmount <= 0) {
      return 0;
    }

    final netAmount = normalizedAmount - mercadoPagoCardFee(normalizedAmount);
    return netAmount < 0 ? 0 : netAmount;
  }
}
