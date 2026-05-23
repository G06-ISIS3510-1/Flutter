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
  static const rideHistory = '/ride-history';
  static const helpCenter = '/help';
  static const helpArticle = '/help/article/:articleId';
  static const savedDestinations = '/saved-destinations';
  static const savedDestinationDetail =
      '/saved-destinations/:savedDestinationId';

  static String groupByRideId(String rideId) => '/group/$rideId';
  static String groupChatByTripId(String tripId) =>
      '/group-chat?tripId=$tripId';
  static String rideDetailsById(String rideId) => '/ride/$rideId';
  static String activeRideById(String rideId) => '/active-ride?rideId=$rideId';
  static String paymentByRideId(String rideId) => '/payment?rideId=$rideId';
  static String helpArticleById(String articleId) =>
      '/help/article/$articleId';
  static String savedDestinationDetailById(int savedDestinationId) =>
      '/saved-destinations/$savedDestinationId';
  static String ridesWithSavedDestination(int savedDestinationId) =>
      '/rides?savedDestinationId=$savedDestinationId&forceSavedDestination=1';
  static String createRideWithSavedDestination(int savedDestinationId) =>
      '/create-ride?savedDestinationId=$savedDestinationId&forceSavedDestination=1';
}
