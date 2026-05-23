import '../../domain/entities/rides_entity.dart';

class LocalRideDetailsCacheModel {
  const LocalRideDetailsCacheModel({
    required this.version,
    required this.rideId,
    required this.savedAt,
    required this.ride,
  });

  static const int currentVersion = 1;

  final int version;
  final String rideId;
  final DateTime savedAt;
  final LocalRideDetailsModel ride;

  factory LocalRideDetailsCacheModel.create({required RidesEntity ride}) {
    return LocalRideDetailsCacheModel(
      version: currentVersion,
      rideId: ride.id,
      savedAt: DateTime.now().toUtc(),
      ride: LocalRideDetailsModel.fromEntity(ride),
    );
  }

  factory LocalRideDetailsCacheModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported cache version: $version');
    }

    final rawRide = json['ride'];
    if (rawRide is! Map) {
      throw const FormatException('Invalid ride payload.');
    }

    final ride = LocalRideDetailsModel.fromJson(
      Map<String, dynamic>.from(rawRide),
    );
    final rideId = _readRequiredString(json['rideId'], 'rideId');
    if (ride.id != rideId) {
      throw const FormatException('Stored ride cache is inconsistent.');
    }

    return LocalRideDetailsCacheModel(
      version: version,
      rideId: rideId,
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      ride: ride,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'rideId': rideId,
      'savedAt': savedAt.toIso8601String(),
      'ride': ride.toJson(),
    };
  }

  bool matchesRide(String currentRideId) {
    return rideId == currentRideId && ride.id == currentRideId;
  }

  bool isExpired({Duration maxAge = const Duration(hours: 6)}) {
    final now = DateTime.now().toUtc();
    if (savedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return true;
    }
    return now.difference(savedAt.toUtc()) > maxAge;
  }

  RidesEntity toEntity() => ride.toEntity();
}

class LocalRideDetailsModel {
  const LocalRideDetailsModel({
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
    required this.driverRating,
    required this.reviewCount,
    required this.onTimeRate,
    required this.verifiedByUniversity,
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

  factory LocalRideDetailsModel.fromEntity(RidesEntity entity) {
    return LocalRideDetailsModel(
      id: entity.id,
      driverId: entity.driverId,
      driverName: entity.driverName,
      driverEmail: entity.driverEmail,
      origin: entity.origin,
      destination: entity.destination,
      departureAt: entity.departureAt,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      totalSeats: entity.totalSeats,
      availableSeats: entity.availableSeats,
      pricePerSeat: entity.pricePerSeat,
      paymentOption: entity.paymentOption,
      status: entity.status,
      notes: entity.notes,
      passengerIds: List<String>.from(entity.passengerIds),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      driverRating: entity.driverRating,
      reviewCount: entity.reviewCount,
      onTimeRate: entity.onTimeRate,
      verifiedByUniversity: entity.verifiedByUniversity,
    );
  }

  factory LocalRideDetailsModel.fromJson(Map<String, dynamic> json) {
    return LocalRideDetailsModel(
      id: _readRequiredString(json['id'], 'id'),
      driverId: _readRequiredString(json['driverId'], 'driverId'),
      driverName: _readRequiredString(json['driverName'], 'driverName'),
      driverEmail: _readRequiredString(json['driverEmail'], 'driverEmail'),
      origin: _readRequiredString(json['origin'], 'origin'),
      destination: _readRequiredString(json['destination'], 'destination'),
      departureAt: _parseRequiredDateTime(json['departureAt'], 'departureAt'),
      estimatedDurationMinutes: _readRequiredInt(
        json['estimatedDurationMinutes'],
        'estimatedDurationMinutes',
      ),
      totalSeats: _readRequiredInt(json['totalSeats'], 'totalSeats'),
      availableSeats: _readRequiredInt(json['availableSeats'], 'availableSeats'),
      pricePerSeat: _readRequiredInt(json['pricePerSeat'], 'pricePerSeat'),
      paymentOption: ridePaymentOptionFromStorage(
        _readRequiredString(json['paymentOption'], 'paymentOption'),
      ),
      status: _readRequiredString(json['status'], 'status'),
      notes: _readRequiredString(json['notes'], 'notes'),
      passengerIds: _readRequiredStringList(json['passengerIds'], 'passengerIds'),
      createdAt: _parseRequiredDateTime(json['createdAt'], 'createdAt'),
      updatedAt: _parseRequiredDateTime(json['updatedAt'], 'updatedAt'),
      driverRating: _readRequiredDouble(json['driverRating'], 'driverRating'),
      reviewCount: _readRequiredInt(json['reviewCount'], 'reviewCount'),
      onTimeRate: _readRequiredInt(json['onTimeRate'], 'onTimeRate'),
      verifiedByUniversity: _readRequiredBool(
        json['verifiedByUniversity'],
        'verifiedByUniversity',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'origin': origin,
      'destination': destination,
      'departureAt': departureAt.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'paymentOption': paymentOption.storageValue,
      'status': status,
      'notes': notes,
      'passengerIds': passengerIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'driverRating': driverRating,
      'reviewCount': reviewCount,
      'onTimeRate': onTimeRate,
      'verifiedByUniversity': verifiedByUniversity,
    };
  }

  RidesEntity toEntity() {
    return RidesEntity(
      id: id,
      driverId: driverId,
      driverName: driverName,
      driverEmail: driverEmail,
      origin: origin,
      destination: destination,
      departureAt: departureAt,
      estimatedDurationMinutes: estimatedDurationMinutes,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      pricePerSeat: pricePerSeat,
      paymentOption: paymentOption,
      status: status,
      notes: notes,
      passengerIds: passengerIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      driverRating: driverRating,
      reviewCount: reviewCount,
      onTimeRate: onTimeRate,
      verifiedByUniversity: verifiedByUniversity,
    );
  }
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  return rawValue;
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
  }

  throw FormatException('Invalid $fieldName value.');
}

double _readRequiredDouble(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toDouble();
  }

  throw FormatException('Invalid $fieldName value.');
}

bool _readRequiredBool(Object? rawValue, String fieldName) {
  if (rawValue is bool) {
    return rawValue;
  }

  throw FormatException('Invalid $fieldName value.');
}

DateTime _parseRequiredDateTime(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }

  return parsed;
}

List<String> _readRequiredStringList(Object? rawValue, String fieldName) {
  if (rawValue is! List) {
    throw FormatException('Invalid $fieldName value.');
  }

  if (rawValue.any((item) => item is! String)) {
    throw FormatException('Invalid $fieldName value.');
  }

  return List<String>.from(rawValue);
}
