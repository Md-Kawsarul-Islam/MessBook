import 'package:flutter/material.dart';
import 'package:mess_manager/models/user.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/routes.dart';

class NavigationHelper {
  /// Navigates the user to the appropriate screen based on their authentication state,
  /// hostel association, and role.
  ///
  /// Uses [pushNamedAndRemoveUntil] to clear the navigation stack, ensuring
  /// user cannot go back to login/splash screens.
  static void navigateBasedOnAuth(BuildContext context, User? user) {
    if (user == null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.memberLogin, (route) => false);
      return;
    }

    // Admins bypass hostel selection
    if (user.role == UserRole.admin) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
      return;
    }

    if (user.currentHostelId == null) {
      // No hostel selected or created -> Go to Selection
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.hostelSelection, (route) => false);
      return;
    }

    // Role-based navigation
    String routeName;
    switch (user.role) {
      case UserRole.admin:
        routeName = AppRoutes.adminDashboard;
        break;
      case UserRole.manager:
        routeName = AppRoutes.managerDashboard;
        break;
      case UserRole.member:
        routeName = AppRoutes.memberDashboard;
        break;
      default:
        routeName = AppRoutes.memberLogin;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }
}
