import 'package:flutter/material.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/services/meal_service.dart';

/// Provider for managing MealEntry data.
class MealProvider with ChangeNotifier {
final MealService _mealService;

List<MealEntry> _mealEntries = [];
final Map<String, double> _monthlyMemberMeals = {};
double _monthlyMessMeals = 0.0;

MealProvider(this._mealService);

// Getters
List<MealEntry> get mealEntries => _mealEntries;

Map<String, double> get monthlyMemberMeals => _monthlyMemberMeals;

double get monthlyMessMeals => _monthlyMessMeals;

/// Fetch meal entries for a specific date and hostel.
Future<void> fetchMealEntriesByDate(
DateTime date,
String hostelId,
) async {
_mealEntries = await _mealService.getMealEntriesByDate(
date,
hostelId,
);

notifyListeners();
}

/// Fetch meal entries for a specific member and hostel.
Future<List<MealEntry>> fetchMealEntriesByMember(
String memberId,
String hostelId,
) async {
return await _mealService.getMealEntriesByMember(
memberId,
hostelId,
);
}

/// Add or update a meal entry.
Future<bool> addOrUpdateMealEntry(
MealEntry mealEntry,
String hostelId,
) async {
try {
final String id = await _mealService.addMealEntry(
mealEntry,
hostelId,
);

if (id.isEmpty) {
return false;
}

// Refresh daily meal entries.
await fetchMealEntriesByDate(
mealEntry.mealDate,
hostelId,
);

// Refresh monthly meal summary.
await calculateMonthlyMeals(
mealEntry.mealDate.month,
mealEntry.mealDate.year,
hostelId,
);

return true;
} catch (e) {
debugPrint('Error adding/updating meal entry: $e');
return false;
}
}

/// Delete a meal entry.
Future<bool> deleteMealEntry(
String id,
DateTime mealDate,
String hostelId,
) async {
try {
final bool success = await _mealService.deleteMealEntry(
id,
hostelId,
);

if (!success) {
return false;
}

// Refresh daily meal entries.
await fetchMealEntriesByDate(
mealDate,
hostelId,
);

// Refresh monthly meal summary.
await calculateMonthlyMeals(
mealDate.month,
mealDate.year,
hostelId,
);

return true;
} catch (e) {
debugPrint('Error deleting meal entry: $e');
return false;
}
}

/// Calculate total meals for the mess for a specific month.
Future<void> calculateMonthlyMeals(
int month,
int year,
String hostelId,
) async {
try {
_monthlyMessMeals =
await _mealService.getMonthlyTotalMealsForMess(
month,
year,
hostelId,
);

notifyListeners();
} catch (e) {
debugPrint('Error calculating monthly meals: $e');
}
}

/// Get total meals for a specific member for a specific month.
Future<double> getMonthlyTotalMealsForMember(
String memberId,
int month,
int year,
String hostelId,
) async {
try {
return await _mealService.getMonthlyTotalMealsForMember(
memberId,
month,
year,
hostelId,
);
} catch (e) {
debugPrint('Error getting member monthly meals: $e');
return 0.0;
}
}

/// Get a meal entry for a specific member and date.
MealEntry? getMealEntryForMemberAndDate(
String memberId,
DateTime date,
) {
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
