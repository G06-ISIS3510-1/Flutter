import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/auth_entity.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthService {
  const AuthService({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<AuthEntity> registerWithUniversityEmail({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    required String role,
  }) async {
    final email = buildUniversityEmail(username);
    final fullName = '$firstName $lastName'.trim();
    firebase_auth.User? createdUser;

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthFailure(
          'We could not create your account. Please try again.',
        );
      }

      await _firestore.collection('users').doc(createdUser.uid).set({
        'fullName': fullName,
        'email': email,
        'role': role,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AuthEntity(
        uid: createdUser.uid,
        email: email,
        role: role,
        fullName: fullName,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseAuthError(error));
    } on FirebaseException {
      if (createdUser != null) {
        await createdUser.delete();
      }
      throw const AuthFailure(
        'Your account could not be saved right now. Please try again.',
      );
    }
  }

  Future<AuthEntity> signInWithUniversityEmail({
    required String username,
    required String password,
  }) async {
    final email = buildUniversityEmail(username);

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'We could not sign you in right now. Please try again.',
        );
      }

      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};

      return AuthEntity(
        uid: user.uid,
        email: email,
        role: (data['role'] as String?) ?? 'passenger',
        fullName: (data['fullName'] as String?) ?? '',
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseAuthError(error));
    }
  }

  Future<AuthEntity?> restoreSession() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      await currentUser.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser == null) {
        return null;
      }

      return _buildAuthEntityFromUser(refreshedUser);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (_invalidSessionCodes.contains(error.code)) {
        await _firebaseAuth.signOut();
        return null;
      }
      throw AuthFailure(_mapFirebaseAuthError(error));
    }
  }

  Stream<AuthEntity?> watchSession() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }

      try {
        return await _buildAuthEntityFromUser(user);
      } on AuthFailure {
        return AuthEntity(
          uid: user.uid,
          email: user.email ?? '',
          role: 'passenger',
          fullName: user.displayName ?? '',
        );
      }
    });
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<AuthEntity> _buildAuthEntityFromUser(firebase_auth.User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};

    return AuthEntity(
      uid: user.uid,
      email: user.email ?? '',
      role: (data['role'] as String?) ?? 'passenger',
      fullName: (data['fullName'] as String?) ?? user.displayName ?? '',
    );
  }

  static const Set<String> _invalidSessionCodes = <String>{
    'user-disabled',
    'user-not-found',
    'invalid-user-token',
    'user-token-expired',
  };

  String _mapFirebaseAuthError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That Uniandes email is already registered.';
      case 'invalid-email':
        return 'That university email is not valid.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your username or password is incorrect.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
}
