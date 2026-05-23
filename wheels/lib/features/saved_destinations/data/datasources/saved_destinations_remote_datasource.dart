import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saved_destination_model.dart';

class SavedDestinationsRemoteDataSource {
  const SavedDestinationsRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_destinations');
  }

  Future<String> upsertDestination(SavedDestinationModel destination) async {
    final collection = _collection(destination.userId);
    final document = destination.remoteId == null
        ? collection.doc()
        : collection.doc(destination.remoteId);
    await document.set(
      destination.toRemoteJson().cast<String, dynamic>(),
      SetOptions(merge: true),
    );
    return document.id;
  }

  Future<void> deleteDestination({
    required String userId,
    required String remoteId,
  }) async {
    await _collection(userId).doc(remoteId).delete();
  }
}
