import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../models/local_registration_draft_model.dart';

LocalRegistrationDraftModel _decodeRegistrationDraft(String rawDraft) {
  final decoded = jsonDecode(rawDraft);
  if (decoded is! Map) {
    throw const FormatException('Stored registration draft is invalid.');
  }

  return LocalRegistrationDraftModel.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String _encodeRegistrationDraft(LocalRegistrationDraftModel draft) {
  return jsonEncode(draft.toJson());
}

class RegistrationDraftLocalDataSource {
  const RegistrationDraftLocalDataSource();

  static const String _draftKey = 'latest_registration_draft';

  Future<LocalRegistrationDraftModel?> loadDraft() async {
    final box = Hive.box<String>(AppHiveBoxes.registrationDrafts);
    final rawDraft = box.get(_draftKey);
    if (rawDraft == null || rawDraft.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodeRegistrationDraft, rawDraft);
    } catch (_) {
      await clearDraft();
      return null;
    }
  }

  Future<void> saveDraft(LocalRegistrationDraftModel draft) async {
    if (draft.isEmpty) {
      await clearDraft();
      return;
    }

    final encoded = await compute(_encodeRegistrationDraft, draft);
    final box = Hive.box<String>(AppHiveBoxes.registrationDrafts);
    await box.put(_draftKey, encoded);
  }

  Future<void> clearDraft() async {
    final box = Hive.box<String>(AppHiveBoxes.registrationDrafts);
    await box.delete(_draftKey);
  }
}
