class AuthEntity {
  const AuthEntity({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
  });

  final String uid;
  final String email;
  final String role;
  final String fullName;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
