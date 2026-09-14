import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/market_schedule.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/providers/market_schedule_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/widgets/custom_button.dart';

/// Screen for managers to record and manage market schedules.
class MarketScheduleScreen extends StatefulWidget {
  const MarketScheduleScreen({super.key});

  @override
  State<MarketScheduleScreen> createState() => _MarketScheduleScreenState();
}

class _MarketScheduleScreenState extends State<MarketScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dutyTitleController =
      TextEditingController(); // New controller
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Member? _selectedMember;
  bool _isLoading = false;
  List<MarketSchedule> _marketSchedules = [];
  MarketSchedule? _editingSchedule;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _dutyTitleController.dispose(); // Dispose new controller
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fetches all market schedules and active members.
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );
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

      await marketScheduleProvider.fetchAllMarketSchedules(hostelId);
      _marketSchedules = marketScheduleProvider.marketSchedules;

      await memberProvider.fetchActiveMembers(hostelId);
      if (memberProvider.activeMembers.isNotEmpty && _selectedMember == null) {
        _selectedMember = memberProvider.activeMembers.first;
      }
    } catch (e) {
      debugPrint('Error fetching market schedule data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load market schedule data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Allows the user to select a date for the market schedule.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030), // Allow future dates for scheduling
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
    }
  }

  /// Handles adding or updating a market schedule entry.
  Future<void> _saveMarketSchedule() async {
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
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );

      final schedule = MarketSchedule(
        id: _editingSchedule?.id,
        memberId: _selectedMember!.id!,
        scheduleDate: _selectedDate,
        dutyTitle: _dutyTitleController.text.trim(), // Save new field
        description: _descriptionController.text.trim(),
      );

      bool success;
      if (_editingSchedule == null) {
        success = await marketScheduleProvider.addMarketSchedule(
          schedule,
          hostelId,
        );
      } else {
        success = await marketScheduleProvider.updateMarketSchedule(
          schedule,
          hostelId,
        );
      }

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingSchedule == null
                  ? 'Market schedule added successfully!'
                  : 'Market schedule updated successfully!',
            ),
          ),
        );
        _clearForm();
        await _fetchData(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingSchedule == null
                  ? 'Failed to add market schedule.'
                  : 'Failed to update market schedule.',
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

  /// Sets the form fields for editing an existing market schedule.
  void _editMarketSchedule(MarketSchedule schedule) {
    setState(() {
      _editingSchedule = schedule;
      _dutyTitleController.text =
          schedule.dutyTitle; // Set new field for editing
      _descriptionController.text = schedule.description;
      _selectedDate = schedule.scheduleDate;
      _selectedMember = Provider.of<MemberProvider>(
        context,
        listen: false,
      ).getMemberById(schedule.memberId);
    });
  }

  /// Deletes a market schedule entry.
  Future<void> _deleteMarketSchedule(String id) async {
    // Changed to String id
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Schedule'),
          content: const Text(
            'Are you sure you want to delete this market schedule?',
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) return;

      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );
      final bool success = await marketScheduleProvider.deleteMarketSchedule(
        id,
        hostelId,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Market schedule deleted successfully!'),
          ),
        );
        _clearForm();
        await _fetchData(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete market schedule.')),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Clears the form fields and resets editing state.
  void _clearForm() {
    _dutyTitleController.clear(); // Clear new controller
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _editingSchedule = null;
      // Reset selected member to the first active member if available
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
      if (memberProvider.activeMembers.isNotEmpty) {
        _selectedMember = memberProvider.activeMembers.first;
      } else {
        _selectedMember = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.marketSchedule)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            title: Text(
                              'Date: ${DateHelpers.formatDate(_selectedDate)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          Consumer<MemberProvider>(
                            builder: (context, memberProvider, child) {
                              return DropdownButtonFormField<Member>(
                                initialValue: _selectedMember,
                                decoration: const InputDecoration(
                                  labelText: 'Assign Member',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items:
                                    memberProvider.activeMembers.map((member) {
                                      return DropdownMenuItem<Member>(
                                        value: member,
                                        child: Text(member.name),
                                      );
                                    }).toList(),
                                onChanged: (Member? newValue) {
                                  setState(() {
                                    _selectedMember = newValue;
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
                          const SizedBox(height: AppConstants.paddingMedium),
                          TextFormField(
                            // New: Duty Title
                            controller: _dutyTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Duty Title',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a duty title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          TextFormField(
                            // Description with larger text area
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint:
                                  true, // Aligns label to top for multiline
                            ),
                            keyboardType:
                                TextInputType
                                    .multiline, // Enables multiline input
                            maxLines: null, // Allows unlimited lines
                            minLines: 3, // Starts with 3 lines height
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.paddingLarge),
                          CustomButton(
                            text:
                                _editingSchedule == null
                                    ? 'Add Schedule'
                                    : 'Update Schedule',
                            onPressed: _saveMarketSchedule,
                          ),
                          if (_editingSchedule != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppConstants.paddingSmall,
                              ),
                              child: CustomButton(
                                text: 'Cancel Edit',
                                onPressed: _clearForm,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _marketSchedules.isEmpty
                            ? const Center(
                              child: Text('No market schedules recorded yet.'),
                            )
                            : ListView.builder(
                              itemCount: _marketSchedules.length,
                              itemBuilder: (context, index) {
                                final schedule = _marketSchedules[index];
                                final memberName =
                                    Provider.of<MemberProvider>(
                                      context,
                                      listen: false,
                                    ).getMemberById(schedule.memberId)?.name ??
                                    'Unknown';
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingMedium,
                                    vertical: AppConstants.paddingSmall,
                                  ),
                                  elevation: 1,
                                  child: ListTile(
                                    title: Text(
                                      '${schedule.dutyTitle} - $memberName',
                                    ), // Display duty title
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date: ${DateHelpers.formatDate(schedule.scheduleDate)}',
                                        ),
                                        Text(
                                          'Description: ${schedule.description}',
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
                                          onPressed:
                                              () =>
                                                  _editMarketSchedule(schedule),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteMarketSchedule(
                                                schedule.id!,
                                              ),
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
