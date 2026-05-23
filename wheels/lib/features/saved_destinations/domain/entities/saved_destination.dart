class SavedDestination {
  const SavedDestination({
    this.localId,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.lastUsedAt,
    required this.useCount,
    this.remoteId,
    this.thumbnailUrl,
    this.pendingSync = false,
    this.isDeleted = false,
  });

  final int? localId;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final int useCount;
  final String? remoteId;
  final String? thumbnailUrl;
  final bool pendingSync;
  final bool isDeleted;

  String get displayLabel => name.trim().isEmpty ? address : name.trim();

  bool get hasResolvedCoordinates => latitude != 0 || longitude != 0;

  String get coordinatesLabel =>
      hasResolvedCoordinates
          ? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
          : 'Coordinates pending';

  SavedDestination copyWith({
    int? localId,
    String? userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
    String? remoteId,
    String? thumbnailUrl,
    bool? pendingSync,
    bool? isDeleted,
  }) {
    return SavedDestination(
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      remoteId: remoteId ?? this.remoteId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class SavedDestinationUsageStats {
  const SavedDestinationUsageStats({
    required this.totalRideCount,
    required this.averagePricePerSeat,
    required this.lastVisitLabels,
  });

  final int totalRideCount;
  final double averagePricePerSeat;
  final List<String> lastVisitLabels;

  static const empty = SavedDestinationUsageStats(
    totalRideCount: 0,
    averagePricePerSeat: 0,
    lastVisitLabels: <String>[],
  );
}
