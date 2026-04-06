class AppRoutes {
  static const login = '/';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  static const createRide = '/create-ride';
  static const rides = '/rides';
  static const rideDetails = '/ride/:rideId';
  static const activeRide = '/active-ride';
  static const groupChat = '/group-chat';
  static const group = '/group/:rideId';
  static const payment = '/payment';
  static const wallet = '/wallet';
  static const withdrawalRequest = '/wallet/request-withdrawal';
  static const profile = '/profile';
  static const trust = '/trust';
  static const reviews = '/reviews';
  static const adminAnalytics = '/admin-analytics';

  static String groupByRideId(String rideId) => '/group/$rideId';
  static String groupChatByTripId(String tripId) =>
      '/group-chat?tripId=$tripId';
  static String rideDetailsById(String rideId) => '/ride/$rideId';
  static String activeRideById(String rideId) => '/active-ride?rideId=$rideId';
  static String paymentByRideId(String rideId) => '/payment?rideId=$rideId';
}
