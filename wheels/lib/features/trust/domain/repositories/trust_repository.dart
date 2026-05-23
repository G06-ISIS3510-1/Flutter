import '../entities/trust_entity.dart';

abstract class TrustRepository {
  const TrustRepository();

  Future<TrustEntity> getTrustData(String userId);

  Future<TrustCacheSnapshot?> getCachedTrustData(String userId);

  Future<void> clearCachedTrustData(String userId);
}

class TrustCacheSnapshot {
  const TrustCacheSnapshot({
    required this.trust,
    required this.savedAt,
    required this.isExpired,
  });

  final TrustEntity trust;
  final DateTime savedAt;
  final bool isExpired;
}
