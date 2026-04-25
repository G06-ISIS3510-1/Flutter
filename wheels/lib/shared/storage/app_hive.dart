import 'package:hive_flutter/hive_flutter.dart';

class AppHiveBoxes {
  static const String rideDetailsCache = 'ride_details_cache_box_v1';
  static const String dashboardCache = 'dashboard_cache_box_v1';
  static const String createRideDrafts = 'create_ride_drafts_box_v1';
}

class AppHiveKeys {
  static const String latestRideDetails = 'latest_ride_details';
  static const String latestDashboard = 'latest_dashboard';
}

Future<void> initializeAppHive() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(AppHiveBoxes.rideDetailsCache);
  await Hive.openBox<String>(AppHiveBoxes.dashboardCache);
  await Hive.openBox<String>(AppHiveBoxes.createRideDrafts);
}
