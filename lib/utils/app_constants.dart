// lib/utils/app_constants.dart

/// Defines global constants used throughout the application.
class AppConstants {
  // Padding and spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // Text strings
  static const String appTitle = 'MessBook';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String adminLoginTitle = 'Admin Login';
  static const String memberLoginTitle = 'Member Login';
  static const String usernameHint = 'Username';
  static const String passwordHint = 'Password';
  static const String confirmPasswordHint = 'Confirm Password';
  static const String nameHint = 'Name';
  static const String emailHint = 'Email';
  static const String saveButton = 'Save';
  static const String deleteButton = 'Delete';
  static const String editButton = 'Edit';
  static const String recordButton = 'Record';
  static const String viewButton = 'View';
  static const String manageButton = 'Manage';
  static const String logoutButton = 'Logout';
  static const String resetDatabaseButton = 'Reset Database';
  static const String toggleActiveStatus = 'Toggle Active';
  static const String changeRole = 'Change Role';
  static const String deleteUser = 'Delete User';
  static const String recordMeals = 'Record Meals';
  static const String recordExpense = 'Record Expense';
  static const String manageContributions = 'Manage Contributions';
  static const String marketSchedule = 'Market Schedule';
  static const String financialReport = 'Financial Report';
  static const String profile = 'Profile';
  static const String personalMealHistory = 'Personal Meal History';
  static const String personalContributionHistory =
      'Personal Contribution History';
  static const String personalExpenseHistory = 'Personal Expense History';
  static const String personalMarketDuty = 'Personal Market Duty';
  static const String registrationScreenTitle = 'Register Admin';
  static const String adminDashboard = 'Admin Dashboard';
  static const String managerDashboard = 'Manager Dashboard';
  static const String memberDashboard = 'Member Dashboard';

  // Firestore Collection names
  static const String collectionUsers = 'users';
  static const String collectionMembers = 'members';
  static const String collectionMealEntries = 'mealEntries';
  static const String collectionExpenses = 'expenses';
  static const String collectionContributions = 'contributions';
  static const String collectionMarketSchedules = 'marketSchedules';

  // User role string values
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleMember = 'member';
  static const String roleNone = 'none';
}
