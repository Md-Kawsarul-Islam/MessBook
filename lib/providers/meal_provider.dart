import 'package:flutter/material.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/services/meal_service.dart';

/// Provider for managing MealEntry data.
class MealProvider with ChangeNotifier {
  final MealService _mealService;
  List<MealEntry> _mealEntries = [];
  final Map<String, double> _monthlyMemberMeals =
      {}; // memberId (String) -> total meals
  double _monthlyMessMeals = 0.0;

  MealProvider(this._mealService);

  List<MealEntry> get mealEntries => _mealEntries;
  Map<String, double> get monthlyMemberMeals => _monthlyMemberMeals;
  double get monthlyMessMeals => _monthlyMessMeals;

  /// Fetches meal entries for a specific date in a specific hostel.
  Future<void> fetchMealEntriesByDate(DateTime date, String hostelId) async {
    _mealEntries = await _mealService.getMealEntriesByDate(date, hostelId);
    notifyListeners();
  }

  /// Fetches meal entries for a specific member in a specific hostel.
  Future<List<MealEntry>> fetchMealEntriesByMember(
    String memberId,
    String hostelId,
  ) async {
    return await _mealService.getMealEntriesByMember(memberId, hostelId);
  }

  /// Adds or updates a meal entry for a specific hostel.
  Future<bool> addOrUpdateMealEntry(
    MealEntry mealEntry,
    String hostelId,
  ) async {
    final String id = await _mealService.addMealEntry(mealEntry, hostelId);
    if (id.isNotEmpty) {
      // Re-fetch data relevant to the UI that might change
      await fetchMealEntriesByDate(
        mealEntry.mealDate,
        hostelId,
      ); // Update daily view
      await calculateMonthlyMeals(
        DateTime.now().month,
        DateTime.now().year,
        hostelId,
      ); // Update dashboard summary
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Deletes a meal entry from a specific hostel.
  Future<bool> deleteMealEntry(
    String id,
    DateTime mealDate,
    String hostelId,
  ) async {
    final bool success = await _mealService.deleteMealEntry(id, hostelId);
    if (success) {
      await fetchMealEntriesByDate(mealDate, hostelId); // Update daily view
      await calculateMonthlyMeals(
        DateTime.now().month,
        DateTime.now().year,
        hostelId,
      ); // Update dashboard summary
      notifyListeners();
    }
    return success;
  }

  /// Calculates and updates monthly meal summaries for a specific hostel.
  Future<void> calculateMonthlyMeals(
    int month,
    int year,
    String hostelId,
  ) async {
    _monthlyMessMeals = await _mealService.getMonthlyTotalMealsForMess(
      month,
      year,
      hostelId,
    );
    notifyListeners();
  }

  /// Retrieves the total meals for a specific member in a given month and year in a specific hostel.
  Future<double> getMonthlyTotalMealsForMember(
    String memberId,
    int month,
    int year,
    String hostelId,
  ) async {
    return await _mealService.getMonthlyTotalMealsForMember(
      memberId,
      month,
      year,
      hostelId,
    );
  }

  /// Gets the meal entry for a specific member on a specific date from the current fetched list.
  MealEntry? getMealEntryForMemberAndDate(String memberId, DateTime date) {
    try {
      return _mealEntries.firstWhere(
        (entry) =>
            entry.memberId == memberId &&
            entry.mealDate.year == date.year &&
            entry.mealDate.month == date.month &&
            entry.mealDate.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }
}
