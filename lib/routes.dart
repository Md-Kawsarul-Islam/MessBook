// lib/routes.dart

import 'package:flutter/material.dart';
import 'package:mess_manager/screens/auth/splash_screen.dart';
import 'package:mess_manager/screens/auth/admin_login_screen.dart';
import 'package:mess_manager/screens/auth/member_login_screen.dart';
import 'package:mess_manager/screens/auth/registration_screen.dart';
import 'package:mess_manager/screens/admin/admin_dashboard_screen.dart';
import 'package:mess_manager/screens/manager/manager_dashboard_screen.dart';
import 'package:mess_manager/screens/manager/record_meals_screen.dart';
import 'package:mess_manager/screens/manager/record_expense_screen.dart';
import 'package:mess_manager/screens/manager/manage_contributions_screen.dart';
import 'package:mess_manager/screens/manager/market_schedule_screen.dart';
import 'package:mess_manager/screens/member/member_dashboard_screen.dart';
import 'package:mess_manager/screens/member/personal_contribution_history_screen.dart';
import 'package:mess_manager/screens/member/personal_expense_history_screen.dart';
import 'package:mess_manager/screens/member/personal_market_duty_screen.dart';
import 'package:mess_manager/screens/member/personal_meal_history_screen.dart';
import 'package:mess_manager/screens/shared/financial_report_screen.dart';
import 'package:mess_manager/screens/shared/report_generation_screen.dart';
import 'package:mess_manager/screens/shared/profile_screen.dart';
import 'package:mess_manager/screens/auth/hostel_selection_screen.dart';
import 'package:mess_manager/screens/auth/create_hostel_screen.dart';
import 'package:mess_manager/screens/member/expense_request_screen.dart';
import 'package:mess_manager/screens/manager/manage_requests_screen.dart';
import 'package:mess_manager/screens/shared/group_chat_screen.dart';
import 'package:mess_manager/screens/admin/admin_backup_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String adminLogin = '/admin_login';
  static const String memberLogin = '/member_login';
  static const String registration = '/registration';
  static const String adminDashboard = '/admin_dashboard';
  static const String managerDashboard = '/manager_dashboard';
  static const String recordMeals = '/record_meals';
  static const String recordExpense = '/record_expense';
  static const String manageContributions = '/manage_contributions';
  static const String marketSchedule = '/market_schedule';
  static const String financialReport = '/financial_report';
  static const String profile = '/profile';
  static const String memberDashboard = '/member_dashboard';
  static const String personalMealHistory = '/personal_meal_history';
  static const String personalContributionHistory =
      '/personal_contribution_history';
  static const String personalExpenseHistory = '/personal_expense_history';
  static const String personalMarketDuty = '/personal_market_duty';
  static const String generateReport = '/generate_report';
  static const String hostelSelection = '/hostel_selection';
  static const String createHostel = '/create_hostel';
  static const String requestExpense = '/request_expense';
  static const String manageRequests = '/manage_requests';
  static const String groupChat = '/group_chat';
  static const String adminBackup = '/admin_backup';

  // FIX: Added 'static' keyword to the generateRoute method.
  // The return type 'Route<dynamic>?' is also explicitly defined as per Flutter's routing API.
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case memberLogin:
        return MaterialPageRoute(builder: (_) => const MemberLoginScreen());
      case registration:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (_) => RegistrationScreen(
                isAdminRegistration: args?['isAdminRegistration'] ?? false,
              ),
        );
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case managerDashboard:
        return MaterialPageRoute(
          builder: (_) => const ManagerDashboardScreen(),
        );
      case recordMeals:
        return MaterialPageRoute(builder: (_) => const RecordMealsScreen());
      case recordExpense:
        return MaterialPageRoute(builder: (_) => const RecordExpenseScreen());
      case manageContributions:
        return MaterialPageRoute(
          builder: (_) => const ManageContributionsScreen(),
        );
      case marketSchedule:
        return MaterialPageRoute(builder: (_) => const MarketScheduleScreen());
      case financialReport:
        return MaterialPageRoute(builder: (_) => const FinancialReportScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case memberDashboard:
        return MaterialPageRoute(builder: (_) => const MemberDashboardScreen());
      case personalMealHistory:
        return MaterialPageRoute(
          builder: (_) => const PersonalMealHistoryScreen(),
        );
      case personalContributionHistory:
        return MaterialPageRoute(
          builder: (_) => const PersonalContributionHistoryScreen(),
        );
      case personalExpenseHistory:
        return MaterialPageRoute(
          builder: (_) => const PersonalExpenseHistoryScreen(),
        );
      case personalMarketDuty:
        return MaterialPageRoute(
          builder: (_) => const PersonalMarketDutyScreen(),
        );
      case generateReport:
        return MaterialPageRoute(
          builder: (_) => const ReportGenerationScreen(),
        );
      case hostelSelection:
        return MaterialPageRoute(builder: (_) => const HostelSelectionScreen());
      case createHostel:
        return MaterialPageRoute(builder: (_) => const CreateHostelScreen());
      case requestExpense:
        return MaterialPageRoute(builder: (_) => const ExpenseRequestScreen());
      case manageRequests:
        return MaterialPageRoute(builder: (_) => const ManageRequestsScreen());
      case groupChat:
        return MaterialPageRoute(builder: (_) => const GroupChatScreen());
      case adminBackup:
        return MaterialPageRoute(builder: (_) => const AdminBackupScreen());
      default:
        // Return a simple error page for unknown routes
        return MaterialPageRoute(
          builder: (_) => const Center(child: Text('Error: Unknown route')),
        );
    }
  }
}
