import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engagement_service.dart';

final engagementServiceProvider = Provider<EngagementService>((ref) {
  return EngagementService(
    firestore: FirebaseFirestore.instance,
    messaging: FirebaseMessaging.instance,
  );
});

final engagementSummaryProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('engagement')
          .doc('summary')
          .snapshots()
          .map((snapshot) => snapshot.data());
    });

final adminUsersProvider = StreamProvider<List<AdminUserOption>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('fullName')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(AdminUserOption.fromSnapshot)
            .where((user) => user.role != 'admin')
            .toList(),
      );
});

class AdminUserOption {
  const AdminUserOption({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String uid;
  final String fullName;
  final String email;
  final String role;

  factory AdminUserOption.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AdminUserOption(
      uid: snapshot.id,
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? data['fullName'] as String
          : 'User ${snapshot.id.substring(0, 6)}',
      email: (data['email'] as String?) ?? 'No email',
      role: (data['role'] as String?) ?? 'passenger',
    );
  }
}
