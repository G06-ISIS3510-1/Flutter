import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../models/local_withdrawal_request_draft_model.dart';

LocalWithdrawalRequestDraftModel _decodeWithdrawalDraft(String rawCache) {
  final decoded = jsonDecode(rawCache);
  if (decoded is! Map) {
    throw const FormatException('Stored withdrawal draft is invalid.');
  }

  return LocalWithdrawalRequestDraftModel.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String _encodeWithdrawalDraft(LocalWithdrawalRequestDraftModel draft) {
  return jsonEncode(draft.toJson());
}

class WithdrawalRequestDraftLocalDataSource {
  const WithdrawalRequestDraftLocalDataSource();

  Future<LocalWithdrawalRequestDraftModel?> loadDraft({
    required String cacheId,
  }) async {
    final box = Hive.box<String>(AppHiveBoxes.withdrawalRequestDrafts);
    final rawCache = box.get(cacheId);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodeWithdrawalDraft, rawCache);
    } catch (_) {
      await clearDraft(cacheId: cacheId);
      return null;
    }
  }

  Future<void> saveDraft({
    required String cacheId,
    required LocalWithdrawalRequestDraftModel draft,
  }) async {
    final encoded = await compute(_encodeWithdrawalDraft, draft);
    final box = Hive.box<String>(AppHiveBoxes.withdrawalRequestDrafts);
    await box.put(cacheId, encoded);
  }

  Future<void> clearDraft({required String cacheId}) async {
    final box = Hive.box<String>(AppHiveBoxes.withdrawalRequestDrafts);
    await box.delete(cacheId);
  }
}
