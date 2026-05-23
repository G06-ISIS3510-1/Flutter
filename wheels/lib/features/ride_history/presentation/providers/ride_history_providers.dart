import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/providers/connectivity_provider.dart';
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

class RideHistoryLoadState {
  const RideHistoryLoadState({
    required this.entries,
    required this.isFromCache,
    required this.hasRemoteError,
  });

  final List<RideHistoryEntity> entries;
  final bool isFromCache;
  final bool hasRemoteError;
}

final rideHistoryProvider =
    AsyncNotifierProvider<RideHistoryNotifier, RideHistoryLoadState>(
      RideHistoryNotifier.new,
    );

class RideHistoryNotifier extends AsyncNotifier<RideHistoryLoadState> {
  @override
  Future<RideHistoryLoadState> build() async {
    final user = ref.watch(authUserProvider);
    if (user == null) {
      return const RideHistoryLoadState(
        entries: [],
        isFromCache: false,
        hasRemoteError: false,
      );
    }

    final isOnline = ref.watch(connectivityStatusProvider).valueOrNull ?? true;
    return _loadForUser(user.uid, isOnline: isOnline);
  }

  Future<void> refresh() async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      state = const AsyncData(
        RideHistoryLoadState(
          entries: [],
          isFromCache: false,
          hasRemoteError: false,
        ),
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final isOnline = await ref.read(connectivityServiceProvider).hasConnection();
      return _loadForUser(user.uid, isOnline: isOnline);
    });
  }

  Future<RideHistoryLoadState> _loadForUser(
    String userId, {
    required bool isOnline,
  }) async {
    final repository = ref.read(rideHistoryRepositoryProvider);
    final cachedEntries = await repository.getCachedHistory(userId);
    final cachedState = RideHistoryLoadState(
      entries: cachedEntries,
      isFromCache: cachedEntries.isNotEmpty,
      hasRemoteError: false,
    );

    if (cachedEntries.isNotEmpty) {
      state = AsyncData(cachedState);
    }

    if (!isOnline) {
      return cachedState;
    }

    try {
      final liveEntries = await repository.getHistory(userId);
      return RideHistoryLoadState(
        entries: liveEntries,
        isFromCache: false,
        hasRemoteError: false,
      );
    } catch (_) {
      if (cachedEntries.isNotEmpty) {
        return RideHistoryLoadState(
          entries: cachedEntries,
          isFromCache: true,
          hasRemoteError: true,
        );
      }
      rethrow;
    }
  }
}
