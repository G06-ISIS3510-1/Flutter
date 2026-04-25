import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../rides/domain/entities/rides_entity.dart';
import '../../../rides/presentation/providers/rides_providers.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/payment_local_datasource.dart';
import '../../data/datasources/payment_firestore_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/models/local_payment_verification_cache_model.dart';
import '../../domain/entities/payment_flow_status.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

const Duration _paymentExpirationWindow = Duration(minutes: 3);

/// UI-facing snapshot of the current checkout session and Firestore payment state.
class PaymentState {
  const PaymentState({
    this.status = PaymentFlowStatus.idle,
    this.checkoutUrl,
    this.rideId,
    this.passengerId,
    this.message,
    this.paymentRecord,
    this.checkoutCreatedAt,
    this.expiresAt,
    this.lastCheckedAt,
    this.hasPendingVerificationCache = false,
    this.pendingVerificationMarkedAt,
  });

  final PaymentFlowStatus status;
  final String? checkoutUrl;
  final String? rideId;
  final String? passengerId;
  final String? message;
  final PaymentRecord? paymentRecord;
  final DateTime? checkoutCreatedAt;
  final DateTime? expiresAt;
  final DateTime? lastCheckedAt;
  final bool hasPendingVerificationCache;
  final DateTime? pendingVerificationMarkedAt;

