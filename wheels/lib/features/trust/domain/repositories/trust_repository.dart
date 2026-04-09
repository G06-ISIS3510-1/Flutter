import '../entities/trust_entity.dart';

abstract class TrustRepository {
  const TrustRepository();

  Future<TrustEntity> getTrustData(String userId);
}
