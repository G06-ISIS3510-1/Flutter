import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum UserRole { passenger, driver }

final firebaseReadyProvider = Provider<bool>((ref) => true);

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    analytics: ref.watch(firebaseAnalyticsProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(
      authService: ref.watch(authServiceProvider),
    ),
  );
});

final authStatusProvider = Provider<String>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return 'Not signed in';
  }
  return 'Signed in as ${user.email}';
});

final authStepProvider = StateProvider<int>((ref) => 0);
final currentUserRoleProvider = StateProvider<UserRole>(
  (ref) => UserRole.passenger,
);
final authUserProvider = StateProvider<AuthEntity?>((ref) => null);
final authSessionReadyProvider = StateProvider<bool>((ref) => false);

final isDriverProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider) == UserRole.driver,
);
final isPassengerProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider) == UserRole.passenger,
);

final authSessionStreamProvider = StreamProvider<AuthEntity?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authUserProvider) != null,
);

final authSessionControllerProvider = Provider<AuthSessionController>((ref) {
  return AuthSessionController(ref);
});

class AuthSessionController {
  const AuthSessionController(this._ref);

  final Ref _ref;

  Future<void> restoreSession() async {
    try {
      final authEntity = await _ref
          .read(authRepositoryProvider)
          .restoreSession();
      _syncState(authEntity);
    } finally {
      _ref.read(authSessionReadyProvider.notifier).state = true;
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    _syncState(null);
  }

  void syncFromStream(AuthEntity? authEntity) {
    _syncState(authEntity);
  }

  void _syncState(AuthEntity? authEntity) {
    _ref.read(authUserProvider.notifier).state = authEntity;
    _ref.read(currentUserRoleProvider.notifier).state =
        authEntity?.role == 'driver' ? UserRole.driver : UserRole.passenger;
    _ref.read(authStepProvider.notifier).state = authEntity == null ? 0 : 1;
  }
}
