import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/monthly_summary.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/market_schedule_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/expense_prediction_provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/widgets/dashboard_card.dart';
import 'package:mess_manager/widgets/expense_chart.dart';
import 'package:mess_manager/providers/notice_provider.dart';
import 'package:mess_manager/models/notice.dart';
import 'package:mess_manager/models/meal_feedback.dart';
import 'package:mess_manager/services/meal_feedback_service.dart';
import 'package:mess_manager/models/hostel.dart';
import 'package:mess_manager/models/monthly_history.dart';
import 'package:mess_manager/services/monthly_history_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manager dashboard displaying overall mess summaries and navigation to management features.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  DateTime _currentMonth = DateTime.now();
  bool _isMonthOpen = true;
  Hostel? _currentHostel;

  bool _isLoading = false;
  MonthlySummary? _overallMonthlySummary;
  MonthlySummary? _personalMonthlySummary;
  Map<String, double> _categoryExpenses = {};
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Fetches all necessary data for the manager dashboard.
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );
      final expensePredictionProvider = Provider.of<ExpensePredictionProvider>(
        context,
        listen: false,
      );

      final String? hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // --- Fetch Hostel Data for Active Month ---
      final hostelDoc =
          await FirebaseFirestore.instance
              .collection('hostels')
              .doc(hostelId)
              .get();
      if (hostelDoc.exists) {
        _currentHostel = Hostel.fromFirestore(hostelDoc);
        if (mounted) {
          _currentMonth = _currentHostel!.activeMonth;
          _isMonthOpen = _currentHostel!.isMonthOpen;
        }
      }

      // --- Fetch Overall Mess Data ---
      await mealProvider.calculateMonthlyMeals(
        _currentMonth.month,
        _currentMonth.year,
        hostelId,
      );
      await expenseProvider.calculateMonthlyFinancials(
        _currentMonth.month,
        _currentMonth.year,
        hostelId,
      );
      final categoryExpenses = await expenseProvider
          .calculateMonthlyCategoryExpenses(
            _currentMonth.month,
            _currentMonth.year,
            hostelId,
          );
      _categoryExpenses = categoryExpenses;
      await memberProvider.fetchAllMembers(
        hostelId,
      ); // Fetch all members for balance calculation
      await marketScheduleProvider.fetchUpcomingMarketSchedules(
        hostelId,
      ); // Fetch for display
      await expensePredictionProvider.initializePrediction(hostelId);

      // Fetch Feedback Data
      if (!mounted) return;
      final feedbackService = Provider.of<MealFeedbackService>(
        context,
        listen: false,
      );
      final avgRating = await feedbackService.getAverageRatingForMonth(
        hostelId,
        _currentMonth.month,
        _currentMonth.year,
      );
      _averageRating = avgRating;

      final List<Member> allMembers = memberProvider.members;
      final double totalMessMeals = mealProvider.monthlyMessMeals;
      final double totalMessExpenses = expenseProvider.monthlyTotalExpenses;
      final double totalMessContributions =
          expenseProvider.monthlyTotalContributions;

      double mealRate = 0.0;
      if (totalMessMeals > 0) {
        mealRate = totalMessExpenses / totalMessMeals;
      }

      List<MemberBalance> overallMemberBalances = [];
      for (Member member in allMembers) {
        if (member.id == null) continue;
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
          member.id!,
          _currentMonth.month,
          _currentMonth.year,
          hostelId,
        );

        final personalContributions = await expenseProvider
            .fetchContributionsByMember(member.id!, hostelId)
            .then(
              (list) => list
                  .where(
                    (c) =>
                        c.contributionDate.year == _currentMonth.year &&
                        c.contributionDate.month == _currentMonth.month,
                  )
                  .fold(0.0, (prev, item) => prev + item.amount),
            );

        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        overallMemberBalances.add(
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

      // Set overall mess summary
      _overallMonthlySummary = MonthlySummary(
        month: _currentMonth.month,
        year: _currentMonth.year,
        totalMessMeals: totalMessMeals,
        totalMessExpenses: totalMessExpenses,
        totalMessContributions: totalMessContributions,
        mealRate: mealRate,
        memberBalances: overallMemberBalances,
      );

      // --- Fetch Personal Manager Data ---
      final String? currentManagerMemberId =
          userProvider.currentMember?.id; // String ID
      final String? currentManagerMemberName = userProvider.currentMember?.name;

      if (currentManagerMemberId != null && currentManagerMemberName != null) {
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
          currentManagerMemberId,
          _currentMonth.month,
          _currentMonth.year,
          hostelId,
        );
        final personalContributionsList = await expenseProvider
            .fetchContributionsByMember(currentManagerMemberId, hostelId);

        final personalContributions = personalContributionsList
            .where(
              (c) =>
                  c.contributionDate.year == _currentMonth.year &&
                  c.contributionDate.month == _currentMonth.month,
            )
            .fold(0.0, (prev, item) => prev + item.amount);

        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        _personalMonthlySummary = MonthlySummary(
          month: _currentMonth.month,
          year: _currentMonth.year,
          totalMessMeals: totalMessMeals,
          totalMessExpenses: totalMessExpenses,
          totalMessContributions: totalMessContributions,
          mealRate: mealRate,
          memberBalances: [
            MemberBalance(
              memberId: currentManagerMemberId,
              memberName: currentManagerMemberName,
              personalMeals: personalMeals,
              personalContributions: personalContributions,
              shareOfExpenses: shareOfExpenses,
              balance: balance,
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint('Error fetching manager dashboard data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles user logout.
  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context);
    final expensePredictionProvider = Provider.of<ExpensePredictionProvider>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.managerDashboard),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: () => _fetchDashboardData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            color: Colors.white,
            tooltip: AppConstants.logoutButton,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(userProvider),
                      const SizedBox(height: AppConstants.paddingMedium),

                      if (userProvider.currentUser?.currentHostelId != null)
                        _buildNoticeSection(
                          userProvider.currentUser!.currentHostelId!,
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Summary
                            _buildSectionTitle(
                              'Your Snapshot',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildPersonalSummaryGrid(),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Mess Status
                            _buildMessStatusHeader(),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildMessStatusGrid(expensePredictionProvider),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Quick Actions
                            _buildSectionTitle(
                              'Management Actions',
                              Icons.grid_view,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildManagementGrid(context),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Secondary Sections (Expenses, Feedback, Duties)
                            if (_categoryExpenses.isNotEmpty) ...[
                              _buildSectionTitle(
                                'Expense Analytics',
                                Icons.pie_chart_outline,
                              ),
                              const SizedBox(height: AppConstants.paddingSmall),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ExpenseChart(
                                    categoryExpenses: _categoryExpenses,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                            ],

                            _buildFeedbackSection(userProvider),
                            const SizedBox(height: AppConstants.paddingLarge),

                            _buildMarketDutiesSection(marketScheduleProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.groupChat),
        tooltip: 'Group Chat',
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildWelcomeSection(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        0,
        AppConstants.paddingMedium,
        AppConstants.paddingLarge + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userProvider.currentMember?.name ??
                userProvider.currentUser?.username ??
                'Manager',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNoticeSection(String hostelId) {
    return StreamBuilder<List<Notice>>(
      stream: Provider.of<NoticeProvider>(
        context,
        listen: false,
      ).getNoticesStream(hostelId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final notices = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Notice Board', Icons.notifications_none),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddNoticeDialog,
                    tooltip: 'Post Notice',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: notices.length > 5 ? 5 : notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  final isUrgent = notice.type == NoticeType.urgent;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Card(
                      elevation: 2,
                      color: isUrgent ? Colors.red.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onLongPress: () => _deleteNotice(notice),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUrgent
                                        ? Icons.warning_amber
                                        : Icons.info_outline,
                                    color:
                                        isUrgent
                                            ? Colors.red
                                            : Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      notice.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            isUrgent
                                                ? Colors.red.shade900
                                                : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateHelpers.formatDate(notice.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: Text(
                                  notice.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '- ${notice.authorName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
        );
      },
    );
  }

  Future<void> _deleteNotice(Notice notice) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Notice?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      if (!mounted) return;
      await Provider.of<NoticeProvider>(
        context,
        listen: false,
      ).deleteNotice(notice.id!, userProvider.currentUser!.currentHostelId!);
    }
  }

  Widget _buildPersonalSummaryGrid() {
    if (_personalMonthlySummary == null ||
        _personalMonthlySummary!.memberBalances.isEmpty) {
      return const SizedBox.shrink();
    }
    final balance = _personalMonthlySummary!.memberBalances.first.balance;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        DashboardCard(
          title: 'My Meals',
          value: _personalMonthlySummary!.memberBalances.first.personalMeals
              .toStringAsFixed(1),
          icon: Icons.restaurant,
          color: Colors.blue,
        ),
        DashboardCard(
          title: 'Balance',
          value:
              balance >= 0
                  ? 'Get: ৳${balance.toStringAsFixed(0)}'
                  : 'Give: ৳${balance.abs().toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet,
          color: balance >= 0 ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMessStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildSectionTitle('Mess Status', Icons.dashboard)),
        if (_currentHostel != null)
          _isMonthOpen
              ? OutlinedButton(
                onPressed: _closeMonth,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Close Month'),
              )
              : OutlinedButton(
                onPressed: _startNextMonth,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Start Next'),
              ),
      ],
    );
  }

  Widget _buildMessStatusGrid(
    ExpensePredictionProvider expensePredictionProvider,
  ) {
    if (_overallMonthlySummary == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        DashboardCard(
          title: 'Total Meals',
          value: _overallMonthlySummary!.totalMessMeals.toStringAsFixed(0),
          icon: Icons.rice_bowl,
          color: Colors.indigo,
        ),
        DashboardCard(
          title: 'Total Expense',
          value:
              '৳${_overallMonthlySummary!.totalMessExpenses.toStringAsFixed(0)}',
          icon: Icons.shopping_cart,
          color: Colors.redAccent,
        ),
        DashboardCard(
          title: 'Meal Rate',
          value: '৳${_overallMonthlySummary!.mealRate.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: Colors.teal,
        ),
        Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, child) {
            return DashboardCard(
              title: 'Hand Cash',
              value:
                  '৳${expenseProvider.currentMessBalance.toStringAsFixed(0)}',
              icon: Icons.savings,
              color:
                  expenseProvider.currentMessBalance >= 0
                      ? Colors.green
                      : Colors.deepOrange,
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Meals',
        'icon': Icons.restaurant_menu,
        'route': AppRoutes.recordMeals,
        'color': Colors.orange,
      },
      {
        'title': 'Expenses',
        'icon': Icons.receipt,
        'route': AppRoutes.recordExpense,
        'color': Colors.redAccent,
      },
      {
        'title': 'Collections',
        'icon': Icons.attach_money,
        'route': AppRoutes.manageContributions,
        'color': Colors.green,
      },
      {
        'title': 'Market',
        'icon': Icons.shopping_bag,
        'route': AppRoutes.marketSchedule,
        'color': Colors.purple,
      },
      {
        'title': 'Reports',
        'icon': Icons.assignment,
        'route': AppRoutes.financialReport,
        'color': Colors.blueGrey,
      },
      {
        'title': 'Profile',
        'icon': Icons.person,
        'route': AppRoutes.profile,
        'color': Colors.blue,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          shadowColor: (action['color'] as Color).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap:
                () => Navigator.pushNamed(context, action['route'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: (action['color'] as Color).withValues(
                    alpha: 0.1,
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection(UserProvider userProvider) {
    if (userProvider.currentUser?.currentHostelId == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Feedback & Ratings', Icons.star_border),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Average Rating',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: StreamBuilder<List<MealFeedback>>(
                stream: Provider.of<MealFeedbackService>(
                  context,
                  listen: false,
                ).getRecentFeedbackStream(
                  userProvider.currentUser!.currentHostelId!,
                  limit: 2,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No recent feedback.'));
                  }
                  return Column(
                    children:
                        snapshot.data!
                            .map(
                              (fb) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: Colors.grey.shade100,
                                child: ListTile(
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 12,
                                    child: Text(
                                      fb.rating.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    fb.mealType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    fb.comment ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketDutiesSection(MarketScheduleProvider provider) {
    if (provider.upcomingMarketSchedules.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Upcoming Duties', Icons.calendar_month),
        const SizedBox(height: AppConstants.paddingMedium),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              provider.upcomingMarketSchedules.length > 3
                  ? 3
                  : provider.upcomingMarketSchedules.length,
          itemBuilder: (context, index) {
            final duty = provider.upcomingMarketSchedules[index];
            final member = Provider.of<MemberProvider>(
              context,
              listen: false,
            ).getMemberById(duty.memberId);

            return Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  duty.dutyTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${member?.name ?? "Unknown"} • ${DateHelpers.formatDate(duty.scheduleDate)}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    NoticeType selectedType = NoticeType.normal;

    showDialog(
      context: context,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder: (builderCtx, setDialogState) {
              return AlertDialog(
                title: const Text('Add New Notice'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<NoticeType>(
                      value: selectedType,
                      onChanged: (NoticeType? newValue) {
                        setDialogState(() {
                          selectedType = newValue!;
                        });
                      },
                      items:
                          NoticeType.values.map<DropdownMenuItem<NoticeType>>((
                            NoticeType value,
                          ) {
                            return DropdownMenuItem<NoticeType>(
                              value: value,
                              child: Text(
                                value.toString().split('.').last.toUpperCase(),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(builderCtx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty) {
                        try {
                          final userProvider = Provider.of<UserProvider>(
                            builderCtx,
                            listen: false,
                          );

                          final notice = Notice(
                            title: titleController.text,
                            description: descriptionController.text,
                            date: DateTime.now(),
                            type: selectedType,
                            authorName: userProvider.currentMember!.name,
                            hostelId:
                                userProvider.currentUser!.currentHostelId!,
                          );

                          await Provider.of<NoticeProvider>(
                            builderCtx,
                            listen: false,
                          ).addNotice(notice);

                          if (!builderCtx.mounted) return;

                          Navigator.pop(builderCtx);
                          ScaffoldMessenger.of(builderCtx).showSnackBar(
                            const SnackBar(
                              content: Text('Notice added successfully'),
                            ),
                          );
                        } catch (e) {
                          if (!builderCtx.mounted) return;
                          ScaffoldMessenger.of(builderCtx).showSnackBar(
                            SnackBar(content: Text('Failed to add notice: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Post Notice'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _closeMonth() async {
    if (_overallMonthlySummary == null || _currentHostel == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Close Month?'),
            content: Text(
              'Are you sure you want to CLOSE the month of ${DateHelpers.formatMonthYear(_currentMonth)}?\n\n'
              'This will freeze all calculations and save the history. You will not be able to add records to this month anymore.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Close Month'),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // 1. Create MonthlyHistory object
      final history = MonthlyHistory(
        hostelId: _currentHostel!.id!,
        month: _currentMonth.month,
        year: _currentMonth.year,
        totalMeals: _overallMonthlySummary!.totalMessMeals,
        totalExpenses: _overallMonthlySummary!.totalMessExpenses,
        totalContributions: _overallMonthlySummary!.totalMessContributions,
        mealRate: _overallMonthlySummary!.mealRate,
        memberBalances:
            _overallMonthlySummary!.memberBalances
                .map(
                  (mb) => MonthlyMemberBalance(
                    memberId: mb.memberId,
                    memberName: mb.memberName,
                    personalMeals: mb.personalMeals,
                    personalContributions: mb.personalContributions,
                    shareOfExpenses: mb.shareOfExpenses,
                    balance: mb.balance,
                  ),
                )
                .toList(),
        timestamp: DateTime.now(),
      );

      // 2. Save to History
      final historyService = Provider.of<MonthlyHistoryService>(
        context,
        listen: false,
      );
      await historyService.saveMonthlyHistory(history);

      // 3. Update Hostel
      await FirebaseFirestore.instance
          .collection('hostels')
          .doc(_currentHostel!.id)
          .update({'isMonthOpen': false});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Month Closed Successfully.')),
        );
        _fetchDashboardData(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error closing month: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNextMonth() async {
    if (_currentHostel == null) return;

    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Start Next Month?'),
            content: Text(
              'Are you sure you want to START the month of ${DateHelpers.formatMonthYear(nextMonth)}?\n\n'
              'This will open the new month for entries.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Start New Month'),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Update Hostel: activeMonth + 1, isMonthOpen = true
      await FirebaseFirestore.instance
          .collection('hostels')
          .doc(_currentHostel!.id)
          .update({
            'activeMonth': Timestamp.fromDate(nextMonth),
            'isMonthOpen': true,
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('New Month Started!')));
        _fetchDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting next month: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
