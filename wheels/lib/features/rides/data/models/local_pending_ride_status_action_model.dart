class LocalPendingRideStatusActionModel {
  const LocalPendingRideStatusActionModel({
    required this.version,
    required this.rideId,
    required this.targetStatus,
    required this.lastKnownStatus,
    required this.savedAt,
  });

  final int version;
  final String rideId;
  final String targetStatus;
  final String lastKnownStatus;
  final DateTime savedAt;

  factory LocalPendingRideStatusActionModel.create({
    required String rideId,
    required String targetStatus,
    required String lastKnownStatus,
    DateTime? savedAt,
  }) {
    return LocalPendingRideStatusActionModel(
      version: 1,
      rideId: rideId,
      targetStatus: targetStatus,
      lastKnownStatus: lastKnownStatus,
      savedAt: savedAt ?? DateTime.now(),
    );
  }

  factory LocalPendingRideStatusActionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    if (version != 1) {
      throw FormatException('Unsupported pending ride action version: $version');
    }

    final rideId = json['rideId'];
    final targetStatus = json['targetStatus'];
    final lastKnownStatus = json['lastKnownStatus'];
    final savedAtRaw = json['savedAt'];

    if (rideId is! String ||
        targetStatus is! String ||
        lastKnownStatus is! String ||
        savedAtRaw is! String) {
      throw const FormatException('Stored pending ride action is invalid.');
    }

    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null) {
      throw const FormatException(
        'Stored pending ride action has an invalid date.',
      );
    }

    return LocalPendingRideStatusActionModel(
      version: version,
      rideId: rideId,
      targetStatus: targetStatus,
      lastKnownStatus: lastKnownStatus,
      savedAt: savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'rideId': rideId,
      'targetStatus': targetStatus,
      'lastKnownStatus': lastKnownStatus,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
