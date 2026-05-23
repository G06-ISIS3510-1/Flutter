import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../ride_history/presentation/providers/ride_history_providers.dart';
import '../../data/cache/saved_destinations_distance_cache.dart';
import '../../data/datasources/saved_destinations_local_datasource.dart';
import '../../data/datasources/saved_destinations_preferences_local_datasource.dart';
import '../../data/datasources/saved_destinations_remote_datasource.dart';
import '../../data/isolates/distance_batch_isolate.dart';
import '../../data/repositories/saved_destinations_repository_impl.dart';
import '../../data/sync/saved_destinations_sync_worker.dart';
import '../../domain/entities/saved_destination.dart';
import '../../domain/repositories/saved_destinations_repository.dart';

final savedDestinationsFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final savedDestinationsLocalDataSourceProvider =
    Provider<SavedDestinationsLocalDataSource>((ref) {
      final ds = SavedDestinationsLocalDataSource();
      ref.onDispose(() => ds.dispose());
      return ds;
    });

final savedDestinationsPreferencesProvider =
    Provider<SavedDestinationsPreferencesLocalDataSource>((ref) {
      return const SavedDestinationsPreferencesLocalDataSource();
    });

final savedDestinationsRemoteDataSourceProvider =
    Provider<SavedDestinationsRemoteDataSource>((ref) {
      return SavedDestinationsRemoteDataSource(
        firestore: ref.watch(savedDestinationsFirestoreProvider),
      );
    });

final savedDestinationsDistanceCacheProvider =
    Provider<SavedDestinationsDistanceCache>((ref) {
      final cache = SavedDestinationsDistanceCache();
      ref.onDispose(cache.clear);
      return cache;
    });

final savedDestinationsDistanceIsolateProvider =
    Provider<DistanceBatchIsolate>((ref) {
      return const DistanceBatchIsolate();
    });

final savedDestinationsRepositoryProvider =
    Provider<SavedDestinationsRepository>((ref) {
      return SavedDestinationsRepositoryImpl(
        localDataSource: ref.watch(savedDestinationsLocalDataSourceProvider),
        remoteDataSource: ref.watch(savedDestinationsRemoteDataSourceProvider),
        preferencesDataSource: ref.watch(savedDestinationsPreferencesProvider),
        distanceCache: ref.watch(savedDestinationsDistanceCacheProvider),
        distanceBatchIsolate: ref.watch(savedDestinationsDistanceIsolateProvider),
        rideHistoryLocalDataSource: ref.watch(rideHistoryLocalDataSourceProvider),
      );
    });

final savedDestinationsCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider)?.uid;
});

final savedDestinationsSortProvider =
    StateProvider<SavedDestinationsSort>((ref) {
      return SavedDestinationsSort.recent;
    });

final savedDestinationsStreamProvider =
    StreamProvider.autoDispose<List<SavedDestination>>((ref) {
      final userId = ref.watch(savedDestinationsCurrentUserIdProvider);
      if (userId == null) {
        return Stream<List<SavedDestination>>.value(const <SavedDestination>[]);
      }
      final sort = ref.watch(savedDestinationsSortProvider);
      return ref
          .watch(savedDestinationsRepositoryProvider)
          .watchDestinations(userId, sort: sort);
    });

final savedDestinationsLastQuickPickProvider =
    FutureProvider.autoDispose<SavedDestination?>((ref) async {
      final userId = ref.watch(savedDestinationsCurrentUserIdProvider);
      if (userId == null) {
        return null;
      }
      return ref.watch(savedDestinationsRepositoryProvider).loadLastQuickPick(userId);
    });

