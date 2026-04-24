import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/ride_history_local_datasource.dart';
import '../../data/datasources/ride_history_remote_datasource.dart';
import '../../data/repositories/ride_history_repository_impl.dart';
import '../../domain/entities/ride_history_entity.dart';
import '../../domain/repositories/ride_history_repository.dart';

final rideHistoryRemoteDataSourceProvider =
    Provider<RideHistoryRemoteDataSource>(
      (ref) => RideHistoryRemoteDataSource(),
    );

final rideHistoryLocalDataSourceProvider = Provider<RideHistoryLocalDataSource>(
  (ref) => RideHistoryLocalDataSource(),
);

final rideHistoryRepositoryProvider = Provider<RideHistoryRepository>((ref) {
  return RideHistoryRepositoryImpl(
    remoteDataSource: ref.watch(rideHistoryRemoteDataSourceProvider),
    localDataSource: ref.watch(rideHistoryLocalDataSourceProvider),
  );
});

final rideHistoryProvider = FutureProvider<List<RideHistoryEntity>>((
  ref,
) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return const [];
  return ref.watch(rideHistoryRepositoryProvider).getHistory(user.uid);
});
