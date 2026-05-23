class RideHistoryEntity {
  const RideHistoryEntity({
    required this.rideId,
    required this.userId,
    required this.userRole,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.pricePerSeat,
    required this.status,
    required this.totalSeats,
    required this.savedAt,
  });

  final String rideId;
  final String userId;
  final String userRole;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departureAt;
  final int pricePerSeat;
  final String status;
  final int totalSeats;
  final DateTime savedAt;

  bool get isDriver => userRole == 'driver';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isInProgress => status == 'in_progress';
  bool get isOpen => status == 'open';
}
