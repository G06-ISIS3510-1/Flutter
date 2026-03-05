import '../models/ride_listing.dart';

List<RideListing> buildMockRides(DateTime baseDate) {
  final day = DateTime(baseDate.year, baseDate.month, baseDate.day);

  DateTime onDay(int daysOffset, int hour, int minute) {
    return DateTime(day.year, day.month, day.day + daysOffset, hour, minute);
  }

  return <RideListing>[
    RideListing(
      id: 'ride-001',
      driverName: 'Carlos Mendez',
      driverInitials: 'CM',
      rating: 4.8,
      reviewCount: 124,
      origin: 'Main Campus',
      destination: 'Downtown',
      departureDateTime: onDay(0, 14, 30),
      durationMinutes: 30,
      pricePerSeat: 3500,
      seatsLeft: 2,
      onTimeRate: 96,
      verifiedByUniversity: true,
    ),
    RideListing(
      id: 'ride-002',
      driverName: 'Maria Sanchez',
      driverInitials: 'MS',
      rating: 4.9,
      reviewCount: 89,
      origin: 'Engineering Building',
      destination: 'North Residence Hall',
      departureDateTime: onDay(0, 15, 0),
      durationMinutes: 35,
      pricePerSeat: 4000,
      seatsLeft: 2,
      onTimeRate: 98,
      verifiedByUniversity: true,
    ),
    RideListing(
      id: 'ride-003',
      driverName: 'Juan Rivera',
      driverInitials: 'JR',
      rating: 4.6,
      reviewCount: 57,
      origin: 'Student Center',
      destination: 'Downtown',
      departureDateTime: onDay(0, 17, 10),
      durationMinutes: 28,
      pricePerSeat: 3000,
      seatsLeft: 3,
      onTimeRate: 92,
      verifiedByUniversity: false,
    ),
    RideListing(
      id: 'ride-004',
      driverName: 'Ana Torres',
      driverInitials: 'AT',
      rating: 4.7,
      reviewCount: 63,
      origin: 'Main Campus',
      destination: 'North Residence Hall',
      departureDateTime: onDay(0, 18, 20),
      durationMinutes: 22,
      pricePerSeat: 2800,
      seatsLeft: 1,
      onTimeRate: 97,
      verifiedByUniversity: true,
    ),
    RideListing(
      id: 'ride-005',
      driverName: 'Laura Gomez',
      driverInitials: 'LG',
      rating: 4.5,
      reviewCount: 41,
      origin: 'Engineering Building',
      destination: 'Downtown',
      departureDateTime: onDay(1, 8, 0),
      durationMinutes: 40,
      pricePerSeat: 4500,
      seatsLeft: 4,
      onTimeRate: 90,
      verifiedByUniversity: true,
    ),
    RideListing(
      id: 'ride-006',
      driverName: 'David Lopez',
      driverInitials: 'DL',
      rating: 4.9,
      reviewCount: 152,
      origin: 'Main Campus',
      destination: 'Student Center',
      departureDateTime: onDay(1, 9, 15),
      durationMinutes: 18,
      pricePerSeat: 2500,
      seatsLeft: 1,
      onTimeRate: 99,
      verifiedByUniversity: true,
    ),
    RideListing(
      id: 'ride-007',
      driverName: 'Sofia Perez',
      driverInitials: 'SP',
      rating: 4.4,
      reviewCount: 34,
      origin: 'North Residence Hall',
      destination: 'Main Campus',
      departureDateTime: onDay(1, 12, 45),
      durationMinutes: 25,
      pricePerSeat: 3200,
      seatsLeft: 2,
      onTimeRate: 88,
      verifiedByUniversity: false,
    ),
  ];
}

RideListing? findRideById(String rideId, DateTime baseDate) {
  for (final ride in buildMockRides(baseDate)) {
    if (ride.id == rideId) {
      return ride;
    }
  }
  return null;
}
