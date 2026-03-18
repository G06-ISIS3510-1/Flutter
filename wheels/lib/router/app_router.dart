import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/payment_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/reviews/presentation/screens/reviews_screen.dart';
import '../features/rides/presentation/screens/active_ride_screen.dart';
import '../features/rides/presentation/screens/create_ride_screen.dart';
import '../features/rides/presentation/screens/group_screen.dart';
import '../features/rides/presentation/screens/ride_details_screen.dart';
import '../features/rides/presentation/screens/rides_search_screen.dart';
import '../features/trust/presentation/screens/trust_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: firebase_auth.FirebaseAuth.instance.currentUser == null
        ? AppRoutes.login
        : AppRoutes.dashboard,
    refreshListenable: GoRouterRefreshStream(
      firebase_auth.FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context, listen: false);
      final isReady = container.read(authSessionReadyProvider);
      final isAuthenticated = container.read(isAuthenticatedProvider);
      final isDriver = container.read(isDriverProvider);
      final location = state.matchedLocation;
      final isPublicRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      if (!isReady) {
        return null;
      }

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.dashboard;
      }

      if (location == AppRoutes.createRide && !isDriver) {
        return AppRoutes.dashboard;
      }

      if (location == AppRoutes.rides && isDriver) {
        return AppRoutes.createRide;
      }

      if ((location == AppRoutes.activeRide ||
              location == AppRoutes.groupChat ||
              location.startsWith('/group/')) &&
          !isDriver) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(
          initialModeIndex: state.uri.queryParameters['mode'] == 'login'
              ? 1
              : 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRide,
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: AppRoutes.rides,
        builder: (context, state) => const RidesSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideDetails,
        builder: (context, state) => RideDetailsScreen(
          rideId: state.pathParameters['rideId'] ?? 'unknown',
        ),
      ),
      GoRoute(
        path: AppRoutes.activeRide,
        builder: (context, state) => const ActiveRideScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupChat,
        builder: (context, state) => GroupChatScreen(
          tripId: state.uri.queryParameters['tripId'] ?? 'active-trip',
        ),
      ),
      GoRoute(
        path: AppRoutes.group,
        builder: (context, state) =>
            GroupScreen(rideId: state.pathParameters['rideId'] ?? 'unknown'),
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.trust,
        builder: (context, state) => const TrustScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (context, state) => const ReviewsScreen(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
