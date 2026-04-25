class LocalPaymentVerificationCacheModel {
  const LocalPaymentVerificationCacheModel({
    required this.version,
    required this.rideId,
    required this.passengerId,
    required this.markedAt,
    required this.message,
    this.checkoutCreatedAt,
    this.expiresAt,
  });

  static const int currentVersion = 1;

  final int version;
  final String rideId;
  final String passengerId;
  final DateTime markedAt;
  final String message;
  final DateTime? checkoutCreatedAt;
  final DateTime? expiresAt;

  factory LocalPaymentVerificationCacheModel.create({
    required String rideId,
    required String passengerId,
    required String message,
    DateTime? checkoutCreatedAt,
    DateTime? expiresAt,
  }) {
    return LocalPaymentVerificationCacheModel(
      version: currentVersion,
      rideId: rideId,
      passengerId: passengerId,
      markedAt: DateTime.now().toUtc(),
      message: message,
      checkoutCreatedAt: checkoutCreatedAt?.toUtc(),
      expiresAt: expiresAt?.toUtc(),
    );
  }

  factory LocalPaymentVerificationCacheModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported payment verification cache version: $version');
    }

    return LocalPaymentVerificationCacheModel(
      version: version,
      rideId: _readRequiredString(json['rideId'], 'rideId'),
      passengerId: _readRequiredString(json['passengerId'], 'passengerId'),
      markedAt: _readRequiredDateTime(json['markedAt'], 'markedAt'),
      message: _readRequiredString(json['message'], 'message'),
      checkoutCreatedAt: _readOptionalDateTime(json['checkoutCreatedAt']),
      expiresAt: _readOptionalDateTime(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'rideId': rideId,
      'passengerId': passengerId,
      'markedAt': markedAt.toIso8601String(),
      'message': message,
      'checkoutCreatedAt': checkoutCreatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }
  return rawValue;
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
  }
  throw FormatException('Invalid $fieldName value.');
}

DateTime _readRequiredDateTime(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }
  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }
  return parsed;
}

DateTime? _readOptionalDateTime(Object? rawValue) {
  if (rawValue == null) {
    return null;
  }
  if (rawValue is! String) {
    throw const FormatException('Invalid optional DateTime value.');
  }
  return DateTime.tryParse(rawValue);
}
