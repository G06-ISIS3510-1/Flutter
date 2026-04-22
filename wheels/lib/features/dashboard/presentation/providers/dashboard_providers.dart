import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../payments/domain/entities/payment_record.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../rides/domain/entities/rides_entity.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

final dashboardSummaryProvider = Provider<String>((ref) => 'Dashboard overview');
final dashboardCardCountProvider = StateProvider<int>((ref) => 3);

class DashboardBootstrapState {
  const DashboardBootstrapState({
    this.driverRide,
    this.walletSummary,
    this.passengerRide,
    this.passengerApplication,
    this.paymentRecord,
    this.driverRideError,
    this.walletSummaryError,
    this.passengerRideError,
    this.passengerApplicationError,
    this.paymentRecordError,
  });

  final RidesEntity? driverRide;
  final WalletSummary? walletSummary;
  final RidesEntity? passengerRide;
  final RideApplicationEntity? passengerApplication;
  final PaymentRecord? paymentRecord;
  final Object? driverRideError;
  final Object? walletSummaryError;
  final Object? passengerRideError;
  final Object? passengerApplicationError;
  final Object? paymentRecordError;

  bool get hasAnyError =>
      driverRideError != null ||
      walletSummaryError != null ||
      passengerRideError != null ||
      passengerApplicationError != null ||
      paymentRecordError != null;
}

class _BootstrapResult<T> {
  const _BootstrapResult._({this.data, this.error});
  const _BootstrapResult.data(T? data) : this._(data: data);
  const _BootstrapResult.error(Object error) : this._(error: error);

  final T? data;
  final Object? error;
}

Future<_BootstrapResult<T>> _guard<T>(Future<T> future) async {
  try {
    return _BootstrapResult<T>.data(await future);
  } catch (error) {
    return _BootstrapResult<T>.error(error);
  }
}

final dashboardBootstrapProvider =
    FutureProvider.autoDispose<DashboardBootstrapState>((ref) async {
      final user = ref.watch(authUserProvider);
      final role = ref.watch(currentUserRoleProvider);

      if (user == null) {
        return const DashboardBootstrapState();
      }

      if (role == UserRole.driver) {
        // Driver: currentDriverRide and walletSummary are independent — load concurrently
        final results = await Future.wait<Object?>([
          _guard<RidesEntity?>(ref.watch(currentDriverRideProvider.future)),
          _guard<WalletSummary?>(ref.watch(driverWalletSummaryProvider.future)),
        ]);

        final rideResult = results[0] as _BootstrapResult<RidesEntity?>;
        final walletResult = results[1] as _BootstrapResult<WalletSummary?>;

        return DashboardBootstrapState(
          driverRide: rideResult.data,
          walletSummary: walletResult.data,
          driverRideError: rideResult.error,
          walletSummaryError: walletResult.error,
        );
      }

      // Passenger: ride must resolve before application and payment record can be requested
      final rideResult = await _guard<RidesEntity?>(
        ref.watch(currentPassengerRideProvider.future),
      );

      if (rideResult.error != null || rideResult.data == null) {
        return DashboardBootstrapState(
          passengerRide: rideResult.data,
          passengerRideError: rideResult.error,
        );
      }

      final rideId = rideResult.data!.id;
      final paymentRequest = PaymentRecordRequest(
        rideId: rideId,
        passengerId: user.uid,
      );

      // Application and payment record don't depend on each other — load concurrently
      final results = await Future.wait<Object?>([
        _guard<RideApplicationEntity?>(
          ref.watch(passengerRideApplicationProvider(rideId).future),
        ),
        _guard<PaymentRecord?>(
          ref.watch(paymentRecordStreamProvider(paymentRequest).future),
        ),
      ]);

      final applicationResult =
          results[0] as _BootstrapResult<RideApplicationEntity?>;
      final paymentResult = results[1] as _BootstrapResult<PaymentRecord?>;

      return DashboardBootstrapState(
        passengerRide: rideResult.data,
        passengerApplication: applicationResult.data,
        paymentRecord: paymentResult.data,
        passengerApplicationError: applicationResult.error,
        paymentRecordError: paymentResult.error,
      );
    });
