import '../entities/saved_destination.dart';

abstract class SavedDestinationsRepository {
  Stream<List<SavedDestination>> watchDestinations(
    String userId, {
    SavedDestinationsSort sort = SavedDestinationsSort.recent,
  });

  Future<List<SavedDestination>> loadDestinations(
    String userId, {
    SavedDestinationsSort sort = SavedDestinationsSort.recent,
  });

  Future<SavedDestination?> loadDestinationById(String userId, int localId);

  Future<SavedDestination> saveDestination(SavedDestination destination);

  Future<void> markDestinationDeleted({
    required String userId,
    required int localId,
  });

  Future<SavedDestination?> loadLastQuickPick(String userId);

  Future<void> saveLastQuickPick({
    required String userId,
    required int localId,
  });

  Future<Map<int, double>> loadDistancesForCurrentLocation({
    required double currentLatitude,
    required double currentLongitude,
    required List<SavedDestination> destinations,
  });

  Future<SavedDestinationUsageStats> loadUsageStats({
    required String userId,
    required SavedDestination destination,
  });

  Future<void> syncPending(String userId);
}

enum SavedDestinationsSort { recent, useCount }
