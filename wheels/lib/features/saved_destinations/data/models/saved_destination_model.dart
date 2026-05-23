import '../../domain/entities/saved_destination.dart';

class SavedDestinationModel extends SavedDestination {
  const SavedDestinationModel({
    super.localId,
    required super.userId,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.createdAt,
    required super.lastUsedAt,
    required super.useCount,
    super.remoteId,
    super.thumbnailUrl,
    super.pendingSync,
    super.isDeleted,
  });

  factory SavedDestinationModel.create({
    int? localId,
    required String userId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? remoteId,
    String? thumbnailUrl,
    bool pendingSync = true,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int useCount = 0,
  }) {
    final now = DateTime.now().toUtc();
    return SavedDestinationModel(
      localId: localId,
      userId: userId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt ?? now,
      lastUsedAt: lastUsedAt ?? now,
      useCount: useCount,
      remoteId: remoteId,
      thumbnailUrl: thumbnailUrl,
      pendingSync: pendingSync,
      isDeleted: isDeleted,
    );
  }

  factory SavedDestinationModel.fromEntity(SavedDestination entity) {
    return SavedDestinationModel(
      localId: entity.localId,
      userId: entity.userId,
      name: entity.name,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
      useCount: entity.useCount,
      remoteId: entity.remoteId,
      thumbnailUrl: entity.thumbnailUrl,
      pendingSync: entity.pendingSync,
      isDeleted: entity.isDeleted,
    );
  }

  factory SavedDestinationModel.fromSqlite(Map<String, Object?> row) {
    return SavedDestinationModel(
      localId: row['id'] as int?,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      address: row['address'] as String,
      latitude: (row['lat'] as num).toDouble(),
      longitude: (row['lng'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(
        row['last_used_at'] as int,
        isUtc: true,
      ),
      useCount: row['use_count'] as int,
      remoteId: row['remote_id'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      pendingSync: (row['pending_sync'] as int? ?? 0) == 1,
      isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toSqlite() {
    return <String, Object?>{
      'id': localId,
      'user_id': userId,
      'name': name,
      'address': address,
      'lat': latitude,
      'lng': longitude,
      'created_at': createdAt.toUtc().millisecondsSinceEpoch,
      'last_used_at': lastUsedAt.toUtc().millisecondsSinceEpoch,
      'use_count': useCount,
      'remote_id': remoteId,
      'thumbnail_url': thumbnailUrl,
      'pending_sync': pendingSync ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, Object?> toRemoteJson() {
    return <String, Object?>{
      'userId': userId,
      'name': name,
      'address': address,
      'normalizedAddress': address.trim().toLowerCase(),
      'lat': latitude,
      'lng': longitude,
      'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
      'lastUsedAt': lastUsedAt.toUtc().millisecondsSinceEpoch,
      'useCount': useCount,
      'thumbnailUrl': thumbnailUrl,
      'isDeleted': isDeleted,
    };
  }

  SavedDestinationModel copyModelWith({
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
    return SavedDestinationModel(
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
