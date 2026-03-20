import '../../domain/entities/rides_entity.dart';
import '../../domain/repositories/rides_repository.dart';
import '../datasources/rides_remote_datasource.dart';

class RidesRepositoryImpl extends RidesRepository {
  const RidesRepositoryImpl({required RidesRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final RidesRemoteDataSource _remoteDataSource;

  @override
  Stream<List<RidesEntity>> watchAvailableRides() {
    return _remoteDataSource.watchAvailableRides();
  }

  @override
  Stream<RidesEntity?> watchRide(String rideId) {
    return _remoteDataSource.watchRide(rideId);
  }

  @override
  Stream<RidesEntity?> watchCurrentDriverRide(String driverId) {
    return _remoteDataSource.watchCurrentDriverRide(driverId);
  }

  @override
  Stream<List<RideApplicationEntity>> watchRideApplications(String rideId) {
    return _remoteDataSource.watchRideApplications(rideId);
  }

  @override
  Stream<RideApplicationEntity?> watchPassengerApplication({
    required String rideId,
    required String passengerId,
  }) {
    return _remoteDataSource.watchPassengerApplication(
      rideId: rideId,
      passengerId: passengerId,
    );
  }

  @override
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
  }) {
    return _remoteDataSource.createRide(
      driverId: driverId,
      driverName: driverName,
      driverEmail: driverEmail,
      origin: origin,
      destination: destination,
      departureAt: departureAt,
      estimatedDurationMinutes: estimatedDurationMinutes,
      totalSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      notes: notes,
    );
  }

  @override
  Future<void> applyToRide({
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
  }) {
    return _remoteDataSource.applyToRide(
      rideId: rideId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerEmail: passengerEmail,
    );
  }

  @override
  Future<void> updateRideStatus({
    required String rideId,
    required String status,
  }) {
    return _remoteDataSource.updateRideStatus(rideId: rideId, status: status);
  }
}
