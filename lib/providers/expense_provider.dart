import 'package:flutter/material.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:mess_manager/models/contribution.dart';
import 'package:mess_manager/services/expense_service.dart';

/// Provider for managing Expense and Contribution data.
class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService;

  List<Expense> _expenses = [];
  List<Contribution> _contributions = [];
  double _monthlyTotalExpenses = 0.0;
  double _monthlyTotalContributions = 0.0;
  double _currentMessBalance = 0.0;

  ExpenseProvider(this._expenseService);

  List<Expense> get expenses => _expenses;
  List<Contribution> get contributions => _contributions;
  double get monthlyTotalExpenses => _monthlyTotalExpenses;
  double get monthlyTotalContributions => _monthlyTotalContributions;
  double get currentMessBalance => _currentMessBalance;

  /// Fetches all expenses from the database for a specific hostel.
  Future<List<Expense>> fetchAllExpenses(String hostelId) async {
    _expenses = await _expenseService.getAllExpenses(hostelId);
    notifyListeners();
    return _expenses;
  }

  /// Adds a new expense to a specific hostel.
  Future<bool> addExpense(Expense expense, String hostelId) async {
    final String id = await _expenseService.addExpense(expense, hostelId);
    if (id.isNotEmpty) {
      await fetchAllExpenses(hostelId); // Refresh list
      await calculateMonthlyFinancials(
        expense.expenseDate.month,
        expense.expenseDate.year,
        hostelId,
      ); // Recalculate financials
      return true;
    }
    return false;
  }

  /// Updates an existing expense in a specific hostel.
  Future<bool> updateExpense(Expense expense, String hostelId) async {
    final bool success = await _expenseService.updateExpense(expense, hostelId);
    if (success) {
      await fetchAllExpenses(hostelId); // Refresh list
      await calculateMonthlyFinancials(
        expense.expenseDate.month,
        expense.expenseDate.year,
        hostelId,
      ); // Recalculate financials
    }
    return success;
  }

  /// Deletes an expense from a specific hostel.
  Future<bool> deleteExpense(String id, String hostelId) async {
    final bool success = await _expenseService.deleteExpense(id, hostelId);
    if (success) {
      // Re-fetch all expenses to get the latest list and then recalculate financials
      await fetchAllExpenses(hostelId);
      // Recalculate for the current month.
      await calculateMonthlyFinancials(
        DateTime.now().month,
        DateTime.now().year,
        hostelId,
      );
    }
    return success;
  }

  /// Fetches all contributions from the database for a specific hostel.
  Future<List<Contribution>> fetchAllContributions(String hostelId) async {
    _contributions = await _expenseService.getAllContributions(hostelId);
    notifyListeners();
    return _contributions;
  }

  /// Adds a new contribution to a specific hostel.
  Future<bool> addContribution(
    Contribution contribution,
    String hostelId,
  ) async {
    final String id = await _expenseService.addContribution(
      contribution,
      hostelId,
    );
    if (id.isNotEmpty) {
      await fetchAllContributions(hostelId); // Refresh list
      await calculateMonthlyFinancials(
        contribution.contributionDate.month,
        contribution.contributionDate.year,
        hostelId,
      ); // Recalculate financials
      return true;
    }
    return false;
  }

  /// Updates an existing contribution in a specific hostel.
  Future<bool> updateContribution(
    Contribution contribution,
    String hostelId,
  ) async {
    final bool success = await _expenseService.updateContribution(
      contribution,
      hostelId,
    );
    if (success) {
      await fetchAllContributions(hostelId); // Refresh list
      await calculateMonthlyFinancials(
        contribution.contributionDate.month,
        contribution.contributionDate.year,
        hostelId,
      ); // Recalculate financials
    }
    return success;
  }

  /// Deletes a contribution from a specific hostel.
  Future<bool> deleteContribution(String id, String hostelId) async {
    final bool success = await _expenseService.deleteContribution(id, hostelId);
    if (success) {
      // Re-fetch all contributions to get the latest list and then recalculate financials
      await fetchAllContributions(hostelId);
      // Recalculate for the current month.
      await calculateMonthlyFinancials(
        DateTime.now().month,
        DateTime.now().year,
        hostelId,
      );
    }
    return success;
  }

  /// Fetches contributions made by a specific member in a specific hostel.
  Future<List<Contribution>> fetchContributionsByMember(
    String memberId,
    String hostelId,
  ) async {
    return await _expenseService.getContributionsByMember(memberId, hostelId);
  }

  /// Calculates monthly total expenses and contributions for the mess in a specific hostel.
  Future<void> calculateMonthlyFinancials(
    int month,
    int year,
    String hostelId,
  ) async {
    _monthlyTotalExpenses = await _expenseService
        .getMonthlyTotalExpensesForMess(month, year, hostelId);
    _monthlyTotalContributions = await _expenseService
        .getMonthlyTotalContributionsForMess(month, year, hostelId);
    _currentMessBalance = _monthlyTotalContributions - _monthlyTotalExpenses;
    notifyListeners();
  }

  /// Aggregates expenses by category for a given month and year.
  Future<Map<String, double>> calculateMonthlyCategoryExpenses(
    int month,
    int year,
    String hostelId,
  ) async {
    final expenses = await _expenseService.getExpensesForMonth(
      month,
      year,
      hostelId,
    );

    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      if (categoryTotals.containsKey(expense.category)) {
        categoryTotals[expense.category] =
            categoryTotals[expense.category]! + expense.amount;
      } else {
        categoryTotals[expense.category] = expense.amount;
      }
    }
    return categoryTotals;
  }
}
