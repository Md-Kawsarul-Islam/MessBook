import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/utils/app_constants.dart';

/// Service class for managing meal-related data in Firestore.
class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new meal entry or updates an existing one for a specific hostel.
  Future<String> addMealEntry(MealEntry mealEntry, String hostelId) async {
    final docRef =
        _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMealEntries)
            .doc();
    // Ensure we don't accidentally write the ID if it's null,
    // though our model handles it.
    await docRef.set(mealEntry.toFirestore());
    return docRef.id;
  }

  /// Retrieves all meal entries for a specific date in a hostel.
  Future<List<MealEntry>> getMealEntriesByDate(
    DateTime date,
    String hostelId,
  ) async {
    // Create start and end of the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMealEntries)
            .where(
              'mealDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('mealDate', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    return snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList();
  }

  /// Retrieves all meal entries for a specific member in a hostel.
  Future<List<MealEntry>> getMealEntriesByMember(
    String memberId,
    String hostelId,
  ) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMealEntries)
            .where('memberId', isEqualTo: memberId)
            .orderBy('mealDate', descending: true)
            .get();

    return snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList();
  }

  /// Updates an existing meal entry in a hostel.
  Future<bool> updateMealEntry(MealEntry mealEntry, String hostelId) async {
    if (mealEntry.id == null) return false;
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionMealEntries)
          .doc(mealEntry.id)
          .update(mealEntry.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a meal entry by its ID from a hostel.
  Future<bool> deleteMealEntry(String id, String hostelId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionMealEntries)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculates the total meals for the entire mess for a given month and year in a hostel.
  Future<double> getMonthlyTotalMealsForMess(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1); // First day of next month

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionMealEntries)
              .where(
                'mealDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('mealDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['breakfastMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['lunchMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['dinnerMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['guestMeals'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculates the total meals for a specific member for a given month and year in a hostel.
  Future<double> getMonthlyTotalMealsForMember(
    String memberId,
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionMealEntries)
              .where('memberId', isEqualTo: memberId)
              .where(
                'mealDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('mealDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['breakfastMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['lunchMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['dinnerMeals'] as num?)?.toDouble() ?? 0.0;
        total += (data['guestMeals'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Retrieves all meal entries for a given month and year in a hostel.
  Future<List<MealEntry>> getMealEntriesForMonth(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionMealEntries)
              .where(
                'mealDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('mealDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .orderBy('mealDate', descending: true)
              .get();

      return snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves meal entries for a specific member for a given month and year in a hostel.
  Future<List<MealEntry>> getMemberMealEntriesForMonth(
    String memberId,
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionMealEntries)
              .where('memberId', isEqualTo: memberId)
              .where(
                'mealDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('mealDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .orderBy('mealDate', descending: true)
              .get();

      return snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
