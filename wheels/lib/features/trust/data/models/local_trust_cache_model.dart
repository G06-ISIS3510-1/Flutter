import '../../domain/entities/trust_entity.dart';
import 'trust_model.dart';

class LocalTrustCacheModel {
  const LocalTrustCacheModel({
    required this.version,
    required this.userId,
    required this.savedAt,
    required this.trust,
  });

  static const int currentVersion = 1;

  final int version;
  final String userId;
  final DateTime savedAt;
  final TrustModel trust;

  factory LocalTrustCacheModel.create({
    required String userId,
    required TrustEntity trust,
  }) {
    return LocalTrustCacheModel(
      version: currentVersion,
      userId: userId,
      savedAt: DateTime.now().toUtc(),
      trust: TrustModel.fromEntity(trust).copyWith(userId: userId),
    );
  }

  factory LocalTrustCacheModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported trust cache version: $version');
    }

    final rawTrust = json['trust'];
    if (rawTrust is! Map) {
      throw const FormatException('Invalid trust cache payload.');
    }

    return LocalTrustCacheModel(
      version: version,
      userId: _readRequiredString(json['userId'], 'userId'),
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      trust: TrustModel.fromJson(Map<String, dynamic>.from(rawTrust)),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'userId': userId,
      'savedAt': savedAt.toIso8601String(),
      'trust': trust.toJson(),
    };
  }

  bool matchesUser(String currentUserId) {
    return userId == currentUserId && trust.userId == currentUserId;
  }

  bool isExpired({Duration maxAge = const Duration(minutes: 30)}) {
    final now = DateTime.now().toUtc();
    if (savedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return true;
    }
    return now.difference(savedAt.toUtc()) > maxAge;
  }

  TrustEntity toEntity() => trust;
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is String) {
    return rawValue;
  }
  throw FormatException('Invalid $fieldName value.');
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
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