final savedDestinationsCurrentPositionProvider =
    FutureProvider.autoDispose<Position?>((ref) async {
      final permission = await Geolocator.checkPermission();
      var resolvedPermission = permission;
      if (resolvedPermission == LocationPermission.denied) {
        resolvedPermission = await Geolocator.requestPermission();
      }
      if (resolvedPermission == LocationPermission.denied ||
          resolvedPermission == LocationPermission.deniedForever) {
        return null;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    });

class SavedDestinationsBootstrapData {
  const SavedDestinationsBootstrapData({
    required this.position,
    required this.lastQuickPick,
  });

  final Position? position;
  final SavedDestination? lastQuickPick;
}

class SavedDestinationTrendingEntry {
  const SavedDestinationTrendingEntry({
    required this.name,
    required this.address,
    required this.saveCount,
  });

  final String name;
  final String address;
  final int saveCount;
}

final savedDestinationsBootstrapProvider =
    FutureProvider.autoDispose<SavedDestinationsBootstrapData>((ref) async {
      final userId = ref.watch(savedDestinationsCurrentUserIdProvider);
      if (userId == null) {
        return const SavedDestinationsBootstrapData(
          position: null,
          lastQuickPick: null,
        );
      }

      final results = await Future.wait<Object?>([
        ref.watch(savedDestinationsCurrentPositionProvider.future),
        ref.watch(savedDestinationsRepositoryProvider).loadLastQuickPick(userId),
      ]);

      return SavedDestinationsBootstrapData(
        position: results[0] as Position?,
        lastQuickPick: results[1] as SavedDestination?,
      );
    });

final savedDestinationByIdProvider =
    FutureProvider.autoDispose.family<SavedDestination?, int>((ref, localId) {
      final userId = ref.watch(savedDestinationsCurrentUserIdProvider);
      if (userId == null) {
        return Future<SavedDestination?>.value(null);
      }
      return ref
          .watch(savedDestinationsRepositoryProvider)
          .loadDestinationById(userId, localId);
    });

final savedDestinationsTrendingProvider =
    FutureProvider.autoDispose<List<SavedDestinationTrendingEntry>>((ref) async {
      final snapshot = await ref
          .watch(savedDestinationsFirestoreProvider)
          .collectionGroup('saved_destinations')
          .where('isDeleted', isEqualTo: false)
          .limit(200)
          .get();

      final counts = <String, SavedDestinationTrendingEntry>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final normalizedAddress =
            (data['normalizedAddress'] as String? ?? '').trim().toLowerCase();
        if (normalizedAddress.isEmpty) {
          continue;
        }

        final existing = counts[normalizedAddress];
        if (existing == null) {
          counts[normalizedAddress] = SavedDestinationTrendingEntry(
            name: (data['name'] as String? ?? data['address'] as String? ?? '')
                .trim(),
            address: (data['address'] as String? ?? '').trim(),
            saveCount: 1,
          );
        } else {
          counts[normalizedAddress] = SavedDestinationTrendingEntry(
            name: existing.name,
            address: existing.address,
            saveCount: existing.saveCount + 1,
          );
        }
      }

      final entries = counts.values.toList(growable: false)
        ..sort((left, right) => right.saveCount.compareTo(left.saveCount));
      return entries.take(5).toList(growable: false);
    });

final savedDestinationsSyncWorkerProvider =
    Provider<SavedDestinationsSyncWorker>((ref) {
      final worker = SavedDestinationsSyncWorker(
        repository: ref.watch(savedDestinationsRepositoryProvider),
        connectivityStream:
            ref.watch(connectivityServiceProvider).watchConnection(),
        currentUserId: () => ref.read(savedDestinationsCurrentUserIdProvider) ?? '',
      );
      worker.start();
      ref.onDispose(() => worker.dispose());
      return worker;
    });

final savedDestinationsFeatureInitProvider = Provider<void>((ref) {
  ref.watch(savedDestinationsSyncWorkerProvider);
});

@visibleForTesting
SavedDestinationsBootstrapData debugSavedDestinationsBootstrapData({
  Position? position,
  SavedDestination? lastQuickPick,
}) {
  return SavedDestinationsBootstrapData(
    position: position,
    lastQuickPick: lastQuickPick,
  );
}
