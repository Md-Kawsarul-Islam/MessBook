// lib/screens/member/personal_expense_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';

/// Screen for members to view their personal expense history.
/// Note: With the removal of 'incurredByMemberId' from Expense, this screen
/// will now show ALL mess expenses, as there is no individual member tie.
/// If personal expenses are needed, the Expense model would need to be re-designed.
class PersonalExpenseHistoryScreen extends StatefulWidget {
  const PersonalExpenseHistoryScreen({super.key});

  @override
  State<PersonalExpenseHistoryScreen> createState() =>
      _PersonalExpenseHistoryScreenState();
}

class _PersonalExpenseHistoryScreenState
    extends State<PersonalExpenseHistoryScreen> {
  List<Expense> _expenseHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenseHistory();
  }

  /// Fetches all expenses (since there's no individual member tie for expenses).
  Future<void> _fetchExpenseHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all expenses, as they are no longer tied to a specific member
      _expenseHistory = await expenseProvider.fetchAllExpenses(hostelId);
    } catch (e) {
      debugPrint('Error fetching expense history: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense history: $e')),
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
      appBar: AppBar(title: const Text(AppConstants.personalExpenseHistory)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _expenseHistory.isEmpty
              ? const Center(child: Text('No expense entries found.'))
              : ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                itemCount: _expenseHistory.length,
                itemBuilder: (context, index) {
                  final expense = _expenseHistory[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.paddingSmall,
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(expense.description),
                      subtitle: Text(
                        'Amount: ৳${expense.amount.toStringAsFixed(2)} - Date: ${DateHelpers.formatDate(expense.expenseDate)}',
                      ), // Changed from $ to ৳
                    ),
                  );
                },
              ),
    );
  }
}
