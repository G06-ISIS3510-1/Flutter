import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/trust/data/models/local_trust_cache_model.dart';
import 'package:wheels/features/trust/data/models/trust_model.dart';

void main() {
  TrustModel buildTrust({String userId = 'user-1', int score = 86}) {
    return TrustModel(
      userId: userId,
      role: 'passenger',
      accountCreatedAt: DateTime.utc(2026, 1, 1),
      totalRides: 4,
      completedRides: 4,
      cancelledRides: 0,
      activeRides: 0,
      totalPayments: 3,
      approvedPayments: 3,
      pendingPayments: 0,
      failedPayments: 0,
      score: score,
      rewardPoints: 49,
    );
  }

  group('LocalTrustCacheModel', () {
    test('round-trips through json and restores the trust score', () {
      final cache = LocalTrustCacheModel.create(
        userId: 'user-1',
        trust: buildTrust(),
      );

      final restored = LocalTrustCacheModel.fromJson(cache.toJson());

      expect(restored.version, LocalTrustCacheModel.currentVersion);
      expect(restored.userId, 'user-1');
      expect(restored.toEntity().score, 86);
      expect(restored.toEntity().approvedPayments, 3);
    });

    test('matchesUser validates both the cache owner and payload user', () {
      final cache = LocalTrustCacheModel.create(
        userId: 'user-42',
        trust: buildTrust(userId: 'user-42'),
      );

      expect(cache.matchesUser('user-42'), isTrue);
      expect(cache.matchesUser('other-user'), isFalse);
    });

    test(
      'create assigns the cache owner when remote payload has no user id',
      () {
        final cache = LocalTrustCacheModel.create(
          userId: 'signed-in-user',
          trust: buildTrust(userId: ''),
        );

        expect(cache.matchesUser('signed-in-user'), isTrue);
        expect(cache.toEntity().userId, 'signed-in-user');
      },
    );

    test('isExpired returns true for old cache entries', () {
      final cache = LocalTrustCacheModel(
        version: LocalTrustCacheModel.currentVersion,
        userId: 'user-old',
        savedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        trust: buildTrust(userId: 'user-old'),
      );

      expect(cache.isExpired(), isTrue);
    });

    test('isExpired returns false for recent cache entries', () {
      final cache = LocalTrustCacheModel(
        version: LocalTrustCacheModel.currentVersion,
        userId: 'user-fresh',
        savedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        trust: buildTrust(userId: 'user-fresh'),
      );

      expect(cache.isExpired(), isFalse);
    });
  });
}
