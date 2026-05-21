import 'help_category.dart';

class HelpArticle {
  const HelpArticle({
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

  int get netHelpfulness => upvotes - downvotes;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (title.toLowerCase().contains(normalized)) return true;
    if (summary.toLowerCase().contains(normalized)) return true;
    if (body.toLowerCase().contains(normalized)) return true;
    return tags.any((tag) => tag.toLowerCase().contains(normalized));
  }
}
