import 'package:wheels/features/rides/data/models/local_ride_details_cache_model.dart';
import 'package:wheels/features/rides/data/models/local_ride_search_cache_model.dart';
import 'package:wheels/features/rides/domain/entities/rides_entity.dart';
import 'package:wheels/features/rides/presentation/models/ride_listing.dart';

RidesEntity buildTestRide({
  String id = 'ride-1',
  String status = 'open',
  RidePaymentOption paymentOption = RidePaymentOption.card,
  DateTime? departureAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  List<String>? passengerIds,
}) {
  final departure = departureAt ?? DateTime.utc(2026, 4, 24, 13, 0);
  final created = createdAt ?? DateTime.utc(2026, 4, 24, 10, 0);
  final updated = updatedAt ?? DateTime.utc(2026, 4, 24, 11, 0);

  return RidesEntity(
    id: id,
    driverId: 'driver-1',
    driverName: 'Martin Driver',
    driverEmail: 'martin@uniandes.edu.co',
    origin: 'Uniandes',
    destination: 'Cedritos',
    departureAt: departure,
    estimatedDurationMinutes: 35,
    totalSeats: 4,
    availableSeats: 2,
    pricePerSeat: 12000,
    paymentOption: paymentOption,
    status: status,
    notes: 'Please be on time.',
    passengerIds: passengerIds ?? const <String>['passenger-1', 'passenger-2'],
    createdAt: created,
    updatedAt: updated,
    driverRating: 4.8,
    reviewCount: 16,
    onTimeRate: 92,
    verifiedByUniversity: true,
  );
}

LocalRideSearchFiltersModel buildSearchFilters({
  String originQuery = 'Uniandes',
  String destinationQuery = 'Cedritos',
  DateTime? selectedDate,
  RideSortOption sort = RideSortOption.smartMatch,
}) {
  return LocalRideSearchFiltersModel(
    originQuery: originQuery,
    destinationQuery: destinationQuery,
    selectedDate: selectedDate ?? DateTime.utc(2026, 4, 24, 18, 45),
    sort: sort,
  );
}

LocalRideSearchCacheModel buildSearchCache({
  DateTime? savedAt,
  LocalRideSearchFiltersModel? filters,
  List<LocalRideSearchResultModel>? results,
}) {
  return LocalRideSearchCacheModel(
    version: LocalRideSearchCacheModel.currentVersion,
    savedAt: savedAt ?? DateTime.utc(2026, 4, 24, 12, 0),
    filters: filters ?? buildSearchFilters(),
    results:
        results ??
        <LocalRideSearchResultModel>[
          LocalRideSearchResultModel.fromEntity(buildTestRide(id: 'ride-1')),
          LocalRideSearchResultModel.fromEntity(
            buildTestRide(
              id: 'ride-2',
              paymentOption: RidePaymentOption.bankTransfer,
              departureAt: DateTime.utc(2026, 4, 24, 15, 30),
            ),
          ),
        ],
  );
}

LocalRideDetailsCacheModel buildRideDetailsCache({
  String rideId = 'ride-1',
  DateTime? savedAt,
}) {
  final ride = buildTestRide(id: rideId);
  return LocalRideDetailsCacheModel(
    version: LocalRideDetailsCacheModel.currentVersion,
    rideId: ride.id,
    savedAt: savedAt ?? DateTime.utc(2026, 4, 24, 12, 0),
    ride: LocalRideDetailsModel.fromEntity(ride),
  );
}
