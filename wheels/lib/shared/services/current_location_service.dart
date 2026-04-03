import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CurrentLocationService {
  const CurrentLocationService();

  Future<String> getCurrentAddress() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const CurrentLocationException(
        'Location services are disabled on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const CurrentLocationException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const CurrentLocationException(
        'Location permission is permanently denied.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return _reverseGeocodePosition(position);
  }

  Future<String> _reverseGeocodePosition(Position position) async {
    final fallbackAddress =
        'Current location (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return await _reverseGeocodeWithHttp(position) ?? fallbackAddress;
      }

      final placemark = placemarks.first;
      final friendlyAddress = _buildFriendlyAddress(placemark);
      if (friendlyAddress != null && _isFriendlyAddress(friendlyAddress)) {
        return friendlyAddress;
      }

      final parts = <String?>[
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
        placemark.country,
      ].whereType<String>().map((part) => part.trim()).where((part) {
        return part.isNotEmpty;
      }).toList();

      if (parts.isEmpty) {
        return await _reverseGeocodeWithHttp(position) ?? fallbackAddress;
      }

      final joinedAddress = parts.toSet().join(', ');
      if (_isFriendlyAddress(joinedAddress)) {
        return joinedAddress;
      }

      return await _reverseGeocodeWithHttp(position) ?? joinedAddress;
    } catch (_) {
      return await _reverseGeocodeWithHttp(position) ?? fallbackAddress;
    }
  }

  Future<String?> _reverseGeocodeWithHttp(Position position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'es',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Referer': 'https://wheels-fd8c0.firebaseapp.com/',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final address = Map<String, dynamic>.from(
        payload['address'] as Map<String, dynamic>? ?? <String, dynamic>{},
      );

      final preciseAddress = _buildAddressFromNominatim(address);
      if (preciseAddress != null && _isFriendlyAddress(preciseAddress)) {
        return preciseAddress;
      }

      final displayName = _normalizeAddress(payload['display_name'] as String?);
      if (displayName == null) {
        return null;
      }

      return displayName
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .take(2)
          .join(', ');
    } catch (_) {
      return null;
    }
  }

  String? _buildAddressFromNominatim(Map<String, dynamic> address) {
    final road = _normalizeAddress(
      address['road'] as String? ??
          address['pedestrian'] as String? ??
          address['footway'] as String? ??
          address['residential'] as String?,
    );
    final houseNumber = _normalizeAddress(address['house_number'] as String?);
    final suburb = _normalizeAddress(
      address['suburb'] as String? ?? address['neighbourhood'] as String?,
    );

    if (road != null && houseNumber != null) {
      return _normalizeColombianAddress('$road #$houseNumber');
    }

    if (road != null) {
      return _normalizeColombianAddress(
        suburb == null ? road : '$road, $suburb',
      );
    }

    return null;
  }

  String? _buildFriendlyAddress(Placemark placemark) {
    final streetAddress = _joinAddressParts(
      placemark.thoroughfare,
      placemark.subThoroughfare,
    );
    final normalizedStreet = _normalizeAddress(placemark.street);
    final normalizedName = _normalizeAddress(placemark.name);

    final candidates = <String>[
      ?streetAddress,
      ?normalizedStreet,
      ?normalizedName,
    ];

    for (final candidate in candidates) {
      if (_looksLikePreciseAddress(candidate)) {
        return candidate;
      }
    }

    return _joinAddressParts(
      normalizedStreet ?? normalizedName,
      placemark.subLocality,
    );
  }

  String? _joinAddressParts(String? first, String? second) {
    final normalizedFirst = _normalizeAddress(first);
    final normalizedSecond = _normalizeAddress(second);

    final parts = <String>[
      ?normalizedFirst,
      ?normalizedSecond,
    ];

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' ');
  }

  String? _normalizeAddress(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String _normalizeColombianAddress(String value) {
    return value
        .replaceAll(RegExp(r'\bCl\.?\b', caseSensitive: false), 'Calle')
        .replaceAll(RegExp(r'\bCra\.?\b', caseSensitive: false), 'Carrera')
        .replaceAll(RegExp(r'\bAv\.?\b', caseSensitive: false), 'Avenida')
        .replaceAll(RegExp(r'\s+#\s+'), ' #')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikePreciseAddress(String value) {
    final compact = value.trim();
    return compact.contains(RegExp(r'\d')) && !compact.contains(',');
  }

  bool _isFriendlyAddress(String? value) {
    if (value == null) {
      return false;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.startsWith('Current location')) {
      return false;
    }

    if (normalized.toLowerCase().contains('unnamed road')) {
      return false;
    }

    return true;
  }
}

class CurrentLocationException implements Exception {
  const CurrentLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
