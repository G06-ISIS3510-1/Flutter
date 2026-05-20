import '../../domain/entities/help_feedback.dart';

class HelpBookmarkModel {
  const HelpBookmarkModel({
    required this.version,
    required this.articleId,
    required this.userId,
    required this.savedAt,
    required this.pendingSync,
  });

  static const int currentVersion = 1;

  final int version;
  final String articleId;
  final String userId;
  final DateTime savedAt;
  final bool pendingSync;

  factory HelpBookmarkModel.fromEntity(HelpBookmark entity) {
    return HelpBookmarkModel(
      version: currentVersion,
      articleId: entity.articleId,
      userId: entity.userId,
      savedAt: entity.savedAt,
      pendingSync: entity.pendingSync,
    );
  }

  factory HelpBookmarkModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported help bookmark version: $version');
    }
    return HelpBookmarkModel(
      version: version,
      articleId: _readRequiredString(json['articleId'], 'articleId'),
      userId: _readRequiredString(json['userId'], 'userId'),
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      pendingSync: _readRequiredBool(json['pendingSync'], 'pendingSync'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'articleId': articleId,
      'userId': userId,
      'savedAt': savedAt.toIso8601String(),
      'pendingSync': pendingSync,
    };
  }

  HelpBookmark toEntity() {
    return HelpBookmark(
      articleId: articleId,
      userId: userId,
      savedAt: savedAt,
      pendingSync: pendingSync,
    );
  }

  HelpBookmarkModel copyWith({bool? pendingSync, DateTime? savedAt}) {
    return HelpBookmarkModel(
      version: version,
      articleId: articleId,
      userId: userId,
      savedAt: savedAt ?? this.savedAt,
      pendingSync: pendingSync ?? this.pendingSync,
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
