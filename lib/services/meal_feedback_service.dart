import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/meal_feedback.dart';

class MealFeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFeedback(MealFeedback feedback) async {
    await _firestore
        .collection('hostels')
        .doc(feedback.hostelId)
        .collection('feedback')
        .add(feedback.toFirestore());
  }

  Stream<List<MealFeedback>> getRecentFeedbackStream(
    String hostelId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('feedback')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MealFeedback.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<double> getAverageRatingForMonth(
    String hostelId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection('feedback')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
            .get();

    if (snapshot.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
    }

    return totalRating / snapshot.docs.length;
  }
}
