import '../../domain/entities/trust_entity.dart';
import '../../domain/repositories/trust_repository.dart';
import '../datasources/trust_local_datasource.dart';
import '../datasources/trust_remote_datasource.dart';
import '../models/local_trust_cache_model.dart';

class TrustRepositoryImpl extends TrustRepository {
  const TrustRepositoryImpl({
    required TrustRemoteDataSource remoteDataSource,
    required TrustLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final TrustRemoteDataSource _remoteDataSource;
  final TrustLocalDataSource _localDataSource;

  @override
  Future<TrustEntity> getTrustData(String userId) async {
    final trust = await _remoteDataSource.getTrustData(userId);
    await _localDataSource.saveTrustScore(
      LocalTrustCacheModel.create(userId: userId, trust: trust),
    );
    return trust;
  }

  @override
  Future<TrustCacheSnapshot?> getCachedTrustData(String userId) async {
    final cache = await _localDataSource.loadTrustScore(userId);
    if (cache == null) {
      return null;
    }
    return TrustCacheSnapshot(
      trust: cache.toEntity(),
      savedAt: cache.savedAt,
      isExpired: cache.isExpired(),
    );
  }

  @override
  Future<void> clearCachedTrustData(String userId) {
    return _localDataSource.clearTrustScore(userId);
  }
}
