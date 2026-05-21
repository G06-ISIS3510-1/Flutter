import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';
import '../../domain/entities/help_feedback.dart';
import '../providers/help_providers.dart';
import '../widgets/help_article_tile.dart';

class HelpArticleScreen extends ConsumerStatefulWidget {
  const HelpArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<HelpArticleScreen> createState() => _HelpArticleScreenState();
}

class _HelpArticleScreenState extends ConsumerState<HelpArticleScreen> {
  bool _viewLogged = false;
  HelpFeedbackVote? _localVote;
  bool _submittingFeedback = false;
  bool _togglingBookmark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(helpRecentlyViewedProvider.notifier).markViewed(widget.articleId);
      // Restore the user's previous vote so the 👍 / 👎 selection survives
      // navigation and sync drains.
      final existingVote = await ref.read(helpRepositoryProvider).loadUserVote(
            userId: currentHelpUserId(),
            articleId: widget.articleId,
          );
      if (!mounted || existingVote == null) return;
      setState(() => _localVote = existingVote);
    });
  }

  void _logArticleView(HelpArticle article) {
    if (_viewLogged) return;
    _viewLogged = true;
    final sessionId = ref.read(helpSessionIdProvider);
    ref.read(helpAnalyticsServiceProvider).logArticleViewed(
          sessionId: sessionId,
          userId: currentHelpUserId(),
          articleId: article.id,
          category: article.category.storageValue,
        );
  }

  Future<void> _toggleBookmark(HelpArticle article) async {
    if (_togglingBookmark) return;
    setState(() => _togglingBookmark = true);
    try {
      await ref.read(helpRepositoryProvider).toggleBookmark(
            userId: currentHelpUserId(),
            articleId: article.id,
          );
      ref.invalidate(helpArticleBookmarkedProvider(article.id));
    } finally {
      if (mounted) {
        setState(() => _togglingBookmark = false);
      }
    }
  }

  Future<void> _submitFeedback(
    HelpArticle article,
    HelpFeedbackVote vote,
  ) async {
    if (_submittingFeedback || _localVote == vote) return;
    setState(() {
      _submittingFeedback = true;
      _localVote = vote;
    });
    try {
      final feedback = HelpFeedback(
        id: generateHelpFeedbackId(),
        articleId: article.id,
        userId: currentHelpUserId(),
        vote: vote,
        createdAt: DateTime.now().toUtc(),
      );
      await ref.read(helpRepositoryProvider).submitFeedback(feedback);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              vote == HelpFeedbackVote.upvote
                  ? 'Thanks for the feedback!'
                  : 'Got it. We will improve this article.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _localVote = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save feedback: $error')),
        );
    } finally {
      if (mounted) {
        setState(() => _submittingFeedback = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final articleAsync = ref.watch(helpArticleByIdProvider(widget.articleId));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Article'),
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.helpCenter);
            }
          },
        ),
        actions: [
          articleAsync.maybeWhen(
            data: (article) {
              if (article == null) return const SizedBox.shrink();
              return _BookmarkAction(
                articleId: article.id,
                busy: _togglingBookmark,
                onToggle: () => _toggleBookmark(article),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: articleAsync.when(
              loading: () => const _ArticleSkeleton(),
              error: (error, _) => _ArticleErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  helpArticleByIdProvider(widget.articleId),
                ),
              ),
              data: (article) {
                if (article == null) {
                  return _ArticleEmptyState(articleId: widget.articleId);
                }
                _logArticleView(article);
                return _ArticleBody(
                  article: article,
                  localVote: _localVote,
                  submittingFeedback: _submittingFeedback,
                  onVote: (vote) => _submitFeedback(article, vote),
                  onRelatedTap: (related) {
                    context.go(AppRoutes.helpArticleById(related.id));
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({
    required this.article,
    required this.localVote,
    required this.submittingFeedback,
    required this.onVote,
    required this.onRelatedTap,
  });

  final HelpArticle article;
  final HelpFeedbackVote? localVote;
  final bool submittingFeedback;
  final ValueChanged<HelpFeedbackVote> onVote;
  final ValueChanged<HelpArticle> onRelatedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final related = ref.watch(
      helpRelatedArticlesProvider(
        HelpRelatedArticlesQuery(
          articleId: article.id,
          category: article.category,
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.heroImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: CachedNetworkImage(
                imageUrl: article.heroImageUrl!,
                memCacheWidth: 800,
                fit: BoxFit.cover,
                placeholder: (_, _) => _ImagePlaceholder(palette: palette),
                errorWidget: (_, _, _) => _ImagePlaceholder(palette: palette),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          _ArticleHeader(article: article),
          const SizedBox(height: AppSpacing.m),
          MarkdownBody(
            data: article.body,
            selectable: true,
            sizedImageBuilder: (config) {
              return CachedNetworkImage(
                imageUrl: config.uri.toString(),
                memCacheWidth: 800,
                fit: BoxFit.cover,
                placeholder: (_, _) => _ImagePlaceholder(palette: palette),
                errorWidget: (_, _, _) => _ImagePlaceholder(palette: palette),
              );
            },
            styleSheet: _markdownStyle(context),
          ),
          const SizedBox(height: AppSpacing.l),
          _FeedbackRow(
            localVote: localVote,
            submitting: submittingFeedback,
            onVote: onVote,
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text(
              'Related articles',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            ...related.expand(
              (item) => <Widget>[
                HelpArticleTile(
                  article: item,
                  onTap: () => onRelatedTap(item),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

MarkdownStyleSheet _markdownStyle(BuildContext context) {
  final palette = context.palette;
  final baseTextStyle = TextStyle(color: palette.textPrimary, fontSize: 15);
  return MarkdownStyleSheet(
    p: baseTextStyle,
    h1: baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
    h2: baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
    h3: baseTextStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
    strong: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
    em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
    blockquote: baseTextStyle.copyWith(color: palette.textSecondary),
    code: TextStyle(
      color: palette.accent,
      backgroundColor: palette.surfaceMuted,
      fontFamily: 'monospace',
      fontSize: 13,
    ),
    listBullet: baseTextStyle,
    a: TextStyle(
      color: palette.accent,
      decoration: TextDecoration.underline,
    ),
  );
}

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({required this.article});

  final HelpArticle article;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            article.category.label,
            style: TextStyle(
              color: palette.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          article.title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          article.summary,
          style: TextStyle(color: palette.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
    required this.localVote,
    required this.submitting,
    required this.onVote,
  });

  final HelpFeedbackVote? localVote;
  final bool submitting;
  final ValueChanged<HelpFeedbackVote> onVote;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasVoted = localVote != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Was this article helpful?',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: <Widget>[
              Expanded(
                child: _FeedbackButton(
                  label: 'Helpful',
                  icon: Icons.thumb_up_alt_outlined,
                  selected: localVote == HelpFeedbackVote.upvote,
                  busy: submitting && localVote == HelpFeedbackVote.upvote,
                  onPressed: submitting
                      ? null
                      : () => onVote(HelpFeedbackVote.upvote),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _FeedbackButton(
                  label: 'Not helpful',
                  icon: Icons.thumb_down_alt_outlined,
                  selected: localVote == HelpFeedbackVote.downvote,
                  busy: submitting && localVote == HelpFeedbackVote.downvote,
                  onPressed: submitting
                      ? null
                      : () => onVote(HelpFeedbackVote.downvote),
                ),
              ),
            ],
          ),
          if (hasVoted) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              'Your vote is queued locally and will sync when online.',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = selected ? palette.accentForeground : palette.textPrimary;
    final bg = selected ? palette.accent : palette.cardSecondary;
    final borderColor = selected ? palette.accent : palette.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else
                Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkAction extends ConsumerWidget {
  const _BookmarkAction({
    required this.articleId,
    required this.busy,
    required this.onToggle,
  });

  final String articleId;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final bookmarked =
        ref.watch(helpArticleBookmarkedProvider(articleId)).valueOrNull ??
            false;

    return IconButton(
      tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
      onPressed: busy ? null : onToggle,
      icon: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.textSecondary,
              ),
            )
          : Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: bookmarked ? palette.accent : palette.textSecondary,
            ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.palette});

  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: palette.cardSecondary,
      child: Icon(
        Icons.image_outlined,
        color: palette.textSecondary,
        size: 48,
      ),
    );
  }
}

class _ArticleSkeleton extends StatelessWidget {
  const _ArticleSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 80,
            decoration: BoxDecoration(
              color: palette.cardSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            height: 28,
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.cardSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          for (var i = 0; i < 6; i++) ...[
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: palette.cardSecondary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}

class _ArticleErrorState extends StatelessWidget {
  const _ArticleErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: palette.error, size: 40),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Could not load the article.',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ArticleEmptyState extends StatelessWidget {
  const _ArticleEmptyState({required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            color: palette.textSecondary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Article not found',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Could not find an article with id "$articleId" locally or on the server.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
