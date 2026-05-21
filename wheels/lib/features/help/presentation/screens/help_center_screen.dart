import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_category.dart';
import '../providers/help_providers.dart';
import '../widgets/help_article_tile.dart';
import '../widgets/help_category_card.dart';
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
      // Touch side-effect providers to start remote sync and isolate corpus sync.
      ref.read(helpRemoteSyncProvider);
      ref.read(helpSearchSyncProvider);
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
    // F-J-5 will replace this with go_router navigation to HelpArticleScreen.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Opening "${article.title}" — coming in F-J-5'),
        ),
      );
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

class _HelpBrowseView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final counts = ref.watch(helpCategoryCountsProvider);
    final recentlyViewed = ref.watch(helpRecentlyViewedArticlesProvider);
    final mostHelpful = ref.watch(helpMostHelpfulProvider);

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
      children: [
        _SectionTitle('Browse by category'),
        const SizedBox(height: AppSpacing.s),
        LayoutBuilder(
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
                    child: HelpCategoryCard(
                      category: category,
                      articleCount: counts[category] ?? 0,
                      onTap: () => onCategoryTap(category),
                    ),
                  ),
              ],
            );
          },
        ),
        if (recentlyViewed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          _SectionTitle('Recently viewed'),
          const SizedBox(height: AppSpacing.s),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewed.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, index) {
                final article = recentlyViewed[index];
                return SizedBox(
                  width: 260,
                  child: HelpArticleTile(
                    article: article,
                    onTap: () => onArticleTap(article),
                    compact: true,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        _SectionTitle('Most helpful'),
        const SizedBox(height: AppSpacing.s),
        ...mostHelpful.expand(
          (article) => <Widget>[
            HelpArticleTile(
              article: article,
              onTap: () => onArticleTap(article),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        _ContactSupportCard(
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
        ),
      ],
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
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            if (index == results.length) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
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
              );
            }
            final article = results[index];
            return HelpArticleTile(
              article: article,
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening "${article.title}" — coming in F-J-5',
                      ),
                    ),
                  );
              },
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
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final article = filtered[index];
        return HelpArticleTile(
          article: article,
          onTap: () => onArticleTap(article),
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
