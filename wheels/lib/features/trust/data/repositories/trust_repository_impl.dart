import '../../domain/entities/trust_entity.dart';
import '../../domain/repositories/trust_repository.dart';
import '../datasources/trust_remote_datasource.dart';

class TrustRepositoryImpl extends TrustRepository {
  const TrustRepositoryImpl({required TrustRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TrustRemoteDataSource _remoteDataSource;

  @override
  Future<TrustEntity> getTrustData(String userId) {
    return _remoteDataSource.getTrustData(userId);
  }
}
