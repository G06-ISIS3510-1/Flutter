import '../../domain/entities/auth_entity.dart';
import '../services/auth_service.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  Future<AuthEntity> registerWithUniversityEmail({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required String role,
  }) async {
    return _authService.registerWithUniversityEmail(
      firstName: firstName,
      lastName: lastName,
      username: username,
      password: password,
      role: role,
    );
  }

  Future<AuthEntity> signInWithUniversityEmail({
    required String username,
    required String password,
  }) async {
    return _authService.signInWithUniversityEmail(
      username: username,
      password: password,
    );
  }

  Future<AuthEntity?> restoreSession() async {
    return _authService.restoreSession();
  }

  Stream<AuthEntity?> watchSession() {
    return _authService.watchSession();
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}

String buildUniversityEmail(String username) {
  return '${username.trim()}@uniandes.edu.co';
}