  PaymentState copyWith({
    PaymentFlowStatus? status,
    String? checkoutUrl,
    bool clearCheckoutUrl = false,
    String? rideId,
    bool clearRideId = false,
    String? passengerId,
    bool clearPassengerId = false,
    String? message,
    bool clearMessage = false,
    PaymentRecord? paymentRecord,
    bool clearPaymentRecord = false,
    DateTime? checkoutCreatedAt,
    bool clearCheckoutCreatedAt = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    DateTime? lastCheckedAt,
    bool clearLastCheckedAt = false,
    bool? hasPendingVerificationCache,
    DateTime? pendingVerificationMarkedAt,
    bool clearPendingVerificationMarkedAt = false,
  }) {
    // Boolean "clear" flags let the notifier explicitly remove nullable values.
    return PaymentState(
      status: status ?? this.status,
      checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
      rideId: clearRideId ? null : (rideId ?? this.rideId),
      passengerId: clearPassengerId ? null : (passengerId ?? this.passengerId),
      message: clearMessage ? null : (message ?? this.message),
      paymentRecord: clearPaymentRecord
          ? null
          : (paymentRecord ?? this.paymentRecord),
      checkoutCreatedAt: clearCheckoutCreatedAt
          ? null
          : (checkoutCreatedAt ?? this.checkoutCreatedAt),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      lastCheckedAt: clearLastCheckedAt
          ? null
          : (lastCheckedAt ?? this.lastCheckedAt),
      hasPendingVerificationCache:
          hasPendingVerificationCache ?? this.hasPendingVerificationCache,
      pendingVerificationMarkedAt: clearPendingVerificationMarkedAt
          ? null
          : (pendingVerificationMarkedAt ?? this.pendingVerificationMarkedAt),
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._ref, this._repository, this._localDataSource)
    : super(const PaymentState()) {
    _initializeDeepLinks();
  }

  final Ref _ref;
  final PaymentRepository _repository;
  final PaymentLocalDataSource _localDataSource;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<PaymentRecord?>? _paymentSubscription;

  void observeRide({required String rideId, required String passengerId}) {
    if (rideId.isEmpty || passengerId.isEmpty) {
      return;
    }

    // Reset transient checkout data when the screen starts observing another ride.
    final hasChangedRide =
        state.rideId != rideId || state.passengerId != passengerId;

    if (hasChangedRide) {
      state = PaymentState(
        status: PaymentFlowStatus.idle,
        rideId: rideId,
        passengerId: passengerId,
        message: 'Ready to pay for this ride with Mercado Pago.',
      );
    }

    bindPaymentStream(rideId: rideId, passengerId: passengerId);
    unawaited(
      _restorePendingVerificationIfNeeded(
        rideId: rideId,
        passengerId: passengerId,
      ),
    );
    unawaited(refreshStatus(allowMissingRecord: true));
  }

  Future<void> startCheckout({
    required String rideId,
    required String title,
    required double unitPrice,
    required int quantity,
    required String payerEmail,
    required String userId,
    required String passengerId,
  }) async {
    // Opening a brand-new checkout always clears stale status from a previous try.
    state = state.copyWith(
      status: PaymentFlowStatus.loading,
      rideId: rideId,
      passengerId: passengerId,
      message: 'Creating Mercado Pago checkout...',
      clearCheckoutUrl: true,
      clearPaymentRecord: true,
      clearCheckoutCreatedAt: true,
      clearExpiresAt: true,
    );

    try {
      final session = await _repository.createCheckoutSession(
        rideId: rideId,
        title: title,
        unitPrice: unitPrice,
        quantity: quantity,
        payerEmail: payerEmail,
        userId: userId,
        passengerId: passengerId,
      );
      final checkoutCreatedAt = DateTime.now();
      final expiresAt = checkoutCreatedAt.add(_paymentExpirationWindow);

      bindPaymentStream(rideId: rideId, passengerId: passengerId);

      state = state.copyWith(
        status: PaymentFlowStatus.checkoutOpened,
        checkoutUrl: session.initPoint,
        rideId: rideId,
        passengerId: passengerId,
        checkoutCreatedAt: checkoutCreatedAt,
        expiresAt: expiresAt,
        message:
            'Mercado Pago checkout is ready. PSE and Bancolombia stay available inside the checkout.',
      );
      unawaited(refreshStatus(allowMissingRecord: true));
    } catch (error) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message: _readableError(
          error,
          fallback: 'We could not start the checkout. Please try again.',
        ),
        clearCheckoutUrl: true,
        clearPaymentRecord: true,
        clearCheckoutCreatedAt: true,
        clearExpiresAt: true,
      );
    }
  }

  Future<void> refreshStatus({bool allowMissingRecord = false}) async {
    final rideId = state.rideId;
    final passengerId = state.passengerId;
    if (rideId == null ||
        rideId.isEmpty ||
        passengerId == null ||
        passengerId.isEmpty) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message:
            'We could not identify the ride payment to validate right now.',
        clearCheckoutUrl: true,
      );
      return;
    }

    try {
      final paymentRecord = await _repository.getPaymentStatus(
        rideId: rideId,
        passengerId: passengerId,
      );
      if (paymentRecord == null) {
        // Firestore writes can lag slightly behind checkout creation.
        _handleMissingPaymentRecord(allowMissingRecord: allowMissingRecord);
        return;
      }
      _applyPaymentRecord(paymentRecord);
    } catch (error) {
      if (state.hasPendingVerificationCache) {
        state = state.copyWith(
          status: PaymentFlowStatus.pending,
          message:
              'We are still reconciling this payment with the backend. The final result will be confirmed when connectivity returns.',
          clearCheckoutUrl: true,
          lastCheckedAt: DateTime.now(),
        );
        return;
      }

      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message: _readableError(
          error,
          fallback:
              'We could not read the latest payment status from Firestore.',
        ),
        clearCheckoutUrl: true,
        lastCheckedAt: DateTime.now(),
      );
    }
  }

  void bindPaymentStream({
    required String rideId,
    required String passengerId,
  }) {
    // The stream is the source of truth once the backend updates Firestore.
    _paymentSubscription?.cancel();
    _paymentSubscription = _repository
        .watchPaymentStatus(rideId: rideId, passengerId: passengerId)
        .listen((paymentRecord) {
          if (paymentRecord == null) {
            return;
          }

          _applyPaymentRecord(paymentRecord);
        });
  }

  void _handleMissingPaymentRecord({required bool allowMissingRecord}) {
    if (allowMissingRecord) {
      // During checkout creation we keep the UX in a waiting state instead of
      // surfacing a false error before Firestore receives the first record.
      final waitingStatus =
          state.checkoutCreatedAt != null ||
              state.status == PaymentFlowStatus.pending ||
              state.status == PaymentFlowStatus.checkoutOpened
          ? state.status == PaymentFlowStatus.checkoutOpened
                ? PaymentFlowStatus.checkoutOpened
                : PaymentFlowStatus.pending
          : PaymentFlowStatus.idle;

      state = state.copyWith(
        status: waitingStatus,
        message: waitingStatus == PaymentFlowStatus.idle
            ? 'Choose a payment method or start checkout when you are ready.'
            : 'Waiting for the backend to write the payment record in Firestore.',
        lastCheckedAt: DateTime.now(),
      );
      return;
    }

    state = state.copyWith(
      status: PaymentFlowStatus.error,
      message: 'Payment status is unavailable right now.',
      clearCheckoutUrl: true,
      lastCheckedAt: DateTime.now(),
    );
  }

  void handleRedirectSuccess() {
    unawaited(
      _markVerificationPending(
        message:
            'Payment submitted. Waiting for the backend to confirm the final result...',
      ),
    );
    unawaited(refreshStatus(allowMissingRecord: true));
  }

  void handleRedirectPending() {
    unawaited(
      _markVerificationPending(
        message:
            'Checkout returned a pending result. Waiting for backend confirmation...',
      ),
    );
    unawaited(refreshStatus(allowMissingRecord: true));
  }

  void handleRedirectFailure() {
    unawaited(
      _markVerificationPending(
        message:
            'Checkout ended without a confirmed result. Verifying the final payment status with the backend...',
      ),
    );
    unawaited(refreshStatus(allowMissingRecord: true));
  }

  void handleCheckoutClosed() {
    if (state.status == PaymentFlowStatus.approved ||
        state.status == PaymentFlowStatus.rejected ||
        state.status == PaymentFlowStatus.expired) {
      return;
    }

    unawaited(
      _markVerificationPending(
        message:
            'Checkout was interrupted or closed. We will verify the real payment state with the backend.',
      ),
    );
    unawaited(refreshStatus(allowMissingRecord: true));
  }

  void handleCheckoutLaunchError(Object error) {
    state = state.copyWith(
      status: PaymentFlowStatus.error,
      message: _readableError(
        error,
        fallback: 'We could not open Mercado Pago checkout.',
      ),
      clearCheckoutUrl: true,
    );
  }

  Future<void> _initializeDeepLinks() async {
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(_handleIncomingUri(uri));
      },
      onError: (Object error) {
        state = state.copyWith(
          status: PaymentFlowStatus.error,
          message: _readableError(
            error,
            fallback: 'Deep link handling failed.',
          ),
        );
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingUri(initialUri);
      }
    } on PlatformException catch (error) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message:
            'Deep link initialization failed: ${error.message ?? error.code}',
      );
    } on FormatException {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message: 'The app received an invalid payment return URL.',
      );
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    if (uri.scheme != 'wheels' || uri.host != 'payment') {
      return;
    }

    // Deep links carry the redirect outcome from Mercado Pago back into the app.
    final rideIdFromLink = uri.queryParameters['rideId'];
    if (rideIdFromLink != null && rideIdFromLink.isNotEmpty) {
      state = state.copyWith(rideId: rideIdFromLink);
      final passengerId = state.passengerId;
      if (passengerId != null && passengerId.isNotEmpty) {
        bindPaymentStream(rideId: rideIdFromLink, passengerId: passengerId);
      }
    }

    final path = uri.path.toLowerCase();
    if (path.contains('success') || path.contains('sucess')) {
      handleRedirectSuccess();
      return;
    }
    if (path.contains('pending')) {
      handleRedirectPending();
      return;
    }
    if (path.contains('failure') || path.contains('failture')) {
      handleRedirectFailure();
    }
  }

  void _applyPaymentRecord(PaymentRecord paymentRecord) {
    // Backend status wins over local assumptions whenever a record is available.
    final effectiveExpiresAt = _effectiveExpiresAt(paymentRecord);
    final flowStatus = _mapStatus(paymentRecord.effectiveStatus);

    unawaited(_clearPendingVerificationCache());

    state = state.copyWith(
      rideId: paymentRecord.rideId,
      passengerId: paymentRecord.passengerId,
      paymentRecord: paymentRecord,
      status: flowStatus,
      message: _statusMessage(
        paymentRecord.effectiveStatus,
        expiresAt: effectiveExpiresAt,
        statusDetail: paymentRecord.statusDetail,
      ),
      checkoutCreatedAt: paymentRecord.createdAt ?? state.checkoutCreatedAt,
      expiresAt: effectiveExpiresAt,
      lastCheckedAt: DateTime.now(),
      clearCheckoutUrl: flowStatus != PaymentFlowStatus.checkoutOpened,
      hasPendingVerificationCache: false,
      clearPendingVerificationMarkedAt: true,
    );
  }

  Future<void> _restorePendingVerificationIfNeeded({
    required String rideId,
    required String passengerId,
  }) async {
    final cache = await _localDataSource.loadPendingVerification(
      rideId: rideId,
      passengerId: passengerId,
    );
    if (cache == null) {
      return;
    }

    state = state.copyWith(
      status: PaymentFlowStatus.pending,
      rideId: rideId,
      passengerId: passengerId,
      message: cache.message,
      checkoutCreatedAt: cache.checkoutCreatedAt,
      expiresAt: cache.expiresAt,
      hasPendingVerificationCache: true,
      pendingVerificationMarkedAt: cache.markedAt,
      clearCheckoutUrl: true,
    );
  }

  Future<void> _markVerificationPending({
    required String message,
  }) async {
    final rideId = state.rideId;
    final passengerId = state.passengerId;
    if (rideId == null ||
        rideId.isEmpty ||
        passengerId == null ||
        passengerId.isEmpty) {
      return;
    }

    final cache = LocalPaymentVerificationCacheModel.create(
      rideId: rideId,
      passengerId: passengerId,
      message: message,
      checkoutCreatedAt: state.checkoutCreatedAt,
      expiresAt: state.expiresAt,
    );
    await _localDataSource.savePendingVerification(cache);

    state = state.copyWith(
      status: PaymentFlowStatus.pending,
      message: message,
      clearCheckoutUrl: true,
      hasPendingVerificationCache: true,
      pendingVerificationMarkedAt: cache.markedAt,
    );
  }

  Future<void> _clearPendingVerificationCache() async {
    final rideId = state.rideId;
    final passengerId = state.passengerId;
    if (rideId == null ||
        rideId.isEmpty ||
        passengerId == null ||
        passengerId.isEmpty) {
      return;
    }

    await _localDataSource.clearPendingVerification(
      rideId: rideId,
      passengerId: passengerId,
    );
  }

  DateTime? _effectiveExpiresAt(PaymentRecord? paymentRecord) {
    return paymentRecord?.expiresAt ??
        state.expiresAt ??
        paymentRecord?.createdAt?.add(_paymentExpirationWindow) ??
        state.checkoutCreatedAt?.add(_paymentExpirationWindow);
  }

  PaymentFlowStatus _mapStatus(String? rawStatus) {
    // The backend may emit a few spelling or provider variants for the same idea.
    final normalizedStatus = rawStatus?.trim().toLowerCase();
    switch (normalizedStatus) {
      case 'approved':
      case 'success':
      case 'sucess':
      case 'accredited':
        return PaymentFlowStatus.approved;
      case 'created':
      case 'not_started':
      case 'initialized':
        if (state.checkoutCreatedAt == null) {
          return PaymentFlowStatus.idle;
        }
        return PaymentFlowStatus.pending;
      case 'pending':
      case 'in_process':
      case 'authorized':
      case 'in_mediation':
        return PaymentFlowStatus.pending;
      case 'expired':
      case 'timeout':
      case 'timed_out':
      case 'payment_timeout':
        return PaymentFlowStatus.expired;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'failure':
      case 'failed':
      case 'refunded':
      case 'charged_back':
        return PaymentFlowStatus.rejected;
      case null:
      case '':
        return PaymentFlowStatus.error;
      default:
        return PaymentFlowStatus.error;
    }
  }

  String _statusMessage(
    String? rawStatus, {
    DateTime? expiresAt,
    String? statusDetail,
  }) {
    switch (_mapStatus(rawStatus)) {
      case PaymentFlowStatus.idle:
        return 'Choose a payment method or start checkout when you are ready.';
      case PaymentFlowStatus.approved:
        return 'Payment approved. Your ride payment is confirmed.';
      case PaymentFlowStatus.pending:
        if (rawStatus?.trim().toLowerCase() == 'created') {
          return 'Checkout created. Complete it before the 3-minute expiration window ends.';
        }
        return 'Payment is being verified by Mercado Pago. PSE and Bancolombia confirmations can take a moment.';
      case PaymentFlowStatus.rejected:
        return statusDetail == 'payment_not_completed_before_ride_finished'
            ? 'Payment was not completed before the ride finished.'
            : 'Payment failed or was cancelled. You can try again.';
      case PaymentFlowStatus.expired:
        return 'The checkout expired after 3 minutes without approval.';
      case PaymentFlowStatus.error:
        return 'Payment status is unavailable right now.';
      case PaymentFlowStatus.loading:
      case PaymentFlowStatus.checkoutOpened:
        return 'Waiting for payment confirmation...';
    }
  }

  String _readableError(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _paymentSubscription?.cancel();
    super.dispose();
  }
}

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((
  ref,
) {
  return PaymentRemoteDataSource();
});

