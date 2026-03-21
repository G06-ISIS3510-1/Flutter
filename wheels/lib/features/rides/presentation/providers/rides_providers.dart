import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/rides_remote_datasource.dart';
import '../../data/repositories/rides_repository_impl.dart';
import '../../domain/entities/rides_entity.dart';
import '../../domain/repositories/rides_repository.dart';

final ridesRemoteDataSourceProvider = Provider<RidesRemoteDataSource>((ref) {
  return RidesRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final ridesRepositoryProvider = Provider<RidesRepository>((ref) {
  return RidesRepositoryImpl(
    remoteDataSource: ref.watch(ridesRemoteDataSourceProvider),
  );
});

final availableRidesProvider = StreamProvider<List<RidesEntity>>((ref) {
  return ref.watch(ridesRepositoryProvider).watchAvailableRides();
});

final rideProvider = StreamProvider.family<RidesEntity?, String>((ref, rideId) {
  return ref.watch(ridesRepositoryProvider).watchRide(rideId);
});

final currentDriverRideProvider = StreamProvider<RidesEntity?>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return Stream<RidesEntity?>.value(null);
  }

  return ref.watch(ridesRepositoryProvider).watchCurrentDriverRide(user.uid);
});

final rideApplicationsProvider =
    StreamProvider.family<List<RideApplicationEntity>, String>((ref, rideId) {
      return ref.watch(ridesRepositoryProvider).watchRideApplications(rideId);
    });

final passengerRideApplicationProvider =
    StreamProvider.family<RideApplicationEntity?, String>((ref, rideId) {
      final user = ref.watch(authUserProvider);
      if (user == null) {
        return Stream<RideApplicationEntity?>.value(null);
      }

      return ref.watch(ridesRepositoryProvider).watchPassengerApplication(
        rideId: rideId,
        passengerId: user.uid,
      );
    });

final createRideControllerProvider =
    StateNotifierProvider<CreateRideController, AsyncValue<String?>>((ref) {
      return CreateRideController(ref.watch(ridesRepositoryProvider));
    });

final rideApplicationControllerProvider =
    StateNotifierProvider<RideApplicationController, AsyncValue<void>>((ref) {
      return RideApplicationController(ref.watch(ridesRepositoryProvider));
    });

final rideStatusControllerProvider =
    StateNotifierProvider<RideStatusController, AsyncValue<void>>((ref) {
      return RideStatusController(ref.watch(ridesRepositoryProvider));
    });

class CreateRideController extends StateNotifier<AsyncValue<String?>> {
  CreateRideController(this._repository) : super(const AsyncValue.data(null));

  final RidesRepository _repository;

  Future<String?> createRide({
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
  }) async {
    state = const AsyncValue.loading();
    try {
      final ride = await _repository.createRide(
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
      state = AsyncValue.data(ride.id);
      return ride.id;
    } catch (error, stackTrace) {
      state = AsyncValue<String?>.error(error, stackTrace);
      return null;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

class RideApplicationController extends StateNotifier<AsyncValue<void>> {
  RideApplicationController(this._repository)
    : super(const AsyncValue.data(null));

  final RidesRepository _repository;

  Future<void> applyToRide({
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.applyToRide(
        rideId: rideId,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerEmail: passengerEmail,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

class RideStatusController extends StateNotifier<AsyncValue<void>> {
  RideStatusController(this._repository) : super(const AsyncValue.data(null));

  final RidesRepository _repository;

  Future<void> updateRideStatus({
    required String rideId,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRideStatus(rideId: rideId, status: status);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
