// lib/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/user_role.dart';

/// Represents a user in the application with authentication details and a role.
class User {
  String? uid; // Firestore Document ID
  String username;
  String email; // Added email field
  UserRole role;
  bool isActive;
  String? memberId; // Reference to Member document ID in the current hostel
  String?
  currentHostelId; // ID of the hostel the user is currently interacting with

  User({
    this.uid,
    required this.username,
    required this.email,
    this.role = UserRole.member,
    this.isActive = true,
    this.memberId,
    this.currentHostelId,
  });

  /// Converts a User object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'role': role.toShortString(),
      'isActive': isActive,
      'memberId': memberId,
      'currentHostelId': currentHostelId,
    };
  }

  /// Creates a User object from a Firestore DocumentSnapshot.
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: UserRoleExtension.fromShortString(data['role'] ?? 'member'),
      isActive: data['isActive'] ?? true,
      memberId: data['memberId'],
      currentHostelId: data['currentHostelId'],
    );
  }

  User copyWith({
    String? uid,
    String? username,
    String? email,
    UserRole? role,
    bool? isActive,
    String? memberId,
    String? currentHostelId,
  }) {
    return User(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      memberId: memberId ?? this.memberId,
      currentHostelId: currentHostelId ?? this.currentHostelId,
    );
  }
}
