import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:mess_manager/models/contribution.dart';
import 'package:mess_manager/models/meal_entry.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/services/meal_service.dart';
import 'package:mess_manager/services/expense_service.dart';
import 'package:mess_manager/services/member_service.dart';

class ReportService {
  final MealService _mealService;
  final ExpenseService _expenseService;
  final MemberService _memberService;

  ReportService(this._mealService, this._expenseService, this._memberService);

  /// Generates a PDF report for a specific month and year based on the user's role.
  /// Admin/Manager: Full Mess Report.
  /// Member: Personal Monthly Report.
  /// Generates a PDF report for a specific month and year based on the user's role.
  /// Admin/Manager: Full Mess Report.
  /// Member: Personal Monthly Report.
  Future<Uint8List> generateMonthlyReport(
    int month,
    int year,
    Member currentMember,
    String hostelId,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    if (currentMember.role == UserRole.admin ||
        currentMember.role == UserRole.manager) {
      await _generateFullReport(pdf, month, year, monthName, hostelId);
    } else {
      await _generatePersonalReport(
        pdf,
        month,
        year,
        monthName,
        currentMember,
        hostelId,
      );
    }

    return pdf.save();
  }

  Future<void> _generateFullReport(
    pw.Document pdf,
    int month,
    int year,
    String monthName,
    String hostelId,
  ) async {
    // 1. Fetch Data
    final expenses = await _expenseService.getExpensesForMonth(
      month,
      year,
      hostelId,
    );
    final contributions = await _expenseService.getContributionsForMonth(
      month,
      year,
      hostelId,
    );
    final meals = await _mealService.getMealEntriesForMonth(
      month,
      year,
      hostelId,
    );
    final members = await _memberService.getAllMembers(hostelId);

    // 2. Calculate Summaries
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double totalMeals = 0;
    for (var m in meals) {
      totalMeals +=
          m.breakfastMeals + m.lunchMeals + m.dinnerMeals + m.guestMeals;
    }
    double mealRate = totalMeals > 0 ? totalExpenses / totalMeals : 0;

    // 3. Build PDF Pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader("Mess Monthly Report", "$monthName $year"),
            pw.SizedBox(height: 20),
            _buildSummaryTable(totalExpenses, totalMeals, mealRate),
            pw.SizedBox(height: 20),
            _buildSectionTitle("Member Summary"),
            _buildMemberSummaryTable(members, meals, contributions, mealRate),
            pw.SizedBox(height: 20),
            _buildSectionTitle("Expenses Breakdown"),
            _buildExpensesTable(expenses),
          ];
        },
      ),
    );
  }

  Future<void> _generatePersonalReport(
    pw.Document pdf,
    int month,
    int year,
    String monthName,
    Member member,
    String hostelId,
  ) async {
    // 1. Fetch Personal Data (and Mess Constants for calculation)
    final memberMeals = await _mealService.getMemberMealEntriesForMonth(
      member.id!,
      month,
      year,
      hostelId,
    );
    final memberContributions = await _expenseService
        .getMemberContributionsForMonth(member.id!, month, year, hostelId);

    // Need Mess Totals for Rate Calculation
    final allExpenses = await _expenseService.getExpensesForMonth(
      month,
      year,
      hostelId,
    );
    final allMeals = await _mealService.getMealEntriesForMonth(
      month,
      year,
      hostelId,
    );

    double totalExpenses = allExpenses.fold(0, (sum, e) => sum + e.amount);
    double totalMessMeals = 0;
    for (var m in allMeals) {
      totalMessMeals +=
          m.breakfastMeals + m.lunchMeals + m.dinnerMeals + m.guestMeals;
    }
    double mealRate = totalMessMeals > 0 ? totalExpenses / totalMessMeals : 0;

    double memberTotalMeals = 0;
    for (var m in memberMeals) {
      memberTotalMeals +=
          m.breakfastMeals + m.lunchMeals + m.dinnerMeals + m.guestMeals;
    }

    double memberCost = memberTotalMeals * mealRate;
    double totalContributed = memberContributions.fold(
      0,
      (sum, c) => sum + c.amount,
    );
    double balance = totalContributed - memberCost;

    // 2. Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader("Personal Monthly Statement", "$monthName $year"),
            pw.Text(
              "Member: ${member.name}",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            _buildSummaryTable(
              totalExpenses,
              totalMessMeals,
              mealRate,
              labelPrefix: "Mess ",
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("Your Summary"),
            _buildPersonalSummaryTable(
              memberTotalMeals,
              mealRate,
              memberCost,
              totalContributed,
              balance,
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("Your Meal Log"),
            _buildMealLogTable(memberMeals),
            pw.SizedBox(height: 20),
            _buildSectionTitle("Your Contributions"),
            _buildContributionLogTable(memberContributions),
          ];
        },
      ),
    );
  }

  // --- Helper Widgets ---

  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummaryTable(
    double totalExpenses,
    double totalMeals,
    double mealRate, {
    String labelPrefix = "",
  }) {
    return pw.TableHelper.fromTextArray(
      headers: ['Total Expenses', 'Total Meals', 'Meal Rate'],
      data: [
        [
          totalExpenses.toStringAsFixed(2),
          totalMeals.toStringAsFixed(1),
          mealRate.toStringAsFixed(2),
        ],
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
    );
  }

  pw.Widget _buildMemberSummaryTable(
    List<Member> members,
    List<MealEntry> meals,
    List<Contribution> contributions,
    double mealRate,
  ) {
    final data =
        members.map((member) {
          // Calculate individual stats
          double memberMeals = 0;
          for (var m in meals.where((m) => m.memberId == member.id)) {
            memberMeals +=
                m.breakfastMeals + m.lunchMeals + m.dinnerMeals + m.guestMeals;
          }
          double cost = memberMeals * mealRate;
          double contributed = contributions
              .where((c) => c.memberId == member.id)
              .fold(0, (sum, c) => sum + c.amount);
          double balance = contributed - cost;

          return [
            member.name,
            memberMeals.toStringAsFixed(1),
            cost.toStringAsFixed(2),
            contributed.toStringAsFixed(2),
            balance.toStringAsFixed(2),
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Member', 'Meals', 'Cost', 'Paid', 'Balance'],
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildPersonalSummaryTable(
    double totalMeals,
    double rate,
    double cost,
    double contributed,
    double balance,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Total Meals', 'Rate', 'Total Cost', 'Contributed', 'Balance'],
      data: [
        [
          totalMeals.toStringAsFixed(1),
          rate.toStringAsFixed(2),
          cost.toStringAsFixed(2),
          contributed.toStringAsFixed(2),
          balance.toStringAsFixed(2),
        ],
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
    );
  }

  pw.Widget _buildExpensesTable(List<Expense> expenses) {
    // Limit to top 20 or summary if too many? For now list all.
    final data =
        expenses.map((e) {
          return [
            DateFormat('dd MMM').format(e.expenseDate),
            e.description,
            e.amount.toStringAsFixed(2),
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Description', 'Amount'],
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
      cellAlignments: {2: pw.Alignment.centerRight},
    );
  }

  pw.Widget _buildMealLogTable(List<MealEntry> entries) {
    final data =
        entries.map((e) {
          double dailyTotal =
              e.breakfastMeals + e.lunchMeals + e.dinnerMeals + e.guestMeals;
          return [
            DateFormat('dd MMM').format(e.mealDate),
            e.breakfastMeals.toString(),
            e.lunchMeals.toString(),
            e.dinnerMeals.toString(),
            dailyTotal.toString(),
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'B', 'L', 'D', 'Total'],
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
    );
  }

  pw.Widget _buildContributionLogTable(List<Contribution> contributions) {
    final data =
        contributions.map((c) {
          return [
            DateFormat('dd MMM').format(c.contributionDate),
            c.note ?? "",
            c.amount.toStringAsFixed(2),
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Note', 'Amount'],
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.orange),
      cellAlignments: {2: pw.Alignment.centerRight},
    );
  }
}
