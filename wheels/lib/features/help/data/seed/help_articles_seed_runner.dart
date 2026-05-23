import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../models/help_article_model.dart';
import 'help_articles_seed.dart';

const String _seedVersionKey = '__seed_corpus_version__';

class HelpArticlesSeedRunner {
  const HelpArticlesSeedRunner();

  Future<void> seedIfNeeded() async {
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    final storedVersion = box.get(_seedVersionKey);
    if (storedVersion == seedHelpCorpusVersion && box.length > 1) {
      return;
    }

    final encoded = await compute(
      _encodeSeedCorpus,
      buildSeedHelpArticles(),
    );

    await box.clear();
    await box.putAll(encoded);
    await box.put(_seedVersionKey, seedHelpCorpusVersion);
  }
}

Map<String, String> _encodeSeedCorpus(List<HelpArticleModel> articles) {
  final result = <String, String>{};
  for (final article in articles) {
    result[article.id] = jsonEncode(article.toJson());
  }
  return result;
}
