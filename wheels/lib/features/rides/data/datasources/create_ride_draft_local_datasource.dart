import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../models/local_create_ride_draft_model.dart';

LocalCreateRideDraftModel _decodeCreateRideDraft(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Stored create ride draft is invalid.');
  }

  return LocalCreateRideDraftModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeCreateRideDraft(LocalCreateRideDraftModel draft) {
  return jsonEncode(draft.toJson());
}

class CreateRideDraftLocalDataSource {
  static const String _draftKeyPrefix = 'create_ride_draft';

  Future<LocalCreateRideDraftModel?> loadDraft({required String cacheId}) async {
    final box = Hive.box<String>(AppHiveBoxes.createRideDrafts);
    final rawDraft = box.get(_buildKey(cacheId));
    if (rawDraft == null || rawDraft.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodeCreateRideDraft, rawDraft);
    } catch (_) {
      await clearDraft(cacheId: cacheId);
      return null;
    }
  }

  Future<void> saveDraft({
    required String cacheId,
    required LocalCreateRideDraftModel draft,
  }) async {
    final encoded = await compute(_encodeCreateRideDraft, draft);
    final box = Hive.box<String>(AppHiveBoxes.createRideDrafts);
    await box.put(_buildKey(cacheId), encoded);
  }

  Future<void> clearDraft({required String cacheId}) async {
    final box = Hive.box<String>(AppHiveBoxes.createRideDrafts);
    await box.delete(_buildKey(cacheId));
  }

  String _buildKey(String cacheId) {
    return '$_draftKeyPrefix:$cacheId';
  }
}
