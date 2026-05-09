import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rideConversionAnalyticsAdminServiceProvider =
    Provider<RideConversionAnalyticsAdminService>((ref) {
      return RideConversionAnalyticsAdminService(FirebaseFirestore.instance);
    });

final rideConversionSummaryProvider = StreamProvider<RideConversionSummary?>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('analytics')
      .doc('ride_conversion_summary')
      .snapshots()
      .map(RideConversionSummary.fromSnapshot);
});

final rideConversionRoutesProvider =
    StreamProvider<List<RideConversionRouteSummary>>((ref) {
      return FirebaseFirestore.instance
          .collection('ride_conversion_routes')
          .orderBy('completedRides', descending: true)
          .limit(8)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(RideConversionRouteSummary.fromSnapshot)
                .toList(),
          );
    });

class RideConversionSummary {
  const RideConversionSummary({
    required this.totalPublishedRides,
    required this.openRides,
    required this.inProgressRides,
    required this.completedRides,
    required this.cancelledRides,
    this.updatedAt,
  });

  final int totalPublishedRides;
  final int openRides;
  final int inProgressRides;
  final int completedRides;
  final int cancelledRides;
  final DateTime? updatedAt;

  double get completionRate => totalPublishedRides == 0
      ? 0
      : completedRides / totalPublishedRides;

  double get cancellationRate => totalPublishedRides == 0
      ? 0
      : cancelledRides / totalPublishedRides;

  factory RideConversionSummary.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return RideConversionSummary(
      totalPublishedRides: _readInt(data['totalPublishedRides']),
      openRides: _readInt(data['openRides']),
      inProgressRides: _readInt(data['inProgressRides']),
      completedRides: _readInt(data['completedRides']),
      cancelledRides: _readInt(data['cancelledRides']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }
}

class RideConversionRouteSummary {
  const RideConversionRouteSummary({
    required this.routeKey,
    required this.routeLabel,
    required this.origin,
    required this.destination,
    required this.totalPublishedRides,
    required this.openRides,
    required this.inProgressRides,
    required this.completedRides,
    required this.cancelledRides,
    this.updatedAt,
  });

  final String routeKey;
  final String routeLabel;
  final String origin;
  final String destination;
  final int totalPublishedRides;
  final int openRides;
  final int inProgressRides;
  final int completedRides;
  final int cancelledRides;
  final DateTime? updatedAt;

  double get completionRate => totalPublishedRides == 0
      ? 0
      : completedRides / totalPublishedRides;

  factory RideConversionRouteSummary.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return RideConversionRouteSummary(
      routeKey: (data['routeKey'] as String?) ?? snapshot.id,
      routeLabel: (data['routeLabel'] as String?) ?? 'Unknown route',
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      totalPublishedRides: _readInt(data['totalPublishedRides']),
      openRides: _readInt(data['openRides']),
      inProgressRides: _readInt(data['inProgressRides']),
      completedRides: _readInt(data['completedRides']),
      cancelledRides: _readInt(data['cancelledRides']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }
}

int _readInt(Object? rawValue) {
  if (rawValue is num) {
    return rawValue.toInt();
  }
  return 0;
}

DateTime? _readDateTime(Object? rawValue) {
  if (rawValue is Timestamp) {
    return rawValue.toDate();
  }
  return null;
}

class RideConversionAnalyticsAdminService {
  const RideConversionAnalyticsAdminService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> rebuildAnalytics() async {
    final ridesSnapshot = await _firestore.collection('rides').get();
    final existingRoutesSnapshot = await _firestore
        .collection('ride_conversion_routes')
        .get();

    var totalPublishedRides = 0;
    var openRides = 0;
    var inProgressRides = 0;
    var completedRides = 0;
    var cancelledRides = 0;
    final routeSummaries = <String, Map<String, dynamic>>{};

    for (final rideDoc in ridesSnapshot.docs) {
      final data = rideDoc.data();
      final origin = (data['origin'] as String?)?.trim() ?? '';
      final destination = (data['destination'] as String?)?.trim() ?? '';
      final status = ((data['status'] as String?) ?? 'open').trim().toLowerCase();
      final routeKey = _routeKey(origin, destination);
      final routeLabel = '$origin -> $destination';

      totalPublishedRides += 1;
      switch (status) {
        case 'completed':
          completedRides += 1;
          break;
        case 'cancelled':
          cancelledRides += 1;
          break;
        case 'in_progress':
          inProgressRides += 1;
          break;
        case 'open':
        default:
          openRides += 1;
          break;
      }

      final routeSummary = routeSummaries.putIfAbsent(routeKey, () {
        return <String, dynamic>{
          'routeKey': routeKey,
          'routeLabel': routeLabel,
          'origin': origin,
          'destination': destination,
          'totalPublishedRides': 0,
          'openRides': 0,
          'inProgressRides': 0,
          'completedRides': 0,
          'cancelledRides': 0,
        };
      });

      routeSummary['totalPublishedRides'] =
          (routeSummary['totalPublishedRides'] as int) + 1;
      switch (status) {
        case 'completed':
          routeSummary['completedRides'] =
              (routeSummary['completedRides'] as int) + 1;
          break;
        case 'cancelled':
          routeSummary['cancelledRides'] =
              (routeSummary['cancelledRides'] as int) + 1;
          break;
        case 'in_progress':
          routeSummary['inProgressRides'] =
              (routeSummary['inProgressRides'] as int) + 1;
          break;
        case 'open':
        default:
          routeSummary['openRides'] = (routeSummary['openRides'] as int) + 1;
          break;
      }
    }

    final operations = <void Function(WriteBatch)>[
      (batch) => batch.set(
        _firestore.collection('analytics').doc('ride_conversion_summary'),
        <String, dynamic>{
          'question':
              'What percentage of published rides end up being completed?',
          'totalPublishedRides': totalPublishedRides,
          'openRides': openRides,
          'inProgressRides': inProgressRides,
          'completedRides': completedRides,
          'cancelledRides': cancelledRides,
          'recomputedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ),
    ];

    for (final doc in existingRoutesSnapshot.docs) {
      if (!routeSummaries.containsKey(doc.id)) {
        operations.add((batch) => batch.delete(doc.reference));
      }
    }

    for (final entry in routeSummaries.entries) {
      operations.add(
        (batch) => batch.set(
          _firestore.collection('ride_conversion_routes').doc(entry.key),
          <String, dynamic>{
            ...entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        ),
      );
    }

    await _commitBatchOperations(operations);
  }

  Future<void> _commitBatchOperations(
    List<void Function(WriteBatch)> operations,
  ) async {
    if (operations.isEmpty) {
      return;
    }

    const chunkSize = 400;
    for (var start = 0; start < operations.length; start += chunkSize) {
      final batch = _firestore.batch();
      final end = (start + chunkSize > operations.length)
          ? operations.length
          : start + chunkSize;
      for (final operation in operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }
  }
}

String _routeKey(String origin, String destination) {
  final normalizedOrigin = origin.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  final normalizedDestination = destination.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  return '${normalizedOrigin}_to_$normalizedDestination';
}