final paymentFirestoreDataSourceProvider = Provider<PaymentFirestoreDataSource>(
  (ref) {
    return PaymentFirestoreDataSource();
  },
);

final paymentLocalDataSourceProvider = Provider<PaymentLocalDataSource>((ref) {
  return PaymentLocalDataSource();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
    firestoreDataSource: ref.watch(paymentFirestoreDataSourceProvider),
  );
});

class RidePaymentBootstrapRequest {
  const RidePaymentBootstrapRequest({
    required this.rideId,
    required this.passengerId,
  });

  final String rideId;
  final String? passengerId;

  @override
  bool operator ==(Object other) {
    return other is RidePaymentBootstrapRequest &&
        other.rideId == rideId &&
        other.passengerId == passengerId;
  }

  @override
  int get hashCode => Object.hash(rideId, passengerId);
}

class RidePaymentBootstrapState {
  const RidePaymentBootstrapState({
    this.ride,
    this.passengerApplication,
    this.paymentRecord,
    this.rideError,
    this.passengerApplicationError,
    this.paymentRecordError,
  });

  final RidesEntity? ride;
  final RideApplicationEntity? passengerApplication;
  final PaymentRecord? paymentRecord;
  final Object? rideError;
  final Object? passengerApplicationError;
  final Object? paymentRecordError;

