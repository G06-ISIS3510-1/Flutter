import 'package:go_router/go_router.dart';

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
import '../features/rides/presentation/screens/rides_search_screen.dart';
import '../features/trust/presentation/screens/trust_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: <RouteBase>[
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.createRide, builder: (context, state) => const CreateRideScreen()),
      GoRoute(path: AppRoutes.rides, builder: (context, state) => const RidesSearchScreen()),
      GoRoute(path: AppRoutes.activeRide, builder: (context, state) => const ActiveRideScreen()),
      GoRoute(
        path: AppRoutes.group,
        builder: (context, state) => GroupScreen(
          rideId: state.pathParameters['rideId'] ?? 'unknown',
        ),
      ),
      GoRoute(path: AppRoutes.payment, builder: (context, state) => const PaymentScreen()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: AppRoutes.trust, builder: (context, state) => const TrustScreen()),
      GoRoute(path: AppRoutes.reviews, builder: (context, state) => const ReviewsScreen()),
    ],
  );
}
