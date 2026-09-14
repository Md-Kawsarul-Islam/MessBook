import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/monthly_summary.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/market_schedule_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:mess_manager/widgets/dashboard_card.dart';
import 'package:mess_manager/providers/notice_provider.dart';
import 'package:mess_manager/models/notice.dart';
import 'package:mess_manager/providers/meal_feedback_provider.dart';
import 'package:mess_manager/models/meal_feedback.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Member dashboard displaying personal summaries and navigation to personal history.
class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final DateTime _currentMonth = DateTime.now();
  bool _isLoading = false;
  MonthlySummary? _personalMonthlySummary;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Fetches all necessary data for the member dashboard.
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
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );

      final String? hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );

      final String? currentMemberId =
          userProvider.currentMember?.id; // String ID
      final String? currentMemberName = userProvider.currentMember?.name;

      if (currentMemberId == null || currentMemberName == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch overall mess data for meal rate calculation
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
      await marketScheduleProvider.fetchUpcomingMarketSchedules(
        hostelId,
      ); // Fetch for display
      await memberProvider.fetchAllMembers(
        hostelId,
      ); // Ensure all members are fetched for context

      final double totalMessMeals = mealProvider.monthlyMessMeals;
      final double totalMessExpenses = expenseProvider.monthlyTotalExpenses;
      final double totalMessContributions =
          expenseProvider.monthlyTotalContributions;

      double mealRate = 0.0;
      if (totalMessMeals > 0) {
        mealRate = totalMessExpenses / totalMessMeals;
      }

      // Calculate personal balance for the CURRENTLY LOGGED-IN MEMBER
      final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
        currentMemberId,
        _currentMonth.month,
        _currentMonth.year,
        hostelId,
      );
      final personalContributionsList = await expenseProvider
          .fetchContributionsByMember(currentMemberId, hostelId);
      final personalContributions = personalContributionsList
          .where(
            (c) => DateHelpers.isSameDay(
              DateHelpers.firstDayOfMonth(_currentMonth),
              DateHelpers.firstDayOfMonth(c.contributionDate),
            ),
          )
          .fold(0.0, (sum, item) => sum + item.amount);

      final shareOfExpenses = personalMeals * mealRate;
      final balance = personalContributions - shareOfExpenses;

      // Create a MonthlySummary specifically for the current member's balance
      _personalMonthlySummary = MonthlySummary(
        month: _currentMonth.month,
        year: _currentMonth.year,
        totalMessMeals: totalMessMeals,
        totalMessExpenses: totalMessExpenses,
        totalMessContributions: totalMessContributions,
        mealRate: mealRate,
        memberBalances: [
          // This list now contains only the current member's balance
          MemberBalance(
            memberId: currentMemberId,
            memberName: currentMemberName,
            personalMeals: personalMeals,
            personalContributions: personalContributions,
            shareOfExpenses: shareOfExpenses,
            balance: balance,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error fetching member dashboard data: $e');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            color: Colors.white,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.groupChat),
            tooltip: 'Group Chat',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
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
                            // Rate Meal Action - Prominent
                            _buildRateMealCard(),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Personal Stats
                            _buildSectionTitle(
                              'Your Snapshot',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildPersonalSummaryGrid(),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Overall Mess Stats
                            _buildSectionTitle(
                              'Mess Status',
                              Icons.dashboard_outlined,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildMessStatusGrid(),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Upcoming Duties
                            _buildMarketDutiesSection(marketScheduleProvider),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Quick Actions
                            _buildSectionTitle(
                              'Quick Actions',
                              Icons.grid_view,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            _buildActionsGrid(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                'Member',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: _buildSectionTitle(
                'Notice Board',
                Icons.notifications_none,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
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
                                          isUrgent ? Colors.red.shade900 : null,
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
                          ],
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

  Widget _buildRateMealCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFeedbackDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rate_rounded,
                  size: 40,
                  color: Colors.amber,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate Today\'s Meal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Share your feedback regarding the food quality.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          onTap: () {
            debugPrint("My Meals tapped");
            Navigator.pushNamed(
              context,
              AppRoutes.personalMealHistory,
            );
          },
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

  Widget _buildMessStatusGrid() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final totalMessMeals =
            Provider.of<MealProvider>(context).monthlyMessMeals;
        final totalMessExpenses = expenseProvider.monthlyTotalExpenses;
        double mealRate = 0.0;
        if (totalMessMeals > 0) {
          mealRate = totalMessExpenses / totalMessMeals;
        }

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
              value: totalMessMeals.toStringAsFixed(0),
              icon: Icons.rice_bowl,
              color: Colors.indigo,
            ),
            DashboardCard(
              title: 'Total Expense',
              value: '৳${totalMessExpenses.toStringAsFixed(0)}',
              icon: Icons.shopping_cart,
              color: Colors.redAccent,
            ),
            DashboardCard(
              title: 'Meal Rate',
              value: '৳${mealRate.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.teal,
            ),
            DashboardCard(
              title: 'Hand Cash',
              value:
                  '৳${expenseProvider.currentMessBalance.toStringAsFixed(0)}',
              icon: Icons.savings,
              color:
                  expenseProvider.currentMessBalance >= 0
                      ? Colors.green
                      : Colors.deepOrange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketDutiesSection(MarketScheduleProvider provider) {
    if (provider.upcomingMarketSchedules.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter duties for current member
    final myDuties =
        provider.upcomingMarketSchedules.where((duty) {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          return duty.memberId == userProvider.currentMember?.id;
        }).toList();

    if (myDuties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Your Upcoming Duties', Icons.calendar_month),
        const SizedBox(height: AppConstants.paddingMedium),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: myDuties.length,
          itemBuilder: (context, index) {
            final duty = myDuties[index];
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
                  'Date: ${DateHelpers.formatDate(duty.scheduleDate)}\n${duty.description}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'My History',
        'icon': Icons.history,
        'route': AppRoutes.personalMealHistory,
        'color': Colors.blue,
      },
      {
        'title': 'Deposits',
        'icon': Icons.account_balance,
        'route': AppRoutes.personalContributionHistory,
        'color': Colors.green,
      },
      {
        'title': 'My Expenses',
        'icon': Icons.receipt_long,
        'route': AppRoutes.personalExpenseHistory,
        'color': Colors.orange,
      },
      {
        'title': 'Market Duties',
        'icon': Icons.calendar_today,
        'route': AppRoutes.personalMarketDuty,
        'color': Colors.purple,
      },
      {
        'title': 'Financial Report',
        'icon': Icons.analytics,
        'route': AppRoutes.financialReport,
        'color': Colors.teal,
      },
      {
        'title': 'Entry Request',
        'icon': Icons.add_circle,
        'route': AppRoutes.requestExpense,
        'color': Colors.redAccent,
      },
      {
        'title': 'Profile',
        'icon': Icons.person,
        'route': AppRoutes.profile,
        'color': Colors.blueGrey,
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
                    fontSize: 11,
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

  void _showFeedbackDialog() {
    double rating = 3.0;
    String mealType = 'Dinner';
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Rate Today\'s Meal'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RatingBar.builder(
                        initialRating: 3,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ),
                        itemBuilder:
                            (context, _) =>
                                const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (updatedRating) {
                          setDialogState(() => rating = updatedRating);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: mealType,
                        decoration: const InputDecoration(
                          labelText: 'Meal Type',
                        ),
                        items:
                            ['Breakfast', 'Lunch', 'Dinner']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => mealType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comments (Optional)',
                          hintText: 'Too spicy, excellent, etc.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      final memberId = userProvider.currentMember?.id;
                      final hostelId =
                          userProvider.currentUser?.currentHostelId;

                      if (memberId == null || hostelId == null) return;

                      final feedback = MealFeedback(
                        memberId: memberId,
                        memberName:
                            userProvider.currentMember?.name ?? 'Unknown',
                        hostelId: hostelId,
                        rating: rating,
                        comment:
                            commentController
                                .text, // renamed from _commentController
                        date: DateTime.now(),
                        mealType: mealType,
                      );

                      await Provider.of<MealFeedbackProvider>(
                        context,
                        listen: false,
                      ).submitFeedback(feedback);

                      if (!context.mounted) return;
                      // Close dialog
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback submitted!')),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
