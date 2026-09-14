import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:mess_manager/models/contribution.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/widgets/custom_button.dart';

/// Screen for managers to record and manage mess expenses.
class RecordExpenseScreen extends StatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  State<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends State<RecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Expense> _expenses = [];
  Expense? _editingExpense;
  bool _isPaidByMember = false;
  Member? _selectedPayer;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Fetches all expenses.
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(
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

      await expenseProvider.fetchAllExpenses(hostelId);
      await memberProvider.fetchActiveMembers(hostelId);
      _expenses = expenseProvider.expenses;
    } catch (e) {
      debugPrint('Error fetching expense data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Allows the user to select a date for the expense.
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
    }
  }

  /// Handles adding or updating an expense.
  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      final expense = Expense(
        id: _editingExpense?.id,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        expenseDate: _selectedDate,
      );

      bool success;
      if (_editingExpense == null) {
        success = await expenseProvider.addExpense(expense, hostelId);

        // Logic: If paid by member, automatically add a Contribution (Refund)
        if (success && _isPaidByMember && _selectedPayer != null) {
          final contribution = Contribution(
            memberId: _selectedPayer!.id!,
            amount: double.parse(_amountController.text),
            contributionDate: _selectedDate,
            note: 'Expense Refund: ${_descriptionController.text.trim()}',
          );
          await expenseProvider.addContribution(contribution, hostelId);
        }
      } else {
        success = await expenseProvider.updateExpense(expense, hostelId);
      }

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingExpense == null
                  ? 'Expense added successfully!'
                  : 'Expense updated successfully!',
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
              _editingExpense == null
                  ? 'Failed to add expense.'
                  : 'Failed to update expense.',
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

  /// Sets the form fields for editing an existing expense.
  void _editExpense(Expense expense) {
    setState(() {
      _editingExpense = expense;
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toString();
      _selectedDate = expense.expenseDate;
    });
  }

  /// Deletes an expense.
  Future<void> _deleteExpense(String id) async {
    // Changed to String id
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
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

      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final bool success = await expenseProvider.deleteExpense(id, hostelId);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully!')),
        );
        _clearForm();
        await _fetchData(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete expense.')),
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
    _descriptionController.clear();
    _amountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedDate = DateTime.now();
      _editingExpense = null;
      _isPaidByMember = false;
      _selectedPayer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.recordExpense)),
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
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount (৳)',
                              prefixIcon: Icon(Icons.money),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          if (_editingExpense == null) ...[
                            // Hide Payer options when editing existing expense to avoid confusion
                            Card(
                              elevation: 2,
                              color:
                                  Colors
                                      .orange
                                      .shade50, // Subtle highlight background
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.orange.shade200),
                              ),
                              child: SwitchListTile(
                                title: const Text(
                                  'Paid by Member (Personal Money)?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Creates a refund contribution automatically',
                                ),
                                secondary: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.deepOrange,
                                ),
                                value: _isPaidByMember,
                                activeThumbColor: Colors.deepOrange,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isPaidByMember = value;
                                    if (!value) _selectedPayer = null;
                                  });
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                              ),
                            ),
                            if (_isPaidByMember)
                              Consumer<MemberProvider>(
                                builder: (context, memberProvider, child) {
                                  return DropdownButtonFormField<Member>(
                                    initialValue: _selectedPayer,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Payer',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    items:
                                        memberProvider.activeMembers.map((
                                          member,
                                        ) {
                                          return DropdownMenuItem<Member>(
                                            value: member,
                                            child: Text(member.name),
                                          );
                                        }).toList(),
                                    onChanged: (Member? newValue) {
                                      setState(() {
                                        _selectedPayer = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (_isPaidByMember && value == null) {
                                        return 'Please select the member who paid';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            const SizedBox(height: AppConstants.paddingMedium),
                          ],
                          ListTile(
                            title: Text(
                              'Date: ${DateHelpers.formatDate(_selectedDate)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                          const SizedBox(height: AppConstants.paddingLarge),
                          CustomButton(
                            text:
                                _editingExpense == null
                                    ? 'Add Expense'
                                    : 'Update Expense',
                            onPressed: _saveExpense,
                          ),
                          if (_editingExpense != null)
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
                        _expenses.isEmpty
                            ? const Center(
                              child: Text('No expenses recorded yet.'),
                            )
                            : ListView.builder(
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingMedium,
                                    vertical: AppConstants.paddingSmall,
                                  ),
                                  elevation: 1,
                                  child: ListTile(
                                    title: Text(
                                      '${expense.description} - ৳${expense.amount.toStringAsFixed(2)}',
                                    ),
                                    subtitle: Text(
                                      'Date: ${DateHelpers.formatDate(expense.expenseDate)}',
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
                                              () => _editExpense(expense),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteExpense(expense.id!),
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
