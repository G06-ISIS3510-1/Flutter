import '../../domain/entities/payment_session.dart';

class PaymentSessionModel extends PaymentSession {
  const PaymentSessionModel({
    required super.preferenceId,
    required super.initPoint,
    super.sandboxInitPoint,
  });

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    final preferenceId = _readString(json, const [
      'preferenceId',
      'preference_id',
      'id',
    ]);
    final initPoint = _readString(json, const [
      'initPoint',
      'init_point',
      'checkoutUrl',
    ]);

    if (preferenceId == null || preferenceId.isEmpty) {
      throw const FormatException(
        'Payment session response is missing a preferenceId.',
      );
    }

    if (initPoint == null || initPoint.isEmpty) {
      throw const FormatException(
        'Payment session response is missing an initPoint URL.',
      );
    }

    return PaymentSessionModel(
      preferenceId: preferenceId,
      initPoint: initPoint,
      sandboxInitPoint: _readString(json, const [
        'sandboxInitPoint',
        'sandbox_init_point',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'preferenceId': preferenceId,
      'initPoint': initPoint,
      'sandboxInitPoint': sandboxInitPoint,
    };
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
