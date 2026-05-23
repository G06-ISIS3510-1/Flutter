import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';

class HelpArticleModel {
  const HelpArticleModel({
    required this.version,
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.tags,
    required this.updatedAt,
    required this.upvotes,
    required this.downvotes,
    this.heroImageUrl,
  });

  static const int currentVersion = 1;

  final int version;
  final String id;
  final String slug;
  final String title;
  final String summary;
  final String body;
  final HelpCategory category;
  final List<String> tags;
  final DateTime updatedAt;
  final int upvotes;
  final int downvotes;
  final String? heroImageUrl;

  factory HelpArticleModel.fromEntity(HelpArticle entity) {
    return HelpArticleModel(
      version: currentVersion,
      id: entity.id,
      slug: entity.slug,
      title: entity.title,
      summary: entity.summary,
      body: entity.body,
      category: entity.category,
      tags: List<String>.from(entity.tags),
      updatedAt: entity.updatedAt,
      upvotes: entity.upvotes,
      downvotes: entity.downvotes,
      heroImageUrl: entity.heroImageUrl,
    );
  }

  factory HelpArticleModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported help article cache version: $version');
    }

    final rawHero = json['heroImageUrl'];
    final heroImageUrl = rawHero is String && rawHero.trim().isNotEmpty
        ? rawHero
        : null;

    return HelpArticleModel(
      version: version,
      id: _readRequiredString(json['id'], 'id'),
      slug: _readRequiredString(json['slug'], 'slug'),
      title: _readRequiredString(json['title'], 'title'),
      summary: _readRequiredString(json['summary'], 'summary'),
      body: _readRequiredString(json['body'], 'body'),
      category: helpCategoryFromStorage(
        _readRequiredString(json['category'], 'category'),
      ),
      tags: _readRequiredStringList(json['tags'], 'tags'),
      updatedAt: _parseRequiredDateTime(json['updatedAt'], 'updatedAt'),
      upvotes: _readRequiredInt(json['upvotes'], 'upvotes'),
      downvotes: _readRequiredInt(json['downvotes'], 'downvotes'),
      heroImageUrl: heroImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'id': id,
      'slug': slug,
      'title': title,
      'summary': summary,
      'body': body,
      'category': category.storageValue,
      'tags': tags,
      'updatedAt': updatedAt.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
    };
  }

  HelpArticle toEntity() {
    return HelpArticle(
      id: id,
      slug: slug,
      title: title,
      summary: summary,
      body: body,
      category: category,
      tags: List<String>.from(tags),
      updatedAt: updatedAt,
      upvotes: upvotes,
      downvotes: downvotes,
      heroImageUrl: heroImageUrl,
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

List<String> _readRequiredStringList(Object? rawValue, String fieldName) {
  if (rawValue is! List) {
    throw FormatException('Invalid $fieldName value.');
  }
  if (rawValue.any((item) => item is! String)) {
    throw FormatException('Invalid $fieldName value.');
  }
  return List<String>.from(rawValue);
}
