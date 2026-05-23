import 'package:wheels/features/help/domain/entities/help_article.dart';
import 'package:wheels/features/help/domain/entities/help_category.dart';

HelpArticle buildHelpArticle({
  String id = 'article-1',
  String? slug,
  String? title,
  HelpCategory category = HelpCategory.rides,
  DateTime? updatedAt,
  int upvotes = 10,
  int downvotes = 1,
}) {
  return HelpArticle(
    id: id,
    slug: slug ?? id,
    title: title ?? 'Article $id',
    summary: 'Summary for $id',
    body: 'Body for $id',
    category: category,
    tags: const <String>['demo', 'test'],
    updatedAt: updatedAt ?? DateTime.utc(2026, 5, 20),
    upvotes: upvotes,
    downvotes: downvotes,
  );
}
