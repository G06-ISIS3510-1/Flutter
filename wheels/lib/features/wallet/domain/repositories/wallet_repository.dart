import '../entities/withdrawal_request_input.dart';
import '../entities/wallet_summary.dart';

abstract class WalletRepository {
  Future<WalletSummary> getWalletSummary({required String userId});

  Future<WithdrawalRequestResult> createWithdrawalRequest({
    required WithdrawalRequestInput input,
  });

  Future<WithdrawalProcessResult> processWithdrawalRequest({
    required WithdrawalProcessInput input,
  });
}
