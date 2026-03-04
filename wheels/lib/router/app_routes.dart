class AppRoutes {
  static const login = '/';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  static const createRide = '/create-ride';
  static const rides = '/rides';
  static const activeRide = '/active-ride';
  static const group = '/group/:rideId';
  static const payment = '/payment';
  static const profile = '/profile';
  static const trust = '/trust';
  static const reviews = '/reviews';

  static String groupByRideId(String rideId) => '/group/$rideId';
}
