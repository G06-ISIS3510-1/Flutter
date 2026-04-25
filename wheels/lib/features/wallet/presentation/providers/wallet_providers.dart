import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/datasources/wallet_summary_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/withdrawal_request_input.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource();
});

final walletSummaryLocalDataSourceProvider =
    Provider<WalletSummaryLocalDataSource>((ref) {
      return const WalletSummaryLocalDataSource();
    });

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
  );
});

final driverWalletSummaryProvider = FutureProvider<WalletSummary?>((ref) async {
  final user = ref.watch(authUserProvider);
  final role = ref.watch(currentUserRoleProvider);

  if (user == null || role != UserRole.driver) {
    return null;
  }

  return ref.watch(walletRepositoryProvider).getWalletSummary(userId: user.uid);
});

final withdrawalRequestControllerProvider =
    StateNotifierProvider<
      WithdrawalRequestController,
      AsyncValue<WithdrawalRequestResult?>
    >((ref) {
      return WithdrawalRequestController(ref);
    });

class WithdrawalRequestController
    extends StateNotifier<AsyncValue<WithdrawalRequestResult?>> {
  WithdrawalRequestController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<WithdrawalRequestResult?> submit({
    required String userId,
    required int amount,
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    state = const AsyncValue.loading();

    final input = WithdrawalRequestInput(
      userId: userId,
      amount: amount,
      bankName: bankName.trim(),
      accountType: accountType.trim(),
      accountNumber: accountNumber.trim(),
      accountHolderName: accountHolderName.trim(),
    );

    try {
      input.validate();
      final result = await _ref
          .read(walletRepositoryProvider)
          .createWithdrawalRequest(input: input);
      _ref.invalidate(driverWalletSummaryProvider);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue<WithdrawalRequestResult?>.error(error, stackTrace);
      return null;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
