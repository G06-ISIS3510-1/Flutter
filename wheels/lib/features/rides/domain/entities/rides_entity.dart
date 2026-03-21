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
    required this.appliedAt,
  });

  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String passengerEmail;
  final String status;
  final DateTime appliedAt;
}

class RideFailure implements Exception {
  const RideFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
