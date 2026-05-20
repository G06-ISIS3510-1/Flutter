import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../../domain/entities/help_article.dart';
import '../../domain/entities/help_feedback.dart';
import '../models/help_article_model.dart';
import '../models/help_bookmark_model.dart';

const String _seedVersionKey = '__seed_corpus_version__';

HelpArticleModel _decodeArticle(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Stored help article payload is invalid.');
  }
  return HelpArticleModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeArticle(HelpArticleModel model) {
  return jsonEncode(model.toJson());
}

Map<String, String> _encodeArticleBatch(List<HelpArticleModel> models) {
  final result = <String, String>{};
  for (final model in models) {
    result[model.id] = jsonEncode(model.toJson());
  }
  return result;
}

HelpBookmarkModel _decodeBookmark(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Stored help bookmark payload is invalid.');
  }
  return HelpBookmarkModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeBookmark(HelpBookmarkModel model) {
  return jsonEncode(model.toJson());
}

class HelpLocalDataSource {
  HelpLocalDataSource()
    : _articlesController = StreamController<List<HelpArticle>>.broadcast() {
    _articlesController.onListen = () => _emitArticlesNow();
  }

  final StreamController<List<HelpArticle>> _articlesController;
  final Map<String, StreamController<List<HelpBookmark>>> _bookmarkControllers =
      <String, StreamController<List<HelpBookmark>>>{};

  Stream<List<HelpArticle>> watchArticles() => _articlesController.stream;

  Future<List<HelpArticle>> loadArticles() async {
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    final List<HelpArticleModel> articles = <HelpArticleModel>[];
    final keysToDrop = <String>[];

    for (final key in box.keys) {
      if (key == _seedVersionKey) {
        continue;
      }
      final raw = box.get(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }
      try {
        final model = await compute(_decodeArticle, raw);
        articles.add(model);
      } catch (_) {
        keysToDrop.add(key.toString());
      }
    }

    if (keysToDrop.isNotEmpty) {
      await box.deleteAll(keysToDrop);
    }

    articles.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return articles.map((m) => m.toEntity()).toList(growable: false);
  }

  Future<HelpArticle?> getArticle(String articleId) async {
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    final raw = box.get(articleId);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final model = await compute(_decodeArticle, raw);
      return model.toEntity();
    } catch (_) {
      await box.delete(articleId);
      return null;
    }
  }

  Future<void> upsertArticle(HelpArticle article) async {
    final encoded = await compute(
      _encodeArticle,
      HelpArticleModel.fromEntity(article),
    );
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    await box.put(article.id, encoded);
    await _emitArticlesNow();
  }

  Future<void> upsertArticles(List<HelpArticle> articles) async {
    if (articles.isEmpty) {
      return;
    }
    final models = articles.map(HelpArticleModel.fromEntity).toList();
    final encoded = await compute(_encodeArticleBatch, models);
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    await box.putAll(encoded);
    await _emitArticlesNow();
  }

  Future<void> deleteArticle(String articleId) async {
    final box = Hive.box<String>(AppHiveBoxes.helpArticles);
    await box.delete(articleId);
    await _emitArticlesNow();
  }

  Stream<List<HelpBookmark>> watchBookmarks(String userId) {
    return _bookmarkControllerFor(userId).stream;
  }

  Future<List<HelpBookmark>> loadBookmarks(String userId) async {
    final box = Hive.box<String>(AppHiveBoxes.helpBookmarks);
    final prefix = _bookmarkKeyPrefix(userId);
    final bookmarks = <HelpBookmarkModel>[];
    final keysToDrop = <String>[];

    for (final key in box.keys) {
      final keyString = key.toString();
      if (!keyString.startsWith(prefix)) {
        continue;
      }
      final raw = box.get(keyString);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }
      try {
        final model = await compute(_decodeBookmark, raw);
        bookmarks.add(model);
      } catch (_) {
        keysToDrop.add(keyString);
      }
    }

    if (keysToDrop.isNotEmpty) {
      await box.deleteAll(keysToDrop);
    }

    bookmarks.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return bookmarks.map((m) => m.toEntity()).toList(growable: false);
  }

  Future<bool> isBookmarked({
    required String userId,
    required String articleId,
  }) async {
    final box = Hive.box<String>(AppHiveBoxes.helpBookmarks);
    final raw = box.get(_bookmarkKey(userId: userId, articleId: articleId));
    return raw != null && raw.trim().isNotEmpty;
  }

  Future<void> upsertBookmark(HelpBookmark bookmark) async {
    final encoded = await compute(
      _encodeBookmark,
      HelpBookmarkModel.fromEntity(bookmark),
    );
    final box = Hive.box<String>(AppHiveBoxes.helpBookmarks);
    await box.put(
      _bookmarkKey(userId: bookmark.userId, articleId: bookmark.articleId),
      encoded,
    );
    await _emitBookmarksNow(bookmark.userId);
  }

  Future<void> deleteBookmark({
    required String userId,
    required String articleId,
  }) async {
    final box = Hive.box<String>(AppHiveBoxes.helpBookmarks);
    await box.delete(_bookmarkKey(userId: userId, articleId: articleId));
    await _emitBookmarksNow(userId);
  }

  Future<void> _emitArticlesNow() async {
    if (_articlesController.isClosed) {
      return;
    }
    final entities = await loadArticles();
    if (_articlesController.isClosed) {
      return;
    }
    _articlesController.add(entities);
  }

  Future<void> _emitBookmarksNow(String userId) async {
    final controller = _bookmarkControllers[userId];
    if (controller == null || controller.isClosed) {
      return;
    }
    final entries = await loadBookmarks(userId);
    if (controller.isClosed) {
      return;
    }
    controller.add(entries);
  }

  StreamController<List<HelpBookmark>> _bookmarkControllerFor(String userId) {
    var controller = _bookmarkControllers[userId];
    if (controller == null) {
      controller = StreamController<List<HelpBookmark>>.broadcast(
        onListen: () => _emitBookmarksNow(userId),
        onCancel: () {
          final c = _bookmarkControllers[userId];
          if (c != null && !c.hasListener) {
            _bookmarkControllers.remove(userId);
            c.close();
          }
        },
      );
      _bookmarkControllers[userId] = controller;
    }
    return controller;
  }

  String _bookmarkKey({required String userId, required String articleId}) {
    return '${_bookmarkKeyPrefix(userId)}$articleId';
  }

  String _bookmarkKeyPrefix(String userId) => 'bookmark:$userId:';

  Future<void> dispose() async {
    if (!_articlesController.isClosed) {
      await _articlesController.close();
    }
    for (final controller in _bookmarkControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _bookmarkControllers.clear();
  }
}
