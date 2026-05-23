import '../entities/ride_history_entity.dart';

abstract class RideHistoryRepository {
  Future<List<RideHistoryEntity>> getHistory(String userId);
  Future<List<RideHistoryEntity>> getCachedHistory(String userId);
}
