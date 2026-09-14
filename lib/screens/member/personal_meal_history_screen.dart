import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';

/// Screen for members to view their personal meal history.
class PersonalMealHistoryScreen extends StatefulWidget {
  const PersonalMealHistoryScreen({super.key});

  @override
  State<PersonalMealHistoryScreen> createState() =>
      _PersonalMealHistoryScreenState();
}

class _PersonalMealHistoryScreenState extends State<PersonalMealHistoryScreen> {
  List<MealEntry> _mealHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalMealHistory();
  }

  /// Fetches the meal history for the current logged-in member.
  Future<void> _fetchPersonalMealHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mealProvider = Provider.of<MealProvider>(context, listen: false);

      final String? memberId = userProvider.currentMember?.id; // String ID
      final String? hostelId = userProvider.currentUser?.currentHostelId;
      if (memberId != null && hostelId != null) {
        _mealHistory = await mealProvider.fetchMealEntriesByMember(
          memberId,
          hostelId,
        );
      } else {
        _mealHistory = [];
      }
    } catch (e) {
      debugPrint('Error fetching personal meal history: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meal history: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.personalMealHistory)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mealHistory.isEmpty
              ? const Center(child: Text('No meal entries found for you.'))
              : ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                itemCount: _mealHistory.length,
                itemBuilder: (context, index) {
                  final meal = _mealHistory[index];
                  final totalMeals =
                      meal.breakfastMeals +
                      meal.lunchMeals +
                      meal.dinnerMeals +
                      meal.guestMeals; // Calculate total meals

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.paddingSmall,
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        'Date: ${DateHelpers.formatDate(meal.mealDate)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breakfast: ${meal.breakfastMeals.toStringAsFixed(1)}',
                          ),
                          Text('Lunch: ${meal.lunchMeals.toStringAsFixed(1)}'),
                          Text(
                            'Dinner: ${meal.dinnerMeals.toStringAsFixed(1)}',
                          ),
                          Text('Guests: ${meal.guestMeals.toStringAsFixed(1)}'),
                          Text(
                            'Total: ${totalMeals.toStringAsFixed(1)} meals',
                          ), // Display total meals
                        ],
                      ),
                      leading: Icon(
                        Icons.restaurant,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
