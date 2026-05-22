/// Aggregate result for BQ-J4: how many Help Center sessions resolved
/// without escalating to "contact support" in a rolling time window.
///
/// `rate` ranges from `0.0` (every session escalated) to `1.0` (no session
/// escalated). When `sessionsStarted == 0` the rate is undefined; the UI
/// hides the banner instead of showing a meaningless number.
class HelpResolutionRate {
  const HelpResolutionRate({
    required this.windowStart,
    required this.windowEnd,
    required this.sessionsStarted,
    required this.supportClicks,
  });

  final DateTime windowStart;
  final DateTime windowEnd;
  final int sessionsStarted;
  final int supportClicks;

  bool get hasEnoughData => sessionsStarted > 0;

  double get rate {
    if (sessionsStarted <= 0) {
      return 0;
    }
    final clamped = supportClicks.clamp(0, sessionsStarted);
    return 1 - clamped / sessionsStarted;
  }

  int get ratePercent => (rate * 100).round();

  /// Convenience for an empty window (used as a default before any events
  /// have been collected).
  factory HelpResolutionRate.empty({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    return HelpResolutionRate(
      windowStart: windowStart,
      windowEnd: windowEnd,
      sessionsStarted: 0,
      supportClicks: 0,
    );
  }
}

/// Minimal projection of a help analytics event read from Firestore. Used
/// only for the BQ-J4 compute pass — does not carry the article id or
/// session id because the resolution-rate calculation does not need them.
class HelpAnalyticsEventRecord {
  const HelpAnalyticsEventRecord({
    required this.event,
    required this.timestamp,
  });

  final String event;
  final DateTime timestamp;
}

const String helpEventSessionStarted = 'help_session_started';
const String helpEventArticleViewed = 'help_article_viewed';
const String helpEventContactSupportClicked = 'help_contact_support_clicked';

/// Pure aggregator that counts sessions and support clicks inside the
/// `[windowStart, windowEnd)` half-open interval and returns the resulting
/// [HelpResolutionRate]. Events outside the window are ignored.
HelpResolutionRate computeHelpResolutionRate({
  required Iterable<HelpAnalyticsEventRecord> events,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  var sessions = 0;
  var clicks = 0;
  for (final event in events) {
    if (event.timestamp.isBefore(windowStart)) continue;
    if (!event.timestamp.isBefore(windowEnd)) continue;
    switch (event.event) {
      case helpEventSessionStarted:
        sessions += 1;
      case helpEventContactSupportClicked:
        clicks += 1;
    }
  }
  return HelpResolutionRate(
    windowStart: windowStart,
    windowEnd: windowEnd,
    sessionsStarted: sessions,
    supportClicks: clicks,
  );
}