  bool get hasAnyError =>
      rideError != null ||
      passengerApplicationError != null ||
      paymentRecordError != null;
}

class _BootstrapLoadResult<T> {
  const _BootstrapLoadResult._({this.data, this.error});

  const _BootstrapLoadResult.data(T? data) : this._(data: data);

  const _BootstrapLoadResult.error(Object error) : this._(error: error);

  final T? data;
  final Object? error;
}

Future<_BootstrapLoadResult<T>> _guardBootstrapFuture<T>(
  Future<T> future,
) async {
  try {
    return _BootstrapLoadResult<T>.data(await future);
  } catch (error) {
    return _BootstrapLoadResult<T>.error(error);
  }
}

class PaymentRecordRequest {
  const PaymentRecordRequest({required this.rideId, required this.passengerId});

  final String rideId;
  final String passengerId;

  @override
  bool operator ==(Object other) {
    return other is PaymentRecordRequest &&
        other.rideId == rideId &&
        other.passengerId == passengerId;
  }

  @override
  int get hashCode => Object.hash(rideId, passengerId);
}

final paymentRecordStreamProvider =
    StreamProvider.family<PaymentRecord?, PaymentRecordRequest>((ref, request) {
      return ref
          .watch(paymentRepositoryProvider)
          .watchPaymentStatus(
            rideId: request.rideId,
            passengerId: request.passengerId,
          );
    });

