import 'dart:math' as math;

import '../../domain/entities/help_article.dart';

/// Pure data + ranking functions used by [HelpSearchIsolate].
///
/// Kept separate from the isolate wrapper so they can be exercised on the
/// main isolate in unit tests without spawning a real worker.
///
/// Ranking pipeline:
///
/// 1. Normalize text (lowercase, strip a curated diacritics set).
/// 2. Tokenize on non-alphanumerics, drop tokens shorter than 2 chars.
/// 3. For each query token vs each article-field token bag, take the best
///    of: exact match (1.0) > prefix match (0.7) > bounded Levenshtein
///    (proportional, only for query tokens length >= 4 and distance <= 2).
/// 4. Weight by field: title x3, tags x2, summary x2, body x1.
/// 5. Sum across query tokens, sort descending, tie-break by upvotes.
/// 6. Return at most `limit` article ids.

class HelpSearchIndexData {
  const HelpSearchIndexData({required this.articles});

  final List<HelpSearchIndexedArticle> articles;
}

class HelpSearchIndexedArticle {
  const HelpSearchIndexedArticle({
    required this.id,
    required this.titleTokens,
    required this.tagTokens,
    required this.summaryTokens,
    required this.bodyTokens,
    required this.upvotes,
  });

  final String id;
  final Set<String> titleTokens;
  final Set<String> tagTokens;
  final Set<String> summaryTokens;
  final Set<String> bodyTokens;
  final int upvotes;
}

HelpSearchIndexData buildHelpSearchIndex(List<HelpArticle> articles) {
  return HelpSearchIndexData(
    articles: articles
        .map((article) => HelpSearchIndexedArticle(
              id: article.id,
              titleTokens: _tokenize(article.title),
              tagTokens: article.tags.expand(_tokenize).toSet(),
              summaryTokens: _tokenize(article.summary),
              bodyTokens: _tokenize(article.body),
              upvotes: article.upvotes,
            ))
        .toList(growable: false),
  );
}

List<String> runHelpSearchQuery(
  HelpSearchIndexData index,
  String query,
  int limit,
) {
  final queryTokens = _tokenize(query);
  if (queryTokens.isEmpty || limit <= 0) {
    return const <String>[];
  }

  final scored = <_ScoredArticle>[];
  for (final article in index.articles) {
    double score = 0;
    for (final queryToken in queryTokens) {
      score += 3.0 * _bestTokenScore(queryToken, article.titleTokens);
      score += 2.0 * _bestTokenScore(queryToken, article.tagTokens);
      score += 2.0 * _bestTokenScore(queryToken, article.summaryTokens);
      score += 1.0 * _bestTokenScore(queryToken, article.bodyTokens);
    }
    if (score > 0) {
      scored.add(_ScoredArticle(
        id: article.id,
        score: score,
        upvotes: article.upvotes,
      ));
    }
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) {
      return byScore;
    }
    return b.upvotes.compareTo(a.upvotes);
  });

  final capped = scored.length > limit ? scored.sublist(0, limit) : scored;
  return capped.map((entry) => entry.id).toList(growable: false);
}

class _ScoredArticle {
  const _ScoredArticle({
    required this.id,
    required this.score,
    required this.upvotes,
  });

  final String id;
  final double score;
  final int upvotes;
}

double _bestTokenScore(String queryToken, Set<String> tokens) {
  if (tokens.contains(queryToken)) {
    return 1.0;
  }

  double best = 0;
  for (final token in tokens) {
    if (token.startsWith(queryToken)) {
      best = math.max(best, 0.7);
      continue;
    }
    if (queryToken.length >= 4 && token.length >= 4) {
      final distance = _levenshteinBounded(queryToken, token, 2);
      if (distance <= 2) {
        final maxLen = math.max(queryToken.length, token.length);
        final ratio = 1.0 - distance / maxLen;
        if (ratio > 0.6) {
          best = math.max(best, 0.5 * ratio);
        }
      }
    }
  }
  return best;
}

Set<String> _tokenize(String input) {
  final normalized = _normalize(input);
  if (normalized.isEmpty) {
    return const <String>{};
  }
  final tokens = <String>{};
  for (final raw in normalized.split(_tokenSplitter)) {
    if (raw.length >= 2) {
      tokens.add(raw);
    }
  }
  return tokens;
}

final RegExp _tokenSplitter = RegExp(r'[^a-z0-9]+');

String _normalize(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final code in lower.codeUnits) {
    final replacement = _diacriticMap[code];
    if (replacement != null) {
      buffer.write(replacement);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

const Map<int, String> _diacriticMap = <int, String>{
  0x00E1: 'a', // á
  0x00E0: 'a', // à
  0x00E2: 'a', // â
  0x00E3: 'a', // ã
  0x00E4: 'a', // ä
  0x00E5: 'a', // å
  0x00E9: 'e', // é
  0x00E8: 'e', // è
  0x00EA: 'e', // ê
  0x00EB: 'e', // ë
  0x00ED: 'i', // í
  0x00EC: 'i', // ì
  0x00EE: 'i', // î
  0x00EF: 'i', // ï
  0x00F3: 'o', // ó
  0x00F2: 'o', // ò
  0x00F4: 'o', // ô
  0x00F5: 'o', // õ
  0x00F6: 'o', // ö
  0x00FA: 'u', // ú
  0x00F9: 'u', // ù
  0x00FB: 'u', // û
  0x00FC: 'u', // ü
  0x00F1: 'n', // ñ
  0x00E7: 'c', // ç
};

/// Levenshtein with an early-exit cap. Returns `cap + 1` when the true
/// distance is known to exceed `cap` (cheaper than computing the full
/// matrix). Good enough for fuzzy-token ranking.
int _levenshteinBounded(String a, String b, int cap) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  if ((a.length - b.length).abs() > cap) {
    return cap + 1;
  }

  final m = a.length;
  final n = b.length;
  var previous = List<int>.generate(n + 1, (i) => i);
  var current = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    current[0] = i;
    var rowMin = current[0];
    for (var j = 1; j <= n; j++) {
      final substitutionCost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + substitutionCost,
      );
      if (current[j] < rowMin) {
        rowMin = current[j];
      }
    }
    if (rowMin > cap) {
      return cap + 1;
    }
    final swap = previous;
    previous = current;
    current = swap;
  }

  return previous[n];
}
