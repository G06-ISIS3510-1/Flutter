import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/help/domain/entities/help_resolution_rate.dart';

void main() {
  final windowStart = DateTime.utc(2026, 5, 14);
  final windowEnd = DateTime.utc(2026, 5, 21);

  HelpAnalyticsEventRecord event(String name, DateTime at) {
    return HelpAnalyticsEventRecord(event: name, timestamp: at);
  }

  group('HelpResolutionRate.rate', () {
    test('is zero with no sessions and reports hasEnoughData=false', () {
      final rate = HelpResolutionRate.empty(
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(rate.hasEnoughData, isFalse);
      expect(rate.rate, 0.0);
      expect(rate.ratePercent, 0);
    });

    test('is 1.0 when every session resolved without a support click', () {
      final rate = HelpResolutionRate(
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsStarted: 10,
        supportClicks: 0,
      );
      expect(rate.rate, 1.0);
      expect(rate.ratePercent, 100);
    });

    test('is 0.0 when every session escalated', () {
      final rate = HelpResolutionRate(
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsStarted: 4,
        supportClicks: 4,
      );
      expect(rate.rate, 0.0);
      expect(rate.ratePercent, 0);
    });

    test('clamps support clicks > sessions to sessions (defensive)', () {
      final rate = HelpResolutionRate(
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsStarted: 5,
        supportClicks: 7,
      );
      // Clamped to 5/5 → rate 0.
      expect(rate.rate, 0.0);
      expect(rate.ratePercent, 0);
    });

    test('typical mixed case', () {
      final rate = HelpResolutionRate(
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessionsStarted: 100,
        supportClicks: 19,
      );
      expect(rate.rate, closeTo(0.81, 1e-9));
      expect(rate.ratePercent, 81);
    });
  });

  group('computeHelpResolutionRate', () {
    test('returns empty rate when there are no events', () {
      final rate = computeHelpResolutionRate(
        events: const <HelpAnalyticsEventRecord>[],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(rate.sessionsStarted, 0);
      expect(rate.supportClicks, 0);
      expect(rate.hasEnoughData, isFalse);
    });

    test('counts session_started and contact_support_clicked', () {
      final events = <HelpAnalyticsEventRecord>[
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 15)),
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 16)),
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 17)),
        event(helpEventContactSupportClicked, DateTime.utc(2026, 5, 17)),
      ];

      final rate = computeHelpResolutionRate(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(rate.sessionsStarted, 3);
      expect(rate.supportClicks, 1);
      expect(rate.ratePercent, 67);
    });

    test('ignores irrelevant event names', () {
      final events = <HelpAnalyticsEventRecord>[
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 15)),
        event(helpEventArticleViewed, DateTime.utc(2026, 5, 15)),
        event('some_other_event', DateTime.utc(2026, 5, 16)),
      ];

      final rate = computeHelpResolutionRate(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(rate.sessionsStarted, 1);
      expect(rate.supportClicks, 0);
      expect(rate.ratePercent, 100);
    });

    test('ignores events outside the time window', () {
      final events = <HelpAnalyticsEventRecord>[
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 13)), // before
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 21)), // ==end, excluded
        event(helpEventSessionStarted, DateTime.utc(2026, 5, 20)), // inside
        event(helpEventContactSupportClicked, DateTime.utc(2026, 5, 20)),
      ];

      final rate = computeHelpResolutionRate(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(rate.sessionsStarted, 1);
      expect(rate.supportClicks, 1);
      expect(rate.ratePercent, 0);
    });

    test('windowStart is inclusive', () {
      final events = <HelpAnalyticsEventRecord>[
        event(helpEventSessionStarted, windowStart),
      ];

      final rate = computeHelpResolutionRate(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(rate.sessionsStarted, 1);
    });
  });
}
