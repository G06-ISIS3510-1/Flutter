import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../payments/domain/entities/payment_record.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../rides/domain/entities/rides_entity.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

final dashboardSummaryProvider = Provider<String>((ref) => 'Dashboard overview');
final dashboardCardCountProvider = StateProvider<int>((ref) => 3);

class DashboardLoadState {
  const DashboardLoadState({
    required this.role,
    required this.user,
    this.currentDriverRide,
    this.currentPassengerRide,
    this.passengerApplication,
    this.paymentRecord,
    this.walletSummary,
    this.driverRideError,
    this.passengerRideError,
    this.passengerApplicationError,
    this.paymentRecordError,
    this.walletSummaryError,
  });

  final UserRole role;
  final AuthEntity? user;
  final RidesEntity? currentDriverRide;
  final RidesEntity? currentPassengerRide;
  final RideApplicationEntity? passengerApplication;
  final PaymentRecord? paymentRecord;
  final WalletSummary? walletSummary;
  final Object? driverRideError;
  final Object? passengerRideError;
  final Object? passengerApplicationError;
  final Object? paymentRecordError;
  final Object? walletSummaryError;

  bool get hasAnyError =>
      driverRideError != null ||
      passengerRideError != null ||
      passengerApplicationError != null ||
      paymentRecordError != null ||
      walletSummaryError != null;

  RidesEntity? get primaryRide => role == UserRole.driver
      ? currentDriverRide
      : currentPassengerRide;

  String get summary {
    final ride = primaryRide;
    if (ride == null) {
      return role == UserRole.driver
          ? 'Dashboard overview. You do not have an active ride yet.'
          : 'Dashboard overview. Search rides and apply to one to see live trip updates here.';
    }

    return role == UserRole.driver
        ? 'Dashboard overview. Your ride from ${ride.origin} to ${ride.destination} is available in the live summary.'
        : 'Dashboard overview. Your ride to ${ride.destination} is loaded in the live summary.';
  }
}

class _LoadResult<T> {
  const _LoadResult._({this.data, this.error});

  const _LoadResult.data(T? data) : this._(data: data);
  const _LoadResult.error(Object error) : this._(error: error);

  final T? data;
  final Object? error;
}

Future<_LoadResult<T>> _guardFuture<T>(Future<T> future) async {
  try {
    return _LoadResult<T>.data(await future);
  } catch (error) {
    return _LoadResult<T>.error(error);
  }
}

final dashboardConcurrentDataProvider =
    FutureProvider<DashboardLoadState>((ref) async {
      final role = ref.watch(currentUserRoleProvider);
      final user = ref.watch(authUserProvider);

      if (role == UserRole.driver) {
        final results = await Future.wait<Object?>([
          _guardFuture<RidesEntity?>(
            ref.watch(currentDriverRideProvider.future),
          ),
          _guardFuture<WalletSummary?>(
            ref.watch(driverWalletSummaryProvider.future),
          ),
        ]);

        final rideResult = results[0] as _LoadResult<RidesEntity?>;
        final walletResult = results[1] as _LoadResult<WalletSummary?>;

        return DashboardLoadState(
          role: role,
          user: user,
          currentDriverRide: rideResult.data,
          walletSummary: walletResult.data,
          driverRideError: rideResult.error,
          walletSummaryError: walletResult.error,
        );
      }

      final passengerRideResult = await _guardFuture<RidesEntity?>(
        ref.watch(currentPassengerRideProvider.future),
      );

      final passengerRide = passengerRideResult.data;
      if (passengerRide == null || user == null) {
        return DashboardLoadState(
          role: role,
          user: user,
          currentPassengerRide: passengerRide,
          passengerRideError: passengerRideResult.error,
        );
      }

      final paymentRequest = PaymentRecordRequest(
        rideId: passengerRide.id,
        passengerId: user.uid,
      );

      final dependentResults = await Future.wait<Object?>([
        _guardFuture<RideApplicationEntity?>(
          ref.watch(passengerRideApplicationProvider(passengerRide.id).future),
        ),
        _guardFuture<PaymentRecord?>(
          ref.watch(paymentRecordStreamProvider(paymentRequest).future),
        ),
      ]);

      final applicationResult =
          dependentResults[0] as _LoadResult<RideApplicationEntity?>;
      final paymentResult = dependentResults[1] as _LoadResult<PaymentRecord?>;

      return DashboardLoadState(
        role: role,
        user: user,
        currentPassengerRide: passengerRide,
        passengerApplication: applicationResult.data,
        paymentRecord: paymentResult.data,
        passengerRideError: passengerRideResult.error,
        passengerApplicationError: applicationResult.error,
        paymentRecordError: paymentResult.error,
      );
    });
