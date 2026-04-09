import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_session_model.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _createPreferenceUri = Uri.parse(
    'https://createpreference-tus5lo6p3a-uc.a.run.app',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);

  final http.Client _client;

  Future<PaymentSessionModel> createPreference({
    required String rideId,
    required String title,
    required double unitPrice,
    required int quantity,
    required String payerEmail,
    required String userId,
    required String passengerId,
  }) async {
    final response = await _client
        .post(
          _createPreferenceUri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'rideId': rideId,
            'title': title,
            'unitPrice': unitPrice,
            'quantity': quantity,
            'payerEmail': payerEmail,
            'userId': userId,
            'passengerId': passengerId,
          }),
        )
        .timeout(_requestTimeout);
    final jsonMap = _decodeMap(response.body);

    if (!_isSuccessStatus(response.statusCode)) {
      throw PaymentRemoteException(
        _extractErrorMessage(
          jsonMap,
          fallback: 'Could not create the checkout session.',
          rawBody: response.body,
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final payload = _unwrapPayload(
      jsonMap,
      preferredKeys: const <String>['data', 'preference', 'result', 'payment'],
    );
    return PaymentSessionModel.fromJson(payload);
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

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

  Map<String, dynamic> _unwrapPayload(
    Map<String, dynamic> json, {
    List<String> preferredKeys = const <String>['data', 'payment', 'result'],
  }) {
    for (final key in preferredKeys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return json;
  }

  String _extractErrorMessage(
    Map<String, dynamic> json, {
    required String fallback,
    String? rawBody,
  }) {
    for (final key in const <String>['message', 'error', 'details', 'detail']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final errors = json['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map<String, dynamic>) {
        for (final key in const <String>['message', 'error', 'detail']) {
          final value = first[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    }

    if (rawBody != null &&
        rawBody.trim().isNotEmpty &&
        rawBody.trim() != '{}') {
      return rawBody.trim();
    }

    return fallback;
  }

  bool _isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
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
