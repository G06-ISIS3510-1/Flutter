import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';
import '../providers/help_providers.dart';
import '../widgets/help_article_tile.dart';
import '../widgets/help_category_card.dart';
import '../widgets/help_resolution_rate_banner.dart';
import '../widgets/help_search_bar.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  late final String _sessionId;
  bool _sessionLogged = false;

  @override
  void initState() {
    super.initState();
    _sessionId = ref.read(helpSessionIdProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sessionLogged) return;
      _sessionLogged = true;
      // Touch side-effect providers to start remote sync, isolate corpus
      // sync, and the feedback/bookmark queue worker.
      ref.read(helpRemoteSyncProvider);
      ref.read(helpSearchSyncProvider);
      ref.read(helpFeedbackSyncWorkerProvider);
      // Fire BQ-J4 session start.
      ref.read(helpAnalyticsServiceProvider).logSessionStarted(
            sessionId: _sessionId,
            userId: currentHelpUserId(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final query = ref.watch(helpQueryProvider);
    final categoryFilter = ref.watch(helpCategoryFilterProvider);
    final articlesAsync = ref.watch(helpArticlesStreamProvider);

    final isSearchMode = query.hasDebouncedQuery;
    final isCategoryMode = !isSearchMode && categoryFilter != null;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.s,
                    AppSpacing.m,
                    AppSpacing.s,
                  ),
                  child: HelpSearchBar(
                    initialValue: query.raw,
                    onChanged: (value) {
                      ref.read(helpQueryProvider.notifier).update(value);
                      if (value.trim().isNotEmpty &&
                          ref.read(helpCategoryFilterProvider) != null) {
                        ref.read(helpCategoryFilterProvider.notifier).state =
                            null;
                      }
                    },
                    onClear: () =>
                        ref.read(helpQueryProvider.notifier).clear(),
                  ),
                ),
                if (isCategoryMode)
                  _CategoryFilterChip(
                    category: categoryFilter,
                    onClear: () => ref
                        .read(helpCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                Expanded(
                  child: articlesAsync.when(
                    loading: () => const _HelpSkeleton(),
                    error: (error, _) => _HelpErrorState(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(helpArticlesStreamProvider),
                    ),
                    data: (articles) {
                      if (isSearchMode) {
                        return _HelpSearchResults(sessionId: _sessionId);
                      }
                      if (isCategoryMode) {
                        return _HelpCategoryListing(
                          category: categoryFilter,
                          articles: articles,
                          onArticleTap: _onArticleTap,
                        );
                      }
                      return _HelpBrowseView(
                        sessionId: _sessionId,
                        articles: articles,
                        onCategoryTap: (category) => ref
                            .read(helpCategoryFilterProvider.notifier)
                            .state = category,
                        onArticleTap: _onArticleTap,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onArticleTap(HelpArticle article) {
    context.go(AppRoutes.helpArticleById(article.id));
  }
}

class _HelpSkeleton extends StatelessWidget {
  const _HelpSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < 5; i++) ...[
            Container(
              height: 84,
              decoration: BoxDecoration(
                color: palette.cardSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}

class _HelpErrorState extends StatelessWidget {
  const _HelpErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: palette.error,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Help Center could not load.',
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

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({required this.category, required this.onClear});

  final HelpCategory category;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text('Category: ${category.label}'),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: onClear,
          backgroundColor: palette.accentSoft,
          labelStyle: TextStyle(
            color: palette.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// F-J-8 micro-optimization (refs sprint4-wiki §6.1).
//
// Before: `_HelpBrowseView` was one `ConsumerWidget` that watched three
// derived providers in a single `build()` and returned a monolithic
// `ListView` of mixed children. Whenever any of the three providers
// re-emitted, the entire browse view (category grid + recently viewed
// strip + most-helpful list + banner + CTA) rebuilt and repainted together
// even though only one section actually changed.
//
// After: each section is its own `RepaintBoundary`-wrapped `Consumer` that
// watches only the provider it needs, so rebuilds and repaints are scoped
// to the section that actually changed. The horizontal strip and the
// long-list lists additionally pass `addAutomaticKeepAlives: false` and
// `addRepaintBoundaries: false` because we are wrapping each child
// manually with the correct `RepaintBoundary` granularity. `cacheExtent`
// is bumped to 600 px so off-screen builds finish before they become
// visible.
class _HelpBrowseView extends StatelessWidget {
  const _HelpBrowseView({
    required this.sessionId,
    required this.articles,
    required this.onCategoryTap,
    required this.onArticleTap,
  });

  final String sessionId;
  final List<HelpArticle> articles;
  final ValueChanged<HelpCategory> onCategoryTap;
  final ValueChanged<HelpArticle> onArticleTap;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return _HelpEmptyState(
        icon: Icons.help_outline_rounded,
        title: 'No help articles available yet',
        subtitle:
            'The Help Center will populate once articles are seeded or synced.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.xl,
      ),
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      children: [
        const _SectionTitle('Browse by category'),
        const SizedBox(height: AppSpacing.s),
        RepaintBoundary(
          child: _CategoryGridSection(onCategoryTap: onCategoryTap),
        ),
        const SizedBox(height: AppSpacing.l),
        RepaintBoundary(
          child: _RecentlyViewedSection(onArticleTap: onArticleTap),
        ),
        const SizedBox(height: AppSpacing.l),
        const _SectionTitle('Most helpful'),
        const SizedBox(height: AppSpacing.s),
        RepaintBoundary(
          child: _MostHelpfulSection(onArticleTap: onArticleTap),
        ),
        const SizedBox(height: AppSpacing.l),
        const RepaintBoundary(child: HelpResolutionRateBanner()),
        const SizedBox(height: AppSpacing.m),
        RepaintBoundary(
          child: _ContactSupportSection(sessionId: sessionId),
        ),
      ],
    );
  }
}

class _CategoryGridSection extends ConsumerWidget {
  const _CategoryGridSection({required this.onCategoryTap});

  final ValueChanged<HelpCategory> onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(helpCategoryCountsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.s;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final category in HelpCategory.values)
              SizedBox(
                width: cardWidth,
                child: RepaintBoundary(
                  child: HelpCategoryCard(
                    category: category,
                    articleCount: counts[category] ?? 0,
                    onTap: () => onCategoryTap(category),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentlyViewedSection extends ConsumerWidget {
  const _RecentlyViewedSection({required this.onArticleTap});

  final ValueChanged<HelpArticle> onArticleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewed = ref.watch(helpRecentlyViewedArticlesProvider);
    if (recentlyViewed.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Recently viewed'),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentlyViewed.length,
            cacheExtent: 600,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
            itemBuilder: (context, index) {
              final article = recentlyViewed[index];
              return RepaintBoundary(
                child: SizedBox(
                  width: 260,
                  child: HelpArticleTile(
                    article: article,
                    onTap: () => onArticleTap(article),
                    compact: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MostHelpfulSection extends ConsumerWidget {
  const _MostHelpfulSection({required this.onArticleTap});

  final ValueChanged<HelpArticle> onArticleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostHelpful = ref.watch(helpMostHelpfulProvider);
    if (mostHelpful.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < mostHelpful.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s),
          RepaintBoundary(
            child: HelpArticleTile(
              article: mostHelpful[i],
              onTap: () => onArticleTap(mostHelpful[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactSupportSection extends ConsumerWidget {
  const _ContactSupportSection({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return _ContactSupportCard(
      onContact: () {
        ref.read(helpAnalyticsServiceProvider).logContactSupportClicked(
              sessionId: sessionId,
              userId: currentHelpUserId(),
              query: ref.read(helpQueryProvider).debounced,
            );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Support form coming soon — your tap was recorded.',
              ),
              backgroundColor: palette.accent,
            ),
          );
      },
    );
  }
}

class _HelpSearchResults extends ConsumerWidget {
  const _HelpSearchResults({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(helpSearchResultsProvider);

    return resultsAsync.when(
      loading: () => const _HelpSkeleton(),
      error: (error, _) => _HelpErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(helpSearchResultsProvider),
      ),
      data: (results) {
        if (results.isEmpty) {
          return _HelpEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No articles match your search',
            subtitle:
                'Try simpler terms, or browse by category from the home view.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.xl,
          ),
          itemCount: results.length + 1,
          cacheExtent: 600,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            if (index == results.length) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: RepaintBoundary(
                  child: _ContactSupportCard(
                    onContact: () {
                      ref
                          .read(helpAnalyticsServiceProvider)
                          .logContactSupportClicked(
                            sessionId: sessionId,
                            userId: currentHelpUserId(),
                            query: ref.read(helpQueryProvider).debounced,
                          );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Support form coming soon — your tap was recorded.',
                            ),
                          ),
                        );
                    },
                  ),
                ),
              );
            }
            final article = results[index];
            return RepaintBoundary(
              child: HelpArticleTile(
                article: article,
                onTap: () =>
                    context.go(AppRoutes.helpArticleById(article.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _HelpCategoryListing extends StatelessWidget {
  const _HelpCategoryListing({
    required this.category,
    required this.articles,
    required this.onArticleTap,
  });

  final HelpCategory category;
  final List<HelpArticle> articles;
  final ValueChanged<HelpArticle> onArticleTap;

  @override
  Widget build(BuildContext context) {
    final filtered = articles.where((a) => a.category == category).toList()
      ..sort((a, b) => b.netHelpfulness.compareTo(a.netHelpfulness));

    if (filtered.isEmpty) {
      return _HelpEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No articles in ${category.label} yet',
        subtitle: 'New articles will appear here as they are published.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.xl,
      ),
      itemCount: filtered.length,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final article = filtered[index];
        return RepaintBoundary(
          child: HelpArticleTile(
            article: article,
            onTap: () => onArticleTap(article),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      title,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: palette.accentForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Still need help?',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'If none of these articles solve your problem, contact the Wheels '
            'support team and we will reach out as soon as possible.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Contact support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.accentForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpEmptyState extends StatelessWidget {
  const _HelpEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: palette.textSecondary, size: 40),
          const SizedBox(height: AppSpacing.s),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
