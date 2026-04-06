class RidesEntity {
  const RidesEntity({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverEmail,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.estimatedDurationMinutes,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.paymentOption,
    required this.status,
    required this.notes,
    required this.passengerIds,
    required this.createdAt,
    required this.updatedAt,
    this.driverRating = 5,
    this.reviewCount = 0,
    this.onTimeRate = 100,
    this.verifiedByUniversity = true,
  });

  final String id;
  final String driverId;
  final String driverName;
  final String driverEmail;
  final String origin;
  final String destination;
  final DateTime departureAt;
  final int estimatedDurationMinutes;
  final int totalSeats;
  final int availableSeats;
  final int pricePerSeat;
  final RidePaymentOption paymentOption;
  final String status;
  final String notes;
  final List<String> passengerIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double driverRating;
  final int reviewCount;
  final int onTimeRate;
  final bool verifiedByUniversity;

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get acceptsCardPayments => paymentOption == RidePaymentOption.card;
  bool get acceptsManualTransfer => true;
  bool get isManualTransferOnly =>
      paymentOption == RidePaymentOption.bankTransfer;
  bool get hasAvailableSeats => availableSeats > 0;
  int get bookedSeats => totalSeats - availableSeats;

  String get driverInitials {
    final parts = driverName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || driverName.trim().isEmpty) {
      return 'WD';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class RideApplicationEntity {
  const RideApplicationEntity({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerEmail,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.isPaymentLocked,
    required this.appliedAt,
    this.paymentStatusSource,
    this.paymentUpdatedAt,
  });

  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String passengerEmail;
  final String status;
  final RidePassengerPaymentStatus paymentStatus;
  final RidePassengerPaymentMethod paymentMethod;
  final bool isPaymentLocked;
  final DateTime appliedAt;
  final String? paymentStatusSource;
  final DateTime? paymentUpdatedAt;

  bool get requiresPaymentMethodSelection =>
      paymentMethod == RidePassengerPaymentMethod.pendingSelection;
  bool get usesCardPayment => paymentMethod == RidePassengerPaymentMethod.card;
  bool get usesManualTransfer =>
      paymentMethod == RidePassengerPaymentMethod.bankTransfer;
}

enum RidePaymentOption { card, bankTransfer }

extension RidePaymentOptionX on RidePaymentOption {
  String get storageValue => switch (this) {
    RidePaymentOption.card => 'card',
    RidePaymentOption.bankTransfer => 'bank_transfer',
  };

  String get label => switch (this) {
    RidePaymentOption.card => 'Card or direct transfer',
    RidePaymentOption.bankTransfer => 'Direct bank transfer only',
  };
}

RidePaymentOption ridePaymentOptionFromStorage(String? rawValue) {
  switch (rawValue?.trim().toLowerCase()) {
    case 'bank_transfer':
    case 'banktransfer':
      return RidePaymentOption.bankTransfer;
    case 'card':
    default:
      return RidePaymentOption.card;
  }
}

enum RidePassengerPaymentStatus { pending, paid, unpaid }

extension RidePassengerPaymentStatusX on RidePassengerPaymentStatus {
  String get storageValue => switch (this) {
    RidePassengerPaymentStatus.pending => 'pending',
    RidePassengerPaymentStatus.paid => 'paid',
    RidePassengerPaymentStatus.unpaid => 'unpaid',
  };

  String get label => switch (this) {
    RidePassengerPaymentStatus.pending => 'Pending',
    RidePassengerPaymentStatus.paid => 'Paid',
    RidePassengerPaymentStatus.unpaid => 'Unpaid',
  };
}

enum RidePassengerPaymentMethod { pendingSelection, card, bankTransfer }

extension RidePassengerPaymentMethodX on RidePassengerPaymentMethod {
  String get storageValue => switch (this) {
    RidePassengerPaymentMethod.pendingSelection => 'pending_selection',
    RidePassengerPaymentMethod.card => 'card',
    RidePassengerPaymentMethod.bankTransfer => 'bank_transfer',
  };

  String get label => switch (this) {
    RidePassengerPaymentMethod.pendingSelection =>
      'Payment method not selected',
    RidePassengerPaymentMethod.card => 'Card payment',
    RidePassengerPaymentMethod.bankTransfer => 'Direct bank transfer',
  };
}

RidePassengerPaymentMethod ridePassengerPaymentMethodFromStorage(
  String? rawValue,
) {
  switch (rawValue?.trim().toLowerCase()) {
    case 'card':
      return RidePassengerPaymentMethod.card;
    case 'bank_transfer':
    case 'banktransfer':
      return RidePassengerPaymentMethod.bankTransfer;
    case 'pending_selection':
    case 'pendingselection':
    default:
      return RidePassengerPaymentMethod.pendingSelection;
  }
}

RidePassengerPaymentStatus ridePassengerPaymentStatusFromStorage(
  String? rawValue,
) {
  switch (rawValue?.trim().toLowerCase()) {
    case 'paid':
      return RidePassengerPaymentStatus.paid;
    case 'unpaid':
      return RidePassengerPaymentStatus.unpaid;
    case 'pending':
    default:
      return RidePassengerPaymentStatus.pending;
  }
}

class RideFailure implements Exception {
  const RideFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
