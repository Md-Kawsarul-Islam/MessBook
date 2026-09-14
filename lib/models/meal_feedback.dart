import 'package:cloud_firestore/cloud_firestore.dart';

class MealFeedback {
  final String? id;
  final String memberId;
  final String memberName;
  final String hostelId;
  final double rating;
  final String? comment;
  final DateTime date;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner'

  MealFeedback({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.hostelId,
    required this.rating,
    this.comment,
    required this.date,
    required this.mealType,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'hostelId': hostelId,
      'rating': rating,
      'comment': comment,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
    };
  }

  factory MealFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealFeedback(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? 'Unknown',
      hostelId: data['hostelId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'],
      date: (data['date'] as Timestamp).toDate(),
      mealType: data['mealType'] ?? 'Dinner',
    );
  }
}
