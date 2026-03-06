class DriverActiveRideMock {
  static const Map<String, dynamic> ride = {
    'driverName': 'Carlos Mendez',
    'driverInitials': 'CM',
    'driverRating': '4.8',
    'carModel': 'Toyota Corolla 2020',
    'origin': 'Campus Uniandes - Entrance Gate',
    'destination': 'Centro Comercial Andino',
    'departureTime': '14:30',
    'eta': '15:00',
    'distance': '4.2 km',
    'fare': '\$3,500',
    'seats': 4,
  };

  static const List<Map<String, dynamic>> passengers = [
    {'name': 'Ana Garcia', 'faculty': 'Ingenieria', 'confirmed': true},
    {'name': 'Pedro Lopez', 'faculty': 'Derecho', 'confirmed': true},
    {'name': 'Maria Diaz', 'faculty': 'Medicina', 'confirmed': false},
  ];
}
