import 'dart:isolate';
import 'dart:math' as math;

import '../../domain/entities/saved_destination.dart';

class DistanceBatchIsolate {
  const DistanceBatchIsolate();

  Future<Map<int, double>> computeDistances({
    required double currentLatitude,
    required double currentLongitude,
    required List<SavedDestination> destinations,
  }) async {
    if (destinations.isEmpty) {
      return const <int, double>{};
    }

    final receivePort = ReceivePort();
    await Isolate.spawn<_DistanceBatchMessage>(
      _distanceBatchEntryPoint,
      _DistanceBatchMessage(
        sendPort: receivePort.sendPort,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        destinations: destinations
            .where((destination) => destination.localId != null)
            .map(
              (destination) => <String, Object>{
                'id': destination.localId!,
                'lat': destination.latitude,
                'lng': destination.longitude,
              },
            )
            .toList(growable: false),
      ),
    );

    final message = await receivePort.first;
    receivePort.close();

    final rawResults = (message as Map<Object?, Object?>)
        .cast<int, double>();
    return rawResults;
  }
}

class _DistanceBatchMessage {
  const _DistanceBatchMessage({
    required this.sendPort,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.destinations,
  });

  final SendPort sendPort;
  final double currentLatitude;
  final double currentLongitude;
  final List<Map<String, Object>> destinations;
}

void _distanceBatchEntryPoint(_DistanceBatchMessage message) {
  final results = <int, double>{};
  for (final destination in message.destinations) {
    final id = destination['id'] as int;
    final latitude = (destination['lat'] as num).toDouble();
    final longitude = (destination['lng'] as num).toDouble();
    results[id] = _haversineKm(
      message.currentLatitude,
      message.currentLongitude,
      latitude,
      longitude,
    );
  }
  message.sendPort.send(results);
}

double _haversineKm(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const earthRadiusKm = 6371.0;
  final deltaLatitude = _toRadians(endLatitude - startLatitude);
  final deltaLongitude = _toRadians(endLongitude - startLongitude);
  final startLatRadians = _toRadians(startLatitude);
  final endLatRadians = _toRadians(endLatitude);

  final a =
      math.pow(math.sin(deltaLatitude / 2), 2).toDouble() +
      math.cos(startLatRadians) *
          math.cos(endLatRadians) *
          math.pow(math.sin(deltaLongitude / 2), 2).toDouble();
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * (math.pi / 180.0);
