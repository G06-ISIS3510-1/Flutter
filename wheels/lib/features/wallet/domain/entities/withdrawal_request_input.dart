import 'wallet_summary.dart';

class WithdrawalRequestInput {
  const WithdrawalRequestInput({
    required this.userId,
    required this.amount,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.accountHolderName,
  });

  final String userId;
  final int amount;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String accountHolderName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'amount': amount,
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
  }

  void validate() {
    if (amount < walletMinimumWithdrawalAmountCop) {
      throw const WalletFailure('The minimum withdrawal amount is COP 10.000.');
    }
  }
}

class WithdrawalRequestResult {
  const WithdrawalRequestResult({
    required this.success,
    this.requestId,
    this.message,
    this.walletSummary,
  });

  final bool success;
  final String? requestId;
  final String? message;
  final WalletSummary? walletSummary;
}

class WithdrawalProcessInput {
  const WithdrawalProcessInput({
    required this.requestId,
    required this.action,
    this.adminUserId,
    this.notes,
    this.paymentReference,
  });

  final String requestId;
  final String action;
  final String? adminUserId;
  final String? notes;
  final String? paymentReference;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'action': action,
      if (adminUserId != null && adminUserId!.trim().isNotEmpty)
        'adminUserId': adminUserId,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      if (paymentReference != null && paymentReference!.trim().isNotEmpty)
        'paymentReference': paymentReference,
    };
  }
}

class WithdrawalProcessResult {
  const WithdrawalProcessResult({
    required this.success,
    this.message,
    this.requestId,
  });

  final bool success;
  final String? message;
  final String? requestId;
}
