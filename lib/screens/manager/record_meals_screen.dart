import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/widgets/custom_button.dart';

/// Screen for managers to record and manage daily meal entries for members.
class RecordMealsScreen extends StatefulWidget {
  const RecordMealsScreen({super.key});

  @override
  State<RecordMealsScreen> createState() => _RecordMealsScreenState();
}

class _RecordMealsScreenState extends State<RecordMealsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _guestMealsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Member? _selectedMember;
  bool _isLoading = false;
  List<MealEntry> _dailyMealEntries = [];
  MealEntry? _editingMealEntry; // This will be null for 'Add' mode

  @override
  void initState() {
    super.initState();
    _initializeScreenData(); // Initial fetch and setup
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _guestMealsController.dispose();
    super.dispose();
  }

  /// Initializes screen data: fetches entries, active members, and sets initial form state.
  Future<void> _initializeScreenData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      await memberProvider.fetchActiveMembers(hostelId);
      await mealProvider.fetchMealEntriesByDate(_selectedDate, hostelId);
      _dailyMealEntries = mealProvider.mealEntries;

      // Set initial selected member if none is selected yet
      if (_selectedMember == null && memberProvider.activeMembers.isNotEmpty) {
        _selectedMember = memberProvider.activeMembers.first;
      }

      // Always reset to 'Add Meal Entry' mode on initial load or after a full refresh
      _clearFormAndSetToAddMode();
    } catch (e) {
      debugPrint('Error initializing meal data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load initial meal data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Clears all text controllers and sets the form to 'Add Meal Entry' mode.
  /// Sets default meal values as requested.
  void _clearFormAndSetToAddMode() {
    _breakfastController.text = '0.5'; // Default for Breakfast
    _lunchController.text = '1.0'; // Default for Lunch
    _dinnerController.text = '1.0'; // Default for Dinner
    _guestMealsController.text = '0.0'; // Default for Guest Meals
    if (mounted) {
      setState(() {
        _editingMealEntry = null; // Explicitly set to null for 'Add' mode
      });
    }
  }

  /// Populates text controllers and sets the form to 'Update Meal Entry' mode.
  void _populateFormForEdit(MealEntry entry) {
    setState(() {
      _editingMealEntry = entry;
      _breakfastController.text = entry.breakfastMeals.toString();
      _lunchController.text = entry.lunchMeals.toString();
      _dinnerController.text = entry.dinnerMeals.toString();
      _guestMealsController.text = entry.guestMeals.toString();
    });
  }

  /// Allows the user to select a date for meal recording.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // After date changes, re-initialize data and reset form state
      await _initializeScreenData();
      // Then, check if an entry exists for the currently selected member on the new date
      _checkAndLoadExistingEntryForSelectedMember();
    }
  }

  /// Handles adding or updating a meal entry.
  Future<void> _saveMealEntry() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMember == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a member.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) return;

      final mealProvider = Provider.of<MealProvider>(context, listen: false);

      final mealEntry = MealEntry(
        id: _editingMealEntry?.id,
        memberId: _selectedMember!.id!, // String ID
        mealDate: _selectedDate,
        breakfastMeals: double.parse(_breakfastController.text),
        lunchMeals: double.parse(_lunchController.text),
        dinnerMeals: double.parse(_dinnerController.text),
        guestMeals: double.parse(_guestMealsController.text),
      );

      bool success = await mealProvider.addOrUpdateMealEntry(
        mealEntry,
        hostelId,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingMealEntry == null
                  ? 'Meal entry added successfully!'
                  : 'Meal entry updated successfully!',
            ),
          ),
        );
        // After successful save, re-initialize data and reset form state
        await _initializeScreenData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingMealEntry == null
                  ? 'Failed to add meal entry.'
                  : 'Failed to update meal entry.',
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sets the form fields for editing an existing meal entry.
  void _editMealEntry(MealEntry mealEntry) {
    // When editing from the list, directly populate and set edit mode
    _populateFormForEdit(mealEntry);
    // Also ensure the correct member is selected in the dropdown
    setState(() {
      _selectedMember = Provider.of<MemberProvider>(
        context,
        listen: false,
      ).getMemberById(mealEntry.memberId);
      _selectedDate =
          mealEntry
              .mealDate; // Update date picker if editing an entry from a different date
    });
    // Re-fetch daily entries for the potentially new date to update the list view
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hostelId = userProvider.currentUser?.currentHostelId;
    if (hostelId != null) {
      Provider.of<MealProvider>(
        context,
        listen: false,
      ).fetchMealEntriesByDate(_selectedDate, hostelId);
    }
  }

  /// Deletes a meal entry.
  Future<void> _deleteMealEntry(String id) async {
    // Changed to String id
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Meal Entry'),
          content: const Text(
            'Are you sure you want to delete this meal entry?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) return;

      final bool success = await mealProvider.deleteMealEntry(
        id,
        _selectedDate,
        hostelId,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal entry deleted successfully!')),
        );
        // After successful delete, re-initialize data and reset form state
        await _initializeScreenData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete meal entry.')),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Checks if an entry exists for the currently selected member and date,
  /// and loads it into the form if found, otherwise ensures form is clear.
  void _checkAndLoadExistingEntryForSelectedMember() {
    _clearFormAndSetToAddMode(); // Always start by clearing to ensure add mode

    if (_selectedMember != null) {
      final existingEntry = Provider.of<MealProvider>(
        context,
        listen: false,
      ).getMealEntryForMemberAndDate(_selectedMember!.id!, _selectedDate);
      if (existingEntry != null) {
        _populateFormForEdit(
          existingEntry,
        ); // If entry exists, switch to edit mode
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.recordMeals)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    flex: 6, // Retained flex for the form section
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingSmall,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Date: ${DateHelpers.formatDate(_selectedDate)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      onTap: () => _selectDate(context),
                                    ),
                                    const SizedBox(
                                      height:
                                          AppConstants.paddingMedium +
                                          AppConstants.paddingSmall,
                                    ),
                                    Consumer<MemberProvider>(
                                      builder: (
                                        context,
                                        memberProvider,
                                        child,
                                      ) {
                                        if (_selectedMember == null &&
                                            memberProvider
                                                .activeMembers
                                                .isNotEmpty) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (!mounted) return;
                                                setState(() {
                                                  _selectedMember =
                                                      memberProvider
                                                          .activeMembers
                                                          .first;
                                                  _checkAndLoadExistingEntryForSelectedMember();
                                                });
                                              });
                                        } else if (_selectedMember != null &&
                                            !memberProvider.activeMembers
                                                .contains(_selectedMember)) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (!mounted) return;
                                                setState(() {
                                                  _selectedMember =
                                                      memberProvider
                                                              .activeMembers
                                                              .isNotEmpty
                                                          ? memberProvider
                                                              .activeMembers
                                                              .first
                                                          : null;
                                                  _checkAndLoadExistingEntryForSelectedMember();
                                                });
                                              });
                                        }

                                        return DropdownButtonFormField<Member>(
                                          initialValue: _selectedMember,
                                          decoration: const InputDecoration(
                                            labelText: 'Select Member',
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                            ),
                                            isDense: true,
                                            labelStyle: TextStyle(fontSize: 14),
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.always,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 6,
                                                  horizontal: 14,
                                                ),
                                          ),
                                          items:
                                              memberProvider.activeMembers.map((
                                                member,
                                              ) {
                                                return DropdownMenuItem<Member>(
                                                  value: member,
                                                  child: Text(
                                                    member.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (Member? newValue) {
                                            setState(() {
                                              _selectedMember = newValue;
                                              _checkAndLoadExistingEntryForSelectedMember();
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select a member';
                                            }
                                            return null;
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(
                                      height:
                                          AppConstants.paddingMedium +
                                          AppConstants.paddingSmall,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _breakfastController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Breakfast Meals',
                                              prefixIcon: Icon(
                                                Icons.free_breakfast,
                                              ),
                                              isDense: true,
                                              labelStyle: TextStyle(
                                                fontSize: 14,
                                              ),
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 14,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Invalid number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppConstants.paddingSmall,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _lunchController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Lunch Meals',
                                              prefixIcon: Icon(
                                                Icons.lunch_dining,
                                              ),
                                              isDense: true,
                                              labelStyle: TextStyle(
                                                fontSize: 14,
                                              ),
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 14,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Invalid number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height:
                                          AppConstants.paddingMedium +
                                          AppConstants.paddingSmall,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _dinnerController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Dinner Meals',
                                              prefixIcon: Icon(
                                                Icons.dinner_dining,
                                              ),
                                              isDense: true,
                                              labelStyle: TextStyle(
                                                fontSize: 14,
                                              ),
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 14,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Invalid number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppConstants.paddingSmall,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _guestMealsController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Guest Meals',
                                              prefixIcon: Icon(
                                                Icons.people_alt,
                                              ),
                                              isDense: true,
                                              labelStyle: TextStyle(
                                                fontSize: 14,
                                              ),
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 14,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required (0 if none)';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Invalid number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          CustomButton(
                            text:
                                _editingMealEntry == null
                                    ? 'Add Meal Entry'
                                    : 'Update Meal Entry',
                            onPressed: _saveMealEntry,
                          ),
                          if (_editingMealEntry != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppConstants.paddingSmall,
                              ),
                              child: CustomButton(
                                text: 'Cancel Edit',
                                onPressed: _clearFormAndSetToAddMode,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    flex: 3,
                    child:
                        _dailyMealEntries.isEmpty
                            ? const Center(
                              child: Text(
                                'No meal entries recorded for this date.',
                              ),
                            )
                            : ListView.builder(
                              itemCount: _dailyMealEntries.length,
                              itemBuilder: (context, index) {
                                final meal = _dailyMealEntries[index];
                                final memberName =
                                    Provider.of<MemberProvider>(
                                      context,
                                      listen: false,
                                    ).getMemberById(meal.memberId)?.name ??
                                    'Unknown';
                                final totalMeals =
                                    meal.breakfastMeals +
                                    meal.lunchMeals +
                                    meal.dinnerMeals +
                                    meal.guestMeals;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingMedium,
                                    vertical: AppConstants.paddingSmall / 2,
                                  ),
                                  elevation: 1,
                                  child: ListTile(
                                    title: Text(
                                      '$memberName - Total: ${totalMeals.toStringAsFixed(1)} meals',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Breakfast: ${meal.breakfastMeals.toStringAsFixed(1)}',
                                        ),
                                        Text(
                                          'Lunch: ${meal.lunchMeals.toStringAsFixed(1)}',
                                        ),
                                        Text(
                                          'Dinner: ${meal.dinnerMeals.toStringAsFixed(1)}',
                                        ),
                                        Text(
                                          'Guests: ${meal.guestMeals.toStringAsFixed(1)}',
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _editMealEntry(meal),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteMealEntry(meal.id!),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
