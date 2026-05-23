import '../entities/auth_entity.dart';

abstract class AuthRepository {
  const AuthRepository();

  Future<AuthEntity> registerWithUniversityEmail({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required String role,
  });

  Future<AuthEntity> signInWithUniversityEmail({
    required String username,
    required String password,
  });

  Future<AuthEntity?> restoreSession();

  Stream<AuthEntity?> watchSession();

  Future<void> signOut();
}
