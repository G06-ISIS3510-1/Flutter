import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_payment_verification_cache_model.dart';

class PaymentLocalDataSource {
  static const String _cacheKeyPrefix = 'payment_verification_pending_v1';

  String _cacheKey(String rideId, String passengerId) {
    return '$_cacheKeyPrefix::$rideId::$passengerId';
  }

  Future<LocalPaymentVerificationCacheModel?> loadPendingVerification({
    required String rideId,
    required String passengerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_cacheKey(rideId, passengerId));
    if (rawCache == null || rawCache.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! Map) {
        throw const FormatException('Stored payment verification cache is invalid.');
      }

      return LocalPaymentVerificationCacheModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      await clearPendingVerification(rideId: rideId, passengerId: passengerId);
      return null;
    }
  }

  Future<void> savePendingVerification(
    LocalPaymentVerificationCacheModel cache,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(cache.rideId, cache.passengerId),
      jsonEncode(cache.toJson()),
    );
  }

  Future<void> clearPendingVerification({
    required String rideId,
    required String passengerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(rideId, passengerId));
  }
}
