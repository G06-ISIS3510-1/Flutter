const int walletMinimumWithdrawalAmountCop = 10000;

class WalletSummary {
  const WalletSummary({
    required this.availableBalance,
    required this.pendingWithdrawalBalance,
    required this.totalEarned,
  });

  final double availableBalance;
  final double pendingWithdrawalBalance;
  final double totalEarned;

  bool get isEmpty =>
      availableBalance <= 0 &&
      pendingWithdrawalBalance <= 0 &&
      totalEarned <= 0;

  bool get canRequestWithdrawal =>
      availableBalance >= walletMinimumWithdrawalAmountCop;
}

class WalletFailure implements Exception {
  const WalletFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
