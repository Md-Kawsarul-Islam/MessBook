// lib/models/user_role.dart

/// Enum representing the different user roles in the application.
enum UserRole {
  admin,
  manager,
  member,
  none, // Used for initial state or unauthenticated users
}

/// Extension to convert UserRole enum to String and vice-versa.
extension UserRoleExtension on UserRole {
  String toShortString() {
    return toString().split('.').last;
  }

  // Corrected method name from 'fromString' to 'fromShortString'
  static UserRole fromShortString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'member':
        return UserRole.member;
      default:
        return UserRole.none;
    }
  }
}
