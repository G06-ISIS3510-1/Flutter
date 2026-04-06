import '../../domain/entities/wallet_summary.dart';

class WalletSummaryModel extends WalletSummary {
  const WalletSummaryModel({
    required super.availableBalance,
    required super.pendingWithdrawalBalance,
    required super.totalEarned,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletSummaryModel(
      availableBalance:
          _readDouble(json['availableBalance'] ?? json['available_balance']) ??
          0,
      pendingWithdrawalBalance:
          _readDouble(
            json['pendingWithdrawalBalance'] ??
                json['pending_withdrawal_balance'],
          ) ??
          0,
      totalEarned:
          _readDouble(json['totalEarned'] ?? json['total_earned']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'availableBalance': availableBalance,
      'pendingWithdrawalBalance': pendingWithdrawalBalance,
      'totalEarned': totalEarned,
    };
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
