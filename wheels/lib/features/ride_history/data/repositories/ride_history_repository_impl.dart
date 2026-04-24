import '../../domain/entities/ride_history_entity.dart';
import '../../domain/repositories/ride_history_repository.dart';
import '../datasources/ride_history_local_datasource.dart';
import '../datasources/ride_history_remote_datasource.dart';
import '../models/ride_history_model.dart';

class RideHistoryRepositoryImpl implements RideHistoryRepository {
  const RideHistoryRepositoryImpl({
    required RideHistoryRemoteDataSource remoteDataSource,
    required RideHistoryLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final RideHistoryRemoteDataSource _remoteDataSource;
  final RideHistoryLocalDataSource _localDataSource;

  @override
  Future<List<RideHistoryEntity>> getHistory(String userId) async {
    final entries = await _remoteDataSource.fetchHistory(userId);
    await _localDataSource.saveHistory(entries.cast<RideHistoryModel>());
    return entries;
  }

  @override
  Future<List<RideHistoryEntity>> getCachedHistory(String userId) {
    return _localDataSource.loadHistory(userId);
  }
}
