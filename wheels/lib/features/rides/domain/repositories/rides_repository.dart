import '../entities/rides_entity.dart';

abstract class RidesRepository {
  const RidesRepository();

  Stream<List<RidesEntity>> watchAvailableRides();

  Stream<RidesEntity?> watchRide(String rideId);

  Stream<RidesEntity?> watchCurrentDriverRide(String driverId);

  Stream<List<RideApplicationEntity>> watchRideApplications(String rideId);

  Stream<RideApplicationEntity?> watchPassengerApplication({
    required String rideId,
    required String passengerId,
  });

  Future<RidesEntity> createRide({
    required String driverId,
    required String driverName,
    required String driverEmail,
    required String origin,
    required String destination,
    required DateTime departureAt,
    required int estimatedDurationMinutes,
    required int totalSeats,
    required int pricePerSeat,
    required String notes,
  });

  Future<void> applyToRide({
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
  });

  Future<void> updateRideStatus({
    required String rideId,
    required String status,
  });
}