final ridePaymentBootstrapProvider = FutureProvider.autoDispose
    .family<RidePaymentBootstrapState, RidePaymentBootstrapRequest>((
      ref,
      request,
    ) async {
      if (request.passengerId == null || request.passengerId!.isEmpty) {
        final rideResult = await _guardBootstrapFuture<RidesEntity?>(
          ref.watch(rideProvider(request.rideId).future),
        );

        return RidePaymentBootstrapState(
          ride: rideResult.data,
          rideError: rideResult.error,
        );
      }

      final paymentRequest = PaymentRecordRequest(
        rideId: request.rideId,
        passengerId: request.passengerId!,
      );

      final results = await Future.wait<Object?>([
        _guardBootstrapFuture<RidesEntity?>(
          ref.watch(rideProvider(request.rideId).future),
        ),
        _guardBootstrapFuture<RideApplicationEntity?>(
          ref.watch(passengerRideApplicationProvider(request.rideId).future),
        ),
        _guardBootstrapFuture<PaymentRecord?>(
          ref.watch(paymentRecordStreamProvider(paymentRequest).future),
        ),
      ]);

      final rideResult = results[0] as _BootstrapLoadResult<RidesEntity?>;
      final applicationResult =
          results[1] as _BootstrapLoadResult<RideApplicationEntity?>;
      final paymentResult = results[2] as _BootstrapLoadResult<PaymentRecord?>;

      return RidePaymentBootstrapState(
        ride: rideResult.data,
        passengerApplication: applicationResult.data,
        paymentRecord: paymentResult.data,
        rideError: rideResult.error,
        passengerApplicationError: applicationResult.error,
        paymentRecordError: paymentResult.error,
      );
    });

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier(
    ref,
    ref.watch(paymentRepositoryProvider),
    ref.watch(paymentLocalDataSourceProvider),
  );
});
