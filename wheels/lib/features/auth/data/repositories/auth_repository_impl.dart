import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl extends AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthEntity> registerWithUniversityEmail({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required String role,
  }) {
    return _remoteDataSource.registerWithUniversityEmail(
      firstName: firstName,
      lastName: lastName,
      username: username,
      password: password,
      role: role,
    );
  }

  @override
  Future<AuthEntity> signInWithUniversityEmail({
    required String username,
    required String password,
  }) {
    return _remoteDataSource.signInWithUniversityEmail(
      username: username,
      password: password,
    );
  }

  @override
  Future<AuthEntity?> restoreSession() {
    return _remoteDataSource.restoreSession();
  }

  @override
  Stream<AuthEntity?> watchSession() {
    return _remoteDataSource.watchSession();
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
