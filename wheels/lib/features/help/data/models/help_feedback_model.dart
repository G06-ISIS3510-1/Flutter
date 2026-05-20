import '../../domain/entities/help_feedback.dart';

class HelpFeedbackModel {
  const HelpFeedbackModel({
    required this.version,
    required this.id,
    required this.articleId,
    required this.userId,
    required this.vote,
    required this.createdAt,
    this.note,
  });

  static const int currentVersion = 1;

  final int version;
  final String id;
  final String articleId;
  final String userId;
  final HelpFeedbackVote vote;
  final DateTime createdAt;
  final String? note;

  factory HelpFeedbackModel.fromEntity(HelpFeedback entity) {
    return HelpFeedbackModel(
      version: currentVersion,
      id: entity.id,
      articleId: entity.articleId,
      userId: entity.userId,
      vote: entity.vote,
      createdAt: entity.createdAt,
      note: entity.note,
    );
  }

  factory HelpFeedbackModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported help feedback version: $version');
    }
    final rawNote = json['note'];
    final note = rawNote is String && rawNote.trim().isNotEmpty ? rawNote : null;
    return HelpFeedbackModel(
      version: version,
      id: _readRequiredString(json['id'], 'id'),
      articleId: _readRequiredString(json['articleId'], 'articleId'),
      userId: _readRequiredString(json['userId'], 'userId'),
      vote: helpFeedbackVoteFromStorage(
        _readRequiredString(json['vote'], 'vote'),
      ),
      createdAt: _parseRequiredDateTime(json['createdAt'], 'createdAt'),
      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'id': id,
      'articleId': articleId,
      'userId': userId,
      'vote': vote.storageValue,
      'createdAt': createdAt.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  HelpFeedback toEntity() {
    return HelpFeedback(
      id: id,
      articleId: articleId,
      userId: userId,
      vote: vote,
      createdAt: createdAt,
      note: note,
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
