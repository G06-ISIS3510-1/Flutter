import '../../domain/entities/withdrawal_request_input.dart';
import 'wallet_summary_model.dart';

class WithdrawalRequestResultModel extends WithdrawalRequestResult {
  const WithdrawalRequestResultModel({
    required super.success,
    super.requestId,
    super.message,
    super.walletSummary,
  });

  factory WithdrawalRequestResultModel.fromJson(Map<String, dynamic> json) {
    final walletSummaryMap = _walletSummaryMap(json);

    return WithdrawalRequestResultModel(
      success: _readBool(json['success']) ?? true,
      requestId:
          _readString(json['requestId']) ??
          _readString(json['request_id']) ??
          _readString(json['id']),
      message:
          _readString(json['message']) ??
          _readString(json['detail']) ??
          _readString(json['details']),
      walletSummary: walletSummaryMap == null
          ? null
          : WalletSummaryModel.fromJson(walletSummaryMap),
    );
  }

  static Map<String, dynamic>? _walletSummaryMap(Map<String, dynamic> json) {
    for (final key in const <String>[
      'walletSummary',
      'wallet_summary',
      'summary',
      'wallet',
    ]) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return null;
  }
}

class WithdrawalProcessResultModel extends WithdrawalProcessResult {
  const WithdrawalProcessResultModel({
    required super.success,
    super.message,
    super.requestId,
  });

  factory WithdrawalProcessResultModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalProcessResultModel(
      success: _readBool(json['success']) ?? true,
      message:
          _readString(json['message']) ??
          _readString(json['detail']) ??
          _readString(json['details']),
      requestId:
          _readString(json['requestId']) ??
          _readString(json['request_id']) ??
          _readString(json['id']),
    );
  }
}

String? _readString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

bool? _readBool(Object? value) {
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
