import '../../domain/entities/rides_entity.dart';
import '../../presentation/models/ride_listing.dart';

class LocalRideSearchFiltersModel {
  const LocalRideSearchFiltersModel({
    required this.originQuery,
    required this.destinationQuery,
    required this.selectedDate,
    required this.sort,
  });

  final String originQuery;
  final String destinationQuery;
  final DateTime selectedDate;
  final RideSortOption sort;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'originQuery': originQuery,
      'destinationQuery': destinationQuery,
      'selectedDate': _formatDateOnly(selectedDate),
      'sort': sort.name,
    };
  }

  factory LocalRideSearchFiltersModel.fromJson(Map<String, dynamic> json) {
    final selectedDate = _parseRequiredDateOnly(
      json['selectedDate'],
      fieldName: 'selectedDate',
    );

    return LocalRideSearchFiltersModel(
      originQuery: _readRequiredString(json['originQuery'], 'originQuery'),
      destinationQuery: _readRequiredString(
        json['destinationQuery'],
        'destinationQuery',
      ),
      selectedDate: selectedDate,
      sort: _parseSort(json['sort']),
    );
  }

  static String _formatDateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static DateTime _parseRequiredDateOnly(
    Object? rawValue, {
    required String fieldName,
  }) {
    final parsed = DateTime.tryParse(_readRequiredString(rawValue, fieldName));
    if (parsed == null) {
      throw FormatException('Invalid $fieldName value.');
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static RideSortOption _parseSort(Object? rawValue) {
    final rawName = _readRequiredString(rawValue, 'sort');
    return RideSortOption.values.firstWhere(
      (value) => value.name == rawName,
      orElse: () => throw const FormatException('Invalid sort value.'),
    );
  }
}

class LocalRideSearchResultModel {
  const LocalRideSearchResultModel({
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

  factory LocalRideSearchResultModel.fromEntity(RidesEntity entity) {
    return LocalRideSearchResultModel(
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

  factory LocalRideSearchResultModel.fromJson(Map<String, dynamic> json) {
    return LocalRideSearchResultModel(
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
      availableSeats: _readRequiredInt(
        json['availableSeats'],
        'availableSeats',
      ),
      pricePerSeat: _readRequiredInt(json['pricePerSeat'], 'pricePerSeat'),
      paymentOption: ridePaymentOptionFromStorage(
        _readRequiredString(json['paymentOption'], 'paymentOption'),
      ),
      status: _readRequiredString(json['status'], 'status'),
      notes: _readRequiredString(json['notes'], 'notes'),
      passengerIds: _readRequiredStringList(
        json['passengerIds'],
        'passengerIds',
      ),
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

class LocalRideSearchCacheModel {
  const LocalRideSearchCacheModel({
    required this.version,
    required this.savedAt,
    required this.filters,
    required this.results,
  });

  static const int currentVersion = 1;

  final int version;
  final DateTime savedAt;
  final LocalRideSearchFiltersModel filters;
  final List<LocalRideSearchResultModel> results;

  factory LocalRideSearchCacheModel.create({
    required LocalRideSearchFiltersModel filters,
    required List<RidesEntity> results,
  }) {
    return LocalRideSearchCacheModel(
      version: currentVersion,
      savedAt: DateTime.now().toUtc(),
      filters: filters,
      results: results.map(LocalRideSearchResultModel.fromEntity).toList(),
    );
  }

  factory LocalRideSearchCacheModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported cache version: $version');
    }

    final rawResults = json['results'];
    if (rawResults is! List) {
      throw const FormatException('Invalid results payload.');
    }

    return LocalRideSearchCacheModel(
      version: version,
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      filters: LocalRideSearchFiltersModel.fromJson(
        Map<String, dynamic>.from(
          json['filters'] as Map<Object?, Object?>? ??
              (throw const FormatException('Missing filters payload.')),
        ),
      ),
      results: rawResults
          .map((item) {
            if (item is! Map) {
              throw const FormatException('Invalid ride result item.');
            }
            return LocalRideSearchResultModel.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'savedAt': savedAt.toIso8601String(),
      'filters': filters.toJson(),
      'results': results.map((result) => result.toJson()).toList(),
    };
  }

  List<RidesEntity> toEntities() {
    return results.map((result) => result.toEntity()).toList(growable: false);
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
