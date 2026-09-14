// lib/screens/shared/financial_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:mess_manager/services/report_service.dart';
import 'package:mess_manager/services/meal_service.dart';
import 'package:mess_manager/services/expense_service.dart';
import 'package:mess_manager/services/member_service.dart';
import 'package:mess_manager/models/monthly_summary.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/expense_prediction_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/models/member.dart';

/// Screen for viewing comprehensive monthly financial reports.
class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  DateTime _selectedDate = DateTime.now();
  MonthlySummary? _monthlySummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  /// Generates the financial report for the selected month.
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _monthlySummary = null;
    });

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final expensePredictionProvider = Provider.of<ExpensePredictionProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hostelId = userProvider.currentUser?.currentHostelId;
    if (hostelId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Ensure all necessary data is fetched
      await memberProvider.fetchAllMembers(hostelId);
      await mealProvider.calculateMonthlyMeals(
        _selectedDate.month,
        _selectedDate.year,
        hostelId,
      );
      await expenseProvider.calculateMonthlyFinancials(
        _selectedDate.month,
        _selectedDate.year,
        hostelId,
      );
      await expensePredictionProvider.initializePrediction(hostelId);

      final List<Member> allMembers = memberProvider.members;
      final double totalMessMeals = mealProvider.monthlyMessMeals;
      final double totalMessExpenses = expenseProvider.monthlyTotalExpenses;
      final double totalMessContributions =
          expenseProvider.monthlyTotalContributions;

      double mealRate = 0.0;
      if (totalMessMeals > 0) {
        mealRate = totalMessExpenses / totalMessMeals;
      }

      List<MemberBalance> memberBalances = [];
      for (Member member in allMembers) {
        // personalMeals now includes regular meals + guest meals recorded by this member
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
          member.id!,
          _selectedDate.month,
          _selectedDate.year,
          hostelId,
        );
        // Corrected way to filter contributions for the current month being displayed
        final personalContributions = await expenseProvider
            .fetchContributionsByMember(member.id!, hostelId)
            .then(
              (list) => list
                  .where(
                    (c) =>
                        c.contributionDate.year == _selectedDate.year &&
                        c.contributionDate.month == _selectedDate.month,
                  )
                  .fold(0.0, (sum, item) => sum + item.amount),
            );

        // Calculate individual share of expenses and balance for the FINAL monthly report
        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        memberBalances.add(
          MemberBalance(
            memberId: member.id!,
            memberName: member.name,
            personalMeals: personalMeals,
            personalContributions: personalContributions,
            shareOfExpenses: shareOfExpenses,
            balance: balance,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _monthlySummary = MonthlySummary(
          month: _selectedDate.month,
          year: _selectedDate.year,
          totalMessMeals: totalMessMeals,
          totalMessExpenses: totalMessExpenses,
          totalMessContributions: totalMessContributions,
          mealRate: mealRate,
          memberBalances: memberBalances,
        );
      });
    } catch (e) {
      debugPrint('Error generating financial report: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Allows the user to select a different month for the report.
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _generateReport();
    }
  }

  Future<void> _printReport() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final hostelId = userProvider.currentUser?.currentHostelId;
    final currentMember = userProvider.currentMember;

    if (hostelId == null || currentMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to generate report.")),
      );
      return;
    }

    final reportService = ReportService(
      MealService(),
      ExpenseService(),
      MemberService(),
    );

    final pdfBytes = await reportService.generateMonthlyReport(
      _selectedDate.month,
      _selectedDate.year,
      currentMember,
      hostelId,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name:
      'Monthly_Report_${_selectedDate.month}_${_selectedDate.year}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Access prediction provider
    final expensePredictionProvider = Provider.of<ExpensePredictionProvider>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.financialReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _monthlySummary == null
              ? const Center(child: Text('No data available for this month.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Report for ${DateHelpers.formatMonthYear(_selectedDate)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildSummaryCard(
                      'Overall Mess Summary',
                      [
                        'Total Meals: ${_monthlySummary!.totalMessMeals.toStringAsFixed(2)}',
                        'Total Expenses: ৳${_monthlySummary!.totalMessExpenses.toStringAsFixed(2)}',
                        'Total Contributions: ৳${_monthlySummary!.totalMessContributions.toStringAsFixed(2)}',
                        'Current Mess Balance: ৳${Provider.of<ExpenseProvider>(context).currentMessBalance.toStringAsFixed(2)}',
                        'Final Meal Rate: ৳${_monthlySummary!.mealRate.toStringAsFixed(2)} / meal',
                        // NEW: Add predicted expenses to the summary
                        expensePredictionProvider.isPredictionLoading
                            ? 'Predicted Next Month\'s Expenses: Calculating...'
                            : 'Predicted Next Month\'s Expenses: ৳${expensePredictionProvider.predictedNextMonthExpense.toStringAsFixed(2)}',
                      ],
                      Icons.summarize,
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Text(
                      'Individual Member Details:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _monthlySummary!.memberBalances.length,
                      itemBuilder: (context, index) {
                        final memberBalance =
                            _monthlySummary!.memberBalances[index];
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: AppConstants.paddingMedium,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingMedium,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memberBalance.memberName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  'Personal Meals',
                                  '${memberBalance.personalMeals.toStringAsFixed(2)} meals',
                                ),
                                _buildDetailRow(
                                  'Personal Contributions',
                                  '৳${memberBalance.personalContributions.toStringAsFixed(2)}',
                                ),
                                _buildDetailRow(
                                  'Share of Expenses',
                                  '৳${memberBalance.shareOfExpenses.toStringAsFixed(2)}',
                                ),
                                _buildDetailRow(
                                  'Balance',
                                  memberBalance.balance >= 0
                                      ? 'Owed: ৳${memberBalance.balance.toStringAsFixed(2)}'
                                      : 'Owes: ৳${(memberBalance.balance * -1).toStringAsFixed(2)}',
                                  isBalance: true,
                                  balanceColor:
                                      memberBalance.balance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    List<String> details,
    IconData icon,
    Color cardColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingSmall / 2,
                ),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBalance = false,
    Color? balanceColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingSmall / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBalance ? FontWeight.bold : FontWeight.normal,
              color: isBalance ? balanceColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
