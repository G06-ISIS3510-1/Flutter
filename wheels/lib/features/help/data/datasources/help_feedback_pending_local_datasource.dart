import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../../domain/entities/help_feedback.dart';
import '../models/help_feedback_model.dart';

HelpFeedbackModel _decodeFeedback(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Stored help feedback payload is invalid.');
  }
  return HelpFeedbackModel.fromJson(Map<String, dynamic>.from(decoded));
}

String _encodeFeedback(HelpFeedbackModel model) {
  return jsonEncode(model.toJson());
}

/// Queue of help-article feedback votes that still have to reach Firestore.
/// `HelpFeedbackSyncWorker` (F-J-6) drains this box on reconnect.
class HelpFeedbackPendingLocalDataSource {
  const HelpFeedbackPendingLocalDataSource();

  Future<void> enqueue(HelpFeedback feedback) async {
    final encoded = await compute(
      _encodeFeedback,
      HelpFeedbackModel.fromEntity(feedback),
    );
    final box = Hive.box<String>(AppHiveBoxes.helpFeedbackPending);
    await box.put(feedback.id, encoded);
  }

  Future<List<HelpFeedback>> loadPending() async {
    final box = Hive.box<String>(AppHiveBoxes.helpFeedbackPending);
    if (box.isEmpty) {
      return const <HelpFeedback>[];
    }

    final items = <HelpFeedbackModel>[];
    final keysToDrop = <String>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }
      try {
        items.add(await compute(_decodeFeedback, raw));
      } catch (_) {
        keysToDrop.add(key.toString());
      }
    }
    if (keysToDrop.isNotEmpty) {
      await box.deleteAll(keysToDrop);
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items.map((m) => m.toEntity()).toList(growable: false);
  }

  Future<void> remove(String feedbackId) async {
    final box = Hive.box<String>(AppHiveBoxes.helpFeedbackPending);
    await box.delete(feedbackId);
  }

  Future<int> get pendingCount async {
    final box = Hive.box<String>(AppHiveBoxes.helpFeedbackPending);
    return box.length;
  }
}
