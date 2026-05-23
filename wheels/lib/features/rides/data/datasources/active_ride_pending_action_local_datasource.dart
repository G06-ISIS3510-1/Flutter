import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../shared/storage/app_hive.dart';
import '../models/local_pending_ride_status_action_model.dart';

LocalPendingRideStatusActionModel _decodePendingRideAction(String rawCache) {
  final decoded = jsonDecode(rawCache);
  if (decoded is! Map) {
    throw const FormatException('Stored pending ride action is invalid.');
  }

  return LocalPendingRideStatusActionModel.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String _encodePendingRideAction(LocalPendingRideStatusActionModel cache) {
  return jsonEncode(cache.toJson());
}

class ActiveRidePendingActionLocalDataSource {
  const ActiveRidePendingActionLocalDataSource();

  Future<LocalPendingRideStatusActionModel?> loadPendingAction({
    required String rideId,
  }) async {
    final box = Hive.box<String>(AppHiveBoxes.activeRidePendingActions);
    final rawCache = box.get(rideId);
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      return await compute(_decodePendingRideAction, rawCache);
    } catch (_) {
      await clearPendingAction(rideId: rideId);
      return null;
    }
  }

  Future<void> savePendingAction(
    LocalPendingRideStatusActionModel action,
  ) async {
    final encoded = await compute(_encodePendingRideAction, action);
    final box = Hive.box<String>(AppHiveBoxes.activeRidePendingActions);
    await box.put(action.rideId, encoded);
  }

  Future<void> clearPendingAction({required String rideId}) async {
    final box = Hive.box<String>(AppHiveBoxes.activeRidePendingActions);
    await box.delete(rideId);
  }
}
