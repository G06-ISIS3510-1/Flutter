import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum UserRole { passenger, driver }

final firebaseReadyProvider = Provider<bool>((ref) => true);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
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
  return 'Firebase Authentication ready';
});

final authStepProvider = StateProvider<int>((ref) => 0);
final currentUserRoleProvider = StateProvider<UserRole>(
  (ref) => UserRole.passenger,
);
final authUserProvider = StateProvider<AuthEntity?>((ref) => null);

final isDriverProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider) == UserRole.driver,
);
final isPassengerProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider) == UserRole.passenger,
);
