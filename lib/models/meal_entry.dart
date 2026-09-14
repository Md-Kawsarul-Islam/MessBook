import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a daily meal entry for a specific member, including guest meals.
class MealEntry {
  String? id; // Firestore Document ID
  String memberId; // Reference to Member ID
  DateTime mealDate;
  double breakfastMeals;
  double lunchMeals;
  double dinnerMeals;
  double guestMeals;

  MealEntry({
    this.id,
    required this.memberId,
    required this.mealDate,
    this.breakfastMeals = 0.0,
    this.lunchMeals = 0.0,
    this.dinnerMeals = 0.0,
    this.guestMeals = 0.0,
  });

  /// Converts a MealEntry object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'mealDate': Timestamp.fromDate(mealDate),
      'breakfastMeals': breakfastMeals,
      'lunchMeals': lunchMeals,
      'dinnerMeals': dinnerMeals,
      'guestMeals': guestMeals,
    };
  }

  /// Creates a MealEntry object from a Firestore DocumentSnapshot.
  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MealEntry(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      mealDate: (data['mealDate'] as Timestamp).toDate(),
      breakfastMeals: (data['breakfastMeals'] as num?)?.toDouble() ?? 0.0,
      lunchMeals: (data['lunchMeals'] as num?)?.toDouble() ?? 0.0,
      dinnerMeals: (data['dinnerMeals'] as num?)?.toDouble() ?? 0.0,
      guestMeals: (data['guestMeals'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
