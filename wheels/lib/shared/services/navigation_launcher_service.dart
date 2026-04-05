import 'package:url_launcher/url_launcher.dart';

class NavigationLauncherService {
  const NavigationLauncherService();

  Future<bool> openDrivingDirections({
    required String destination,
    String? origin,
  }) async {
    final cleanedDestination = destination.trim();
    if (cleanedDestination.isEmpty) {
      return false;
    }

    final queryParameters = <String, String>{
      'api': '1',
      'destination': cleanedDestination,
      'travelmode': 'driving',
      'utm_source': 'Wheels',
      'utm_campaign': 'ride_navigation',
    };

    final cleanedOrigin = origin?.trim();
    if (cleanedOrigin != null && cleanedOrigin.isNotEmpty) {
      queryParameters['origin'] = cleanedOrigin;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      queryParameters,
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
