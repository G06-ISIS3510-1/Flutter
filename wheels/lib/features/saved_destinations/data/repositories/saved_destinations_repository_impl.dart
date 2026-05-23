import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../ride_history/data/datasources/ride_history_local_datasource.dart';
import '../../../ride_history/domain/entities/ride_history_entity.dart';
import '../../domain/entities/saved_destination.dart';
import '../../domain/repositories/saved_destinations_repository.dart';
import '../cache/saved_destinations_distance_cache.dart';
import '../datasources/saved_destinations_local_datasource.dart';
import '../datasources/saved_destinations_preferences_local_datasource.dart';
import '../datasources/saved_destinations_remote_datasource.dart';
import '../isolates/distance_batch_isolate.dart';
import '../models/saved_destination_model.dart';

class SavedDestinationsRepositoryImpl implements SavedDestinationsRepository {
  const SavedDestinationsRepositoryImpl({
    required SavedDestinationsLocalDataSource localDataSource,
    required SavedDestinationsRemoteDataSource remoteDataSource,
    required SavedDestinationsPreferencesLocalDataSource preferencesDataSource,
    required SavedDestinationsDistanceCache distanceCache,
    required DistanceBatchIsolate distanceBatchIsolate,
    required RideHistoryLocalDataSource rideHistoryLocalDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _preferencesDataSource = preferencesDataSource,
       _distanceCache = distanceCache,
       _distanceBatchIsolate = distanceBatchIsolate,
       _rideHistoryLocalDataSource = rideHistoryLocalDataSource;

  final SavedDestinationsLocalDataSource _localDataSource;
  final SavedDestinationsRemoteDataSource _remoteDataSource;
  final SavedDestinationsPreferencesLocalDataSource _preferencesDataSource;
  final SavedDestinationsDistanceCache _distanceCache;
  final DistanceBatchIsolate _distanceBatchIsolate;
  final RideHistoryLocalDataSource _rideHistoryLocalDataSource;

  @override
  Stream<List<SavedDestination>> watchDestinations(
    String userId, {
    SavedDestinationsSort sort = SavedDestinationsSort.recent,
  }) {
    return _localDataSource.watchDestinations(
      userId,
      sort: _mapSort(sort),
    );
  }

  @override
  Future<List<SavedDestination>> loadDestinations(
    String userId, {
    SavedDestinationsSort sort = SavedDestinationsSort.recent,
  }) {
    return _localDataSource.loadDestinations(userId, sort: _mapSort(sort));
  }

  @override
  Future<SavedDestination?> loadDestinationById(String userId, int localId) {
    return _localDataSource.loadDestinationById(userId, localId);
  }

  @override
  Future<SavedDestination> saveDestination(SavedDestination destination) async {
    final model = SavedDestinationModel.fromEntity(destination).copyModelWith(
      pendingSync: true,
      isDeleted: false,
    );
    return _localDataSource.upsertDestination(model);
  }

  @override
  Future<void> markDestinationDeleted({
    required String userId,
    required int localId,
  }) async {
    _distanceCache.invalidateDestination(localId);
    await _localDataSource.markDestinationDeleted(userId: userId, localId: localId);
  }

  @override
  Future<SavedDestination?> loadLastQuickPick(String userId) async {
    final localId = await _preferencesDataSource.loadLastQuickPick(userId);
    if (localId == null) {
      return null;
    }
    final destination = await _localDataSource.loadDestinationById(userId, localId);
    if (destination == null || destination.isDeleted) {
      return null;
    }
    return destination;
  }

  @override
  Future<void> saveLastQuickPick({
    required String userId,
    required int localId,
  }) async {
    await _preferencesDataSource.saveLastQuickPick(
      userId: userId,
      localId: localId,
    );

    final destination = await _localDataSource.loadDestinationById(userId, localId);
    if (destination == null) {
      return;
    }

    final updated = destination.copyModelWith(
      useCount: destination.useCount + 1,
      lastUsedAt: DateTime.now().toUtc(),
      pendingSync: true,
    );
    await _localDataSource.upsertDestination(updated);
  }

  @override
  Future<Map<int, double>> loadDistancesForCurrentLocation({
    required double currentLatitude,
    required double currentLongitude,
    required List<SavedDestination> destinations,
  }) async {
    final resolved = <int, double>{};
    final pending = <SavedDestination>[];

    for (final destination in destinations) {
      final localId = destination.localId;
      if (localId == null || !destination.hasResolvedCoordinates) {
        continue;
      }

      final cached = _distanceCache.get(
        destinationId: localId,
        latitude: currentLatitude,
        longitude: currentLongitude,
      );
      if (cached != null) {
        resolved[localId] = cached;
      } else {
        pending.add(destination);
      }
    }

    if (pending.isNotEmpty) {
      final computed = await _distanceBatchIsolate.computeDistances(
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        destinations: pending,
      );
      for (final entry in computed.entries) {
        _distanceCache.put(
          destinationId: entry.key,
          latitude: currentLatitude,
          longitude: currentLongitude,
          distanceKm: entry.value,
        );
        resolved[entry.key] = entry.value;
      }
    }

    return resolved;
  }

  @override
  Future<SavedDestinationUsageStats> loadUsageStats({
    required String userId,
    required SavedDestination destination,
  }) async {
    final history = await _rideHistoryLocalDataSource.loadHistory(userId);
    final matching = history
        .where((entry) => _matchesDestination(entry, destination))
        .toList(growable: false);
    if (matching.isEmpty) {
      return SavedDestinationUsageStats.empty;
    }

    final lastVisits = matching.take(5).map((entry) {
      final date = entry.departureAt.toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month ${entry.origin}';
    }).toList(growable: false);

    final averagePrice =
        matching.fold<int>(0, (sum, entry) => sum + entry.pricePerSeat) /
        matching.length;

    return SavedDestinationUsageStats(
      totalRideCount: matching.length,
      averagePricePerSeat: averagePrice,
      lastVisitLabels: lastVisits,
    );
  }

  @override
  Future<void> syncPending(String userId) async {
    final pending = await _localDataSource.loadPendingSync(userId);
    if (pending.isEmpty) {
      return;
    }

    final encodedBatch = await compute(
      _encodePendingSyncBatch,
      pending.map((item) => item.toRemoteJson()).toList(growable: false),
    );
    final encodedByNormalized = <String, Map<String, Object?>>{
      for (final map in encodedBatch)
        map['normalizedAddress'] as String: map,
    };

    for (final destination in pending) {
      if (destination.localId == null) {
        continue;
      }

      if (destination.isDeleted) {
        if (destination.remoteId != null) {
          await _remoteDataSource.deleteDestination(
            userId: userId,
            remoteId: destination.remoteId!,
          );
        }
        await _localDataSource.hardDelete(
          userId: userId,
          localId: destination.localId!,
        );
        continue;
      }

      final normalizedAddress = destination.address.trim().toLowerCase();
      final remotePayload = encodedByNormalized[normalizedAddress];
      final syncedRemoteId = await _remoteDataSource.upsertDestination(
        destination.copyModelWith(
          pendingSync: false,
          remoteId: destination.remoteId,
          name: remotePayload?['name'] as String? ?? destination.name,
        ),
      );
      await _localDataSource.markSynced(
        userId: userId,
        localId: destination.localId!,
        remoteId: syncedRemoteId,
      );
    }
  }

  SavedDestinationsLocalSort _mapSort(SavedDestinationsSort sort) {
    return sort == SavedDestinationsSort.recent
        ? SavedDestinationsLocalSort.recent
        : SavedDestinationsLocalSort.useCount;
  }

  bool _matchesDestination(
    RideHistoryEntity entry,
    SavedDestination destination,
  ) {
    final normalizedEntryDestination = entry.destination.trim().toLowerCase();
    final normalizedSavedAddress = destination.address.trim().toLowerCase();
    final normalizedSavedName = destination.name.trim().toLowerCase();
    return normalizedEntryDestination.contains(normalizedSavedAddress) ||
        normalizedEntryDestination.contains(normalizedSavedName);
  }
}

List<Map<String, Object?>> _encodePendingSyncBatch(
  List<Map<String, Object?>> batch,
) {
  return batch
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}
