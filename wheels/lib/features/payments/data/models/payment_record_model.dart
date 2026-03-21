import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment_record.dart';

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.rideId,
    required super.status,
    super.paymentId,
    super.mpStatus,
    super.transactionAmount,
    super.paymentMethodId,
    super.statusDetail,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    final rideId = _readString(json['rideId']) ?? _readString(json['ride_id']);
    final status = _readString(json['status']) ?? 'unknown';

    if (rideId == null || rideId.isEmpty) {
      throw const FormatException('Payment status response is missing rideId.');
    }

    return PaymentRecordModel(
      rideId: rideId,
      status: status,
      paymentId:
          _readString(json['paymentId']) ?? _readString(json['payment_id']),
      mpStatus: _readString(json['mpStatus']) ?? _readString(json['mp_status']),
      transactionAmount: _readDouble(
        json['transactionAmount'] ?? json['transaction_amount'],
      ),
      paymentMethodId:
          _readString(json['paymentMethodId']) ??
          _readString(json['payment_method_id']),
      statusDetail:
          _readString(json['statusDetail']) ??
          _readString(json['status_detail']),
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
          snapshot.id,
      status: _readString(data['status']) ?? 'unknown',
      paymentId:
          _readString(data['paymentId']) ?? _readString(data['payment_id']),
      mpStatus: _readString(data['mpStatus']) ?? _readString(data['mp_status']),
      transactionAmount: _readDouble(
        data['transactionAmount'] ?? data['transaction_amount'],
      ),
      paymentMethodId:
          _readString(data['paymentMethodId']) ??
          _readString(data['payment_method_id']),
      statusDetail:
          _readString(data['statusDetail']) ??
          _readString(data['status_detail']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rideId': rideId,
      'status': status,
      'paymentId': paymentId,
      'mpStatus': mpStatus,
      'transactionAmount': transactionAmount,
      'paymentMethodId': paymentMethodId,
      'statusDetail': statusDetail,
    };
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
}
