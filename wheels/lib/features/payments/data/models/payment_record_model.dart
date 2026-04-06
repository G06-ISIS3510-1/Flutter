import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment_record.dart';

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.rideId,
    required super.passengerId,
    required super.paymentStatus,
    super.status,
    super.paymentId,
    super.mpStatus,
    super.transactionAmount,
    super.paymentMethodId,
    super.paymentType,
    super.paymentMode,
    super.paymentProvider,
    super.currency,
    super.statusDetail,
    super.createdAt,
    super.updatedAt,
    super.expiresAt,
    super.walletCredited,
    super.walletRefunded,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    final payload = _mergeNestedPayload(json);
    final rideId =
        _readString(payload['rideId']) ?? _readString(payload['ride_id']);
    final passengerId =
        _readString(payload['passengerId']) ??
        _readString(payload['passenger_id']) ??
        _readString(payload['userId']) ??
        _readString(payload['user_id']) ??
        _readString(payload['payerUserId']) ??
        _readString(payload['payer_user_id']);
    final paymentStatus =
        _readString(payload['paymentStatus']) ??
        _readString(payload['payment_status']) ??
        'unknown';

    if (rideId == null || rideId.isEmpty) {
      throw const FormatException('Payment status response is missing rideId.');
    }
    if (passengerId == null || passengerId.isEmpty) {
      throw const FormatException(
        'Payment status response is missing passengerId.',
      );
    }

    return PaymentRecordModel(
      rideId: rideId,
      passengerId: passengerId,
      paymentStatus: paymentStatus,
      status: _readString(payload['status']),
      paymentId:
          _readString(payload['paymentId']) ??
          _readString(payload['payment_id']),
      mpStatus:
          _readString(payload['mpStatus']) ?? _readString(payload['mp_status']),
      transactionAmount: _readDouble(
        payload['transactionAmount'] ??
            payload['transaction_amount'] ??
            payload['amount'],
      ),
      paymentMethodId:
          _readString(payload['paymentMethodId']) ??
          _readString(payload['payment_method_id']),
      paymentType:
          _readString(payload['paymentType']) ??
          _readString(payload['payment_type']),
      paymentMode:
          _readString(payload['paymentMode']) ??
          _readString(payload['payment_mode']),
      paymentProvider:
          _readString(payload['paymentProvider']) ??
          _readString(payload['payment_provider']),
      currency:
          _readString(payload['currency']) ??
          _readString(payload['currencyId']) ??
          _readString(payload['currency_id']),
      statusDetail:
          _readString(payload['statusDetail']) ??
          _readString(payload['status_detail']),
      createdAt:
          _readDateTime(payload['createdAt']) ??
          _readDateTime(payload['created_at']),
      updatedAt:
          _readDateTime(payload['updatedAt']) ??
          _readDateTime(payload['updated_at']),
      expiresAt:
          _readDateTime(payload['expiresAt']) ??
          _readDateTime(payload['expires_at']),
      walletCredited:
          _readBool(payload['walletCredited']) ??
          _readBool(payload['wallet_credited']),
      walletRefunded:
          _readBool(payload['walletRefunded']) ??
          _readBool(payload['wallet_refunded']),
    );
  }

  factory PaymentRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw const FormatException('Payment document is empty.');
    }

    return PaymentRecordModel(
      rideId:
          _readString(data['rideId']) ??
          _readString(data['ride_id']) ??
          _readString((snapshot.reference.parent.parent)?.id) ??
          snapshot.id,
      passengerId:
          _readString(data['passengerId']) ??
          _readString(data['passenger_id']) ??
          _readString(data['userId']) ??
          _readString(data['user_id']) ??
          snapshot.id,
      paymentStatus:
          _readString(data['paymentStatus']) ??
          _readString(data['payment_status']) ??
          'unknown',
      status: _readString(data['status']),
      paymentId:
          _readString(data['paymentId']) ?? _readString(data['payment_id']),
      mpStatus: _readString(data['mpStatus']) ?? _readString(data['mp_status']),
      transactionAmount: _readDouble(
        data['transactionAmount'] ?? data['transaction_amount'],
      ),
      paymentMethodId:
          _readString(data['paymentMethodId']) ??
          _readString(data['payment_method_id']),
      paymentType:
          _readString(data['paymentType']) ?? _readString(data['payment_type']),
      paymentMode:
          _readString(data['paymentMode']) ?? _readString(data['payment_mode']),
      paymentProvider:
          _readString(data['paymentProvider']) ??
          _readString(data['payment_provider']),
      currency:
          _readString(data['currency']) ??
          _readString(data['currencyId']) ??
          _readString(data['currency_id']),
      statusDetail:
          _readString(data['statusDetail']) ??
          _readString(data['status_detail']),
      createdAt:
          _readDateTime(data['createdAt']) ?? _readDateTime(data['created_at']),
      updatedAt:
          _readDateTime(data['updatedAt']) ?? _readDateTime(data['updated_at']),
      expiresAt:
          _readDateTime(data['expiresAt']) ?? _readDateTime(data['expires_at']),
      walletCredited:
          _readBool(data['walletCredited']) ??
          _readBool(data['wallet_credited']),
      walletRefunded:
          _readBool(data['walletRefunded']) ??
          _readBool(data['wallet_refunded']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rideId': rideId,
      'passengerId': passengerId,
      'paymentStatus': paymentStatus,
      'status': status,
      'paymentId': paymentId,
      'mpStatus': mpStatus,
      'transactionAmount': transactionAmount,
      'paymentMethodId': paymentMethodId,
      'paymentType': paymentType,
      'paymentMode': paymentMode,
      'paymentProvider': paymentProvider,
      'currency': currency,
      'statusDetail': statusDetail,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'walletCredited': walletCredited,
      'walletRefunded': walletRefunded,
    };
  }

  static Map<String, dynamic> _mergeNestedPayload(Map<String, dynamic> json) {
    final merged = <String, dynamic>{...json};

    for (final key in const <String>[
      'payment',
      'paymentDocument',
      'payment_document',
      'document',
    ]) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        merged.addAll(value);
      }
    }

    return merged;
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }

    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      final milliseconds = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;

      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds * 1000) + ((nanoseconds as num).toInt() ~/ 1000000),
          isUtc: true,
        ).toLocal();
      }
    }

    return null;
  }
}
