import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/payment_firestore_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_flow_status.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentState {
  const PaymentState({
    this.status = PaymentFlowStatus.idle,
    this.checkoutUrl,
    this.rideId,
    this.passengerId,
    this.message,
    this.paymentRecord,
  });

  final PaymentFlowStatus status;
  final String? checkoutUrl;
  final String? rideId;
  final String? passengerId;
  final String? message;
  final PaymentRecord? paymentRecord;

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
  }) {
    return PaymentState(
      status: status ?? this.status,
      checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
      rideId: clearRideId ? null : (rideId ?? this.rideId),
      passengerId: clearPassengerId ? null : (passengerId ?? this.passengerId),
      message: clearMessage ? null : (message ?? this.message),
      paymentRecord: clearPaymentRecord
          ? null
          : (paymentRecord ?? this.paymentRecord),
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._repository) : super(const PaymentState()) {
    _initializeDeepLinks();
  }

  final PaymentRepository _repository;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<PaymentRecord?>? _paymentSubscription;

  void observeRide({required String rideId, required String passengerId}) {
    if (rideId.isEmpty || passengerId.isEmpty) {
      return;
    }

    if (state.rideId != rideId || state.passengerId != passengerId) {
      state = PaymentState(
        status: PaymentFlowStatus.idle,
        rideId: rideId,
        passengerId: passengerId,
        message: 'Ready to pay for this ride.',
      );
    }

    bindPaymentStream(rideId: rideId, passengerId: passengerId);
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
    state = state.copyWith(
      status: PaymentFlowStatus.loading,
      rideId: rideId,
      passengerId: passengerId,
      message: 'Creating Mercado Pago checkout...',
      clearCheckoutUrl: true,
      clearPaymentRecord: true,
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
      final checkoutUrl = session.initPoint;

      bindPaymentStream(rideId: rideId, passengerId: passengerId);

      state = state.copyWith(
        status: PaymentFlowStatus.checkoutOpened,
        checkoutUrl: checkoutUrl,
        rideId: rideId,
        message: 'Checkout opened. Finish the payment inside Wheels.',
      );
    } catch (error) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message: _readableError(
          error,
          fallback: 'We could not start the checkout. Please try again.',
        ),
        clearCheckoutUrl: true,
        clearPaymentRecord: true,
      );
    }
  }

  Future<void> refreshStatus() async {
    final rideId = state.rideId;
    final passengerId = state.passengerId;
    if (rideId == null ||
        rideId.isEmpty ||
        passengerId == null ||
        passengerId.isEmpty) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message:
            'We could not identify the passenger payment to validate right now.',
        clearCheckoutUrl: true,
      );
      return;
    }

    try {
      final paymentRecord = await _repository.getPaymentStatus(
        rideId: rideId,
        passengerId: passengerId,
      );
      state = state.copyWith(
        status: _mapStatus(paymentRecord.status),
        paymentRecord: paymentRecord,
        message: _statusMessage(paymentRecord.status),
        clearCheckoutUrl: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: PaymentFlowStatus.error,
        message: _readableError(
          error,
          fallback: 'We could not refresh the payment status.',
        ),
        clearCheckoutUrl: true,
      );
    }
  }

  void bindPaymentStream({
    required String rideId,
    required String passengerId,
  }) {
    _paymentSubscription?.cancel();
    _paymentSubscription = _repository
        .watchPaymentStatus(rideId: rideId, passengerId: passengerId)
        .listen(
          (paymentRecord) {
            if (paymentRecord == null) {
              return;
            }

            state = state.copyWith(
              rideId: rideId,
              passengerId: passengerId,
              paymentRecord: paymentRecord,
              status: _mapStatus(paymentRecord.status),
              message: _statusMessage(paymentRecord.status),
              clearCheckoutUrl:
                  state.status != PaymentFlowStatus.checkoutOpened,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              status: PaymentFlowStatus.error,
              message: _readableError(
                error,
                fallback: 'We lost the payment observer connection.',
              ),
            );
          },
        );
  }

  void handleRedirectSuccess() {
    state = state.copyWith(
      status: PaymentFlowStatus.pending,
      message: 'Payment submitted. Verifying with backend...',
      clearCheckoutUrl: true,
    );
    unawaited(refreshStatus());
  }

  void handleRedirectPending() {
    state = state.copyWith(
      status: PaymentFlowStatus.pending,
      message: 'Payment pending. Waiting for backend confirmation...',
      clearCheckoutUrl: true,
    );
    unawaited(refreshStatus());
  }

  void handleRedirectFailure() {
    state = state.copyWith(
      status: PaymentFlowStatus.rejected,
      message: 'Payment failed or was cancelled.',
      clearCheckoutUrl: true,
    );
    unawaited(refreshStatus());
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

  PaymentFlowStatus _mapStatus(String? rawStatus) {
    switch (rawStatus?.trim().toLowerCase()) {
      case 'created':
      case 'not_started':
      case 'initialized':
        return PaymentFlowStatus.idle;
      case 'approved':
      case 'success':
      case 'sucess':
        return PaymentFlowStatus.approved;
      case 'pending':
      case 'in_process':
        return PaymentFlowStatus.pending;
      case 'rejected':
      case 'cancelled':
      case 'failure':
      case 'failture':
        return PaymentFlowStatus.rejected;
      default:
        return PaymentFlowStatus.error;
    }
  }

  String _statusMessage(String? rawStatus) {
    switch (_mapStatus(rawStatus)) {
      case PaymentFlowStatus.idle:
        return 'Choose a payment method or start checkout when you are ready.';
      case PaymentFlowStatus.approved:
        return 'Payment approved and confirmed in Firestore.';
      case PaymentFlowStatus.pending:
        return 'Payment is being verified. Waiting for backend confirmation.';
      case PaymentFlowStatus.rejected:
        return 'Payment failed or was cancelled.';
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

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
    firestoreDataSource: ref.watch(paymentFirestoreDataSourceProvider),
  );
});

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

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier(ref.watch(paymentRepositoryProvider));
});
