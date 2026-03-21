import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_record_model.dart';
import '../models/payment_session_model.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _createPreferenceUri = Uri.parse(
    'https://createpreference-tus5lo6p3a-uc.a.run.app',
  );
  static final Uri _paymentStatusUri = Uri.parse(
    'https://getpaymentstatus-tus5lo6p3a-uc.a.run.app',
  );

  final http.Client _client;

  Future<PaymentSessionModel> createPreference({
    required String rideId,
    required String title,
    required double unitPrice,
    required int quantity,
    required String payerEmail,
    required String userId,
  }) async {
    final response = await _client.post(
      _createPreferenceUri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'rideId': rideId,
        'title': title,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'payerEmail': payerEmail,
        'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw PaymentRemoteException(
        'Could not create the checkout session.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final jsonMap = _decodeMap(response.body);
    final payload = _unwrapPayload(jsonMap);
    return PaymentSessionModel.fromJson(payload);
  }

  Future<PaymentRecordModel> getPaymentStatus(String rideId) async {
    final response = await _client.get(
      _paymentStatusUri.replace(
        queryParameters: <String, String>{'rideId': rideId},
      ),
    );

    if (response.statusCode != 200) {
      throw PaymentRemoteException(
        'Could not fetch payment status.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final jsonMap = _decodeMap(response.body);
    final payload = _unwrapPayload(jsonMap);
    final normalizedPayload = <String, dynamic>{
      'rideId': payload['rideId'] ?? payload['ride_id'] ?? rideId,
      ...payload,
    };
    return PaymentRecordModel.fromJson(normalizedPayload);
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Response is not a JSON object.');
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Response body is not valid JSON.');
    }
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    for (final key in const ['data', 'payment', 'result']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return json;
  }
}

class PaymentRemoteException implements Exception {
  const PaymentRemoteException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}
