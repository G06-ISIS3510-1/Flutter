import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/rides/data/models/local_ride_details_cache_model.dart';

import '../../../../support/ride_test_data.dart';

void main() {
  group('LocalRideDetailsCacheModel', () {
    test('round-trips through json and restores the ride entity', () {
      final cache = buildRideDetailsCache();

      final restored = LocalRideDetailsCacheModel.fromJson(cache.toJson());
      final entity = restored.toEntity();

      expect(restored.version, LocalRideDetailsCacheModel.currentVersion);
      expect(restored.rideId, 'ride-1');
      expect(entity.id, 'ride-1');
      expect(entity.origin, 'Uniandes');
      expect(entity.destination, 'Cedritos');
      expect(entity.driverRating, 4.8);
    });

    test('throws when rideId does not match stored ride payload', () {
      final invalidJson = buildRideDetailsCache().toJson()
        ..['rideId'] = 'different-ride';

      expect(
        () => LocalRideDetailsCacheModel.fromJson(invalidJson),
        throwsFormatException,
      );
    });

    test('matchesRide only returns true for the cached ride id', () {
      final cache = buildRideDetailsCache(rideId: 'ride-42');

      expect(cache.matchesRide('ride-42'), isTrue);
      expect(cache.matchesRide('ride-99'), isFalse);
    });

    test('isExpired returns true for very old cache entries', () {
      final oldCache = buildRideDetailsCache(
        savedAt: DateTime.now().toUtc().subtract(const Duration(hours: 7)),
      );

      expect(oldCache.isExpired(), isTrue);
    });

    test('isExpired returns true for future timestamps beyond tolerance', () {
      final futureCache = buildRideDetailsCache(
        savedAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      );

      expect(futureCache.isExpired(), isTrue);
    });

    test('isExpired returns false for recent cache entries', () {
      final freshCache = buildRideDetailsCache(
        savedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
      );

      expect(freshCache.isExpired(), isFalse);
    });
  });
}
