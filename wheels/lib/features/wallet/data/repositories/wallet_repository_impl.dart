import '../../domain/entities/withdrawal_request_input.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<WalletSummary> getWalletSummary({required String userId}) {
    return _remoteDataSource.getWalletSummary(userId: userId);
  }

  @override
  Future<WithdrawalRequestResult> createWithdrawalRequest({
    required WithdrawalRequestInput input,
  }) {
    return _remoteDataSource.createWithdrawalRequest(input: input);
  }

  @override
  Future<WithdrawalProcessResult> processWithdrawalRequest({
    required WithdrawalProcessInput input,
  }) {
    return _remoteDataSource.processWithdrawalRequest(input: input);
  }
}
