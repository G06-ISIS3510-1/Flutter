import '../../domain/entities/rides_entity.dart';

class LocalCreateRideDraftModel {
  const LocalCreateRideDraftModel({
    required this.version,
    required this.savedAt,
    required this.origin,
    required this.destination,
    required this.notes,
    required this.dateText,
    required this.timeText,
    required this.durationText,
    required this.priceText,
    required this.availableSeats,
    required this.paymentOption,
    required this.currentLocationSuggestion,
    required this.pendingSync,
    required this.pendingSyncReason,
    required this.pendingSyncRequestedAt,
  });

  static const int currentVersion = 1;

  final int version;
  final DateTime savedAt;
  final String origin;
  final String destination;
  final String notes;
  final String dateText;
  final String timeText;
  final String durationText;
  final String priceText;
  final int availableSeats;
  final RidePaymentOption paymentOption;
  final String? currentLocationSuggestion;
  final bool pendingSync;
  final String? pendingSyncReason;
  final DateTime? pendingSyncRequestedAt;

  factory LocalCreateRideDraftModel.create({
    required String origin,
    required String destination,
    required String notes,
    required String dateText,
    required String timeText,
    required String durationText,
    required String priceText,
    required int availableSeats,
    required RidePaymentOption paymentOption,
    String? currentLocationSuggestion,
    bool pendingSync = false,
    String? pendingSyncReason,
    DateTime? pendingSyncRequestedAt,
  }) {
    return LocalCreateRideDraftModel(
      version: currentVersion,
      savedAt: DateTime.now().toUtc(),
      origin: origin,
      destination: destination,
      notes: notes,
      dateText: dateText,
      timeText: timeText,
      durationText: durationText,
      priceText: priceText,
      availableSeats: availableSeats,
      paymentOption: paymentOption,
      currentLocationSuggestion: currentLocationSuggestion,
      pendingSync: pendingSync,
      pendingSyncReason: pendingSyncReason,
      pendingSyncRequestedAt: pendingSyncRequestedAt?.toUtc(),
    );
  }

  factory LocalCreateRideDraftModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported create ride draft version: $version');
    }

    return LocalCreateRideDraftModel(
      version: version,
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      origin: _readRequiredString(json['origin'], 'origin'),
      destination: _readRequiredString(json['destination'], 'destination'),
      notes: _readRequiredString(json['notes'], 'notes'),
      dateText: _readRequiredString(json['dateText'], 'dateText'),
      timeText: _readRequiredString(json['timeText'], 'timeText'),
      durationText: _readRequiredString(json['durationText'], 'durationText'),
      priceText: _readRequiredString(json['priceText'], 'priceText'),
      availableSeats: _readRequiredInt(json['availableSeats'], 'availableSeats'),
      paymentOption: ridePaymentOptionFromStorage(
        _readRequiredString(json['paymentOption'], 'paymentOption'),
      ),
      currentLocationSuggestion: _readOptionalString(
        json['currentLocationSuggestion'],
      ),
      pendingSync: _readRequiredBool(json['pendingSync'], 'pendingSync'),
      pendingSyncReason: _readOptionalString(json['pendingSyncReason']),
      pendingSyncRequestedAt: _parseOptionalDateTime(
        json['pendingSyncRequestedAt'],
        'pendingSyncRequestedAt',
      ),
    );
  }

  bool get hasMeaningfulData {
    return origin.trim().isNotEmpty ||
        destination.trim().isNotEmpty ||
        notes.trim().isNotEmpty ||
        dateText.trim().isNotEmpty ||
        timeText.trim().isNotEmpty ||
        durationText.trim().isNotEmpty ||
        priceText.trim().isNotEmpty;
  }

  LocalCreateRideDraftModel copyWith({
    DateTime? savedAt,
    String? origin,
    String? destination,
    String? notes,
    String? dateText,
    String? timeText,
    String? durationText,
    String? priceText,
    int? availableSeats,
    RidePaymentOption? paymentOption,
    String? currentLocationSuggestion,
    bool? pendingSync,
    String? pendingSyncReason,
    DateTime? pendingSyncRequestedAt,
    bool clearPendingSyncReason = false,
    bool clearPendingSyncRequestedAt = false,
  }) {
    return LocalCreateRideDraftModel(
      version: version,
      savedAt: savedAt ?? this.savedAt,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      notes: notes ?? this.notes,
      dateText: dateText ?? this.dateText,
      timeText: timeText ?? this.timeText,
      durationText: durationText ?? this.durationText,
      priceText: priceText ?? this.priceText,
      availableSeats: availableSeats ?? this.availableSeats,
      paymentOption: paymentOption ?? this.paymentOption,
      currentLocationSuggestion:
          currentLocationSuggestion ?? this.currentLocationSuggestion,
      pendingSync: pendingSync ?? this.pendingSync,
      pendingSyncReason: clearPendingSyncReason
          ? null
          : (pendingSyncReason ?? this.pendingSyncReason),
      pendingSyncRequestedAt: clearPendingSyncRequestedAt
          ? null
          : (pendingSyncRequestedAt ?? this.pendingSyncRequestedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'savedAt': savedAt.toIso8601String(),
      'origin': origin,
      'destination': destination,
      'notes': notes,
      'dateText': dateText,
      'timeText': timeText,
      'durationText': durationText,
      'priceText': priceText,
      'availableSeats': availableSeats,
      'paymentOption': paymentOption.storageValue,
      'currentLocationSuggestion': currentLocationSuggestion,
      'pendingSync': pendingSync,
      'pendingSyncReason': pendingSyncReason,
      'pendingSyncRequestedAt': pendingSyncRequestedAt?.toIso8601String(),
    };
  }
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  return rawValue;
}

String? _readOptionalString(Object? rawValue) {
  if (rawValue == null) {
    return null;
  }
  if (rawValue is! String) {
    throw const FormatException('Invalid optional string value.');
  }
  return rawValue;
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
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
  final rawString = _readRequiredString(rawValue, fieldName);
  final parsed = DateTime.tryParse(rawString);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }

  return parsed.toUtc();
}

DateTime? _parseOptionalDateTime(Object? rawValue, String fieldName) {
  final rawString = _readOptionalString(rawValue);
  if (rawString == null || rawString.trim().isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(rawString);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }

  return parsed.toUtc();
}
