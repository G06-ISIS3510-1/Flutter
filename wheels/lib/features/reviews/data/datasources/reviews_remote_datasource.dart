import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reviews_model.dart';

class ReviewsRemoteDataSource {
  ReviewsRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _firestore.collection('reviews');

  Future<ReviewsModel> fetchUserReviews({
    required String userId,
    required String fallbackFullName,
  }) async {
    //PEDIMOS REVIEWS A FIREBASE
    final snapshot = await _reviewsCollection
        .where('reviewedUserId', isEqualTo: userId)
        .get(const GetOptions(source: Source.server));

    return ReviewsModel.fromFirestore(
      userId: userId,
      fallbackFullName: fallbackFullName,
      documents: snapshot.docs,
    );
  }
}
