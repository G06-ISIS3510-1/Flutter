import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/rides/data/models/local_ride_search_cache_model.dart';
import 'package:wheels/features/rides/domain/entities/rides_entity.dart';
import 'package:wheels/features/rides/presentation/models/ride_listing.dart';

import '../../../../support/ride_test_data.dart';

void main() {
  group('LocalRideSearchFiltersModel', () {
    test('serializes selectedDate as a date-only value', () {
      final filters = buildSearchFilters(
        selectedDate: DateTime.utc(2026, 4, 24, 18, 45),
        sort: RideSortOption.cheapest,
      );

      final json = filters.toJson();

      expect(json['selectedDate'], '2026-04-24');
      expect(json['sort'], 'cheapest');
    });

    test('normalizes selectedDate when reading from json', () {
      final filters = LocalRideSearchFiltersModel.fromJson(<String, dynamic>{
        'originQuery': 'Uniandes',
        'destinationQuery': 'Chapinero',
        'selectedDate': '2026-04-24T19:30:00.000Z',
        'sort': 'highestRated',
      });

      expect(filters.selectedDate, DateTime(2026, 4, 24));
      expect(filters.sort, RideSortOption.highestRated);
    });

    test('throws when sort value is unsupported', () {
      expect(
        () => LocalRideSearchFiltersModel.fromJson(<String, dynamic>{
          'originQuery': 'Uniandes',
          'destinationQuery': 'Cedritos',
          'selectedDate': '2026-04-24',
          'sort': 'fastest',
        }),
        throwsFormatException,
      );
    });
  });

  group('LocalRideSearchCacheModel', () {
    test('round-trips through json and restores entities', () {
      final cache = buildSearchCache();

      final restored = LocalRideSearchCacheModel.fromJson(cache.toJson());
      final entities = restored.toEntities();

      expect(restored.version, LocalRideSearchCacheModel.currentVersion);
      expect(restored.savedAt, cache.savedAt);
      expect(restored.filters.originQuery, cache.filters.originQuery);
      expect(restored.filters.destinationQuery, cache.filters.destinationQuery);
      expect(restored.filters.selectedDate, cache.filters.selectedDate);
      expect(restored.results, hasLength(2));
      expect(entities.map((ride) => ride.id), <String>['ride-1', 'ride-2']);
      expect(
        entities.map((ride) => ride.paymentOption),
        <Object>[RidePaymentOption.card, RidePaymentOption.bankTransfer],
      );
    });

    test('create builds a versioned cache from rides entities', () {
      final cache = LocalRideSearchCacheModel.create(
        filters: buildSearchFilters(sort: RideSortOption.earliest),
        results: <RidesEntity>[
          buildTestRide(id: 'ride-1'),
          buildTestRide(id: 'ride-2'),
        ],
      );

      expect(cache.version, LocalRideSearchCacheModel.currentVersion);
      expect(cache.results, hasLength(2));
      expect(cache.filters.sort, RideSortOption.earliest);
    });

    test('throws when cache version is unsupported', () {
      final invalidJson = buildSearchCache().toJson()..['version'] = 999;

      expect(
        () => LocalRideSearchCacheModel.fromJson(invalidJson),
        throwsFormatException,
      );
    });

    test('throws when a result item is not a map', () {
      final invalidJson = buildSearchCache().toJson()..['results'] = <Object>[
          'not-a-map',
        ];

      expect(
        () => LocalRideSearchCacheModel.fromJson(invalidJson),
        throwsFormatException,
      );
    });
  });
}
