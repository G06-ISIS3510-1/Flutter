import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/withdrawal_request_input.dart';
import '../models/wallet_summary_model.dart';
import '../models/withdrawal_response_model.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _createWithdrawalRequestUri = Uri.parse(
    'https://us-central1-wheels-fd8c0.cloudfunctions.net/createWithdrawalRequest',
  );
  static final Uri _processWithdrawalRequestUri = Uri.parse(
    'https://us-central1-wheels-fd8c0.cloudfunctions.net/processWithdrawalRequest',
  );
  static final Uri _getWalletSummaryUri = Uri.parse(
    'https://us-central1-wheels-fd8c0.cloudfunctions.net/getWalletSummary',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);

  final http.Client _client;

  Future<WalletSummaryModel> getWalletSummary({required String userId}) async {
    final response = await _client
        .get(
          _getWalletSummaryUri.replace(
            queryParameters: <String, String>{'userId': userId},
          ),
        )
        .timeout(_requestTimeout);
    final jsonMap = _decodeMap(response.body);

    if (!_isSuccessStatus(response.statusCode) || _isExplicitFailure(jsonMap)) {
      throw WalletRemoteException(
        _extractErrorMessage(
          jsonMap,
          fallback: 'Could not load the wallet summary.',
          rawBody: response.body,
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final payload = _unwrapPayload(
      jsonMap,
      preferredKeys: const <String>['data', 'wallet', 'summary', 'result'],
    );
    return WalletSummaryModel.fromJson(payload);
  }

  Future<WithdrawalRequestResultModel> createWithdrawalRequest({
    required WithdrawalRequestInput input,
  }) async {
    final response = await _client
        .post(
          _createWithdrawalRequestUri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(input.toJson()),
        )
        .timeout(_requestTimeout);
    final jsonMap = _decodeMap(response.body);

    if (!_isSuccessStatus(response.statusCode) || _isExplicitFailure(jsonMap)) {
      throw WalletRemoteException(
        _extractErrorMessage(
          jsonMap,
          fallback: 'Could not create the withdrawal request.',
          rawBody: response.body,
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final payload = _unwrapPayload(
      jsonMap,
      preferredKeys: const <String>['data', 'result', 'request'],
    );
    return WithdrawalRequestResultModel.fromJson(<String, dynamic>{
      ...jsonMap,
      ...payload,
    });
  }

  Future<WithdrawalProcessResultModel> processWithdrawalRequest({
    required WithdrawalProcessInput input,
  }) async {
    final response = await _client
        .post(
          _processWithdrawalRequestUri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(input.toJson()),
        )
        .timeout(_requestTimeout);
    final jsonMap = _decodeMap(response.body);

    if (!_isSuccessStatus(response.statusCode) || _isExplicitFailure(jsonMap)) {
      throw WalletRemoteException(
        _extractErrorMessage(
          jsonMap,
          fallback: 'Could not process the withdrawal request.',
          rawBody: response.body,
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final payload = _unwrapPayload(
      jsonMap,
      preferredKeys: const <String>['data', 'result', 'request'],
    );
    return WithdrawalProcessResultModel.fromJson(<String, dynamic>{
      ...jsonMap,
      ...payload,
    });
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
    List<String> preferredKeys = const <String>['data', 'result'],
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
    for (final key in const <String>['message', 'error', 'detail', 'details']) {
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

  bool _isExplicitFailure(Map<String, dynamic> json) {
    final success = json['success'];
    return success is bool && success == false;
  }

  bool _isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
}

class WalletRemoteException implements Exception {
  const WalletRemoteException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}
