import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/user_role.dart';

/// Represents a member of the mess. A user can be associated with a member.
class Member {
  String? id; // Firestore Document ID
  String name;
  String? email; // Optional email
  UserRole role;
  String? fcmToken; // Firebase Cloud Messaging Token

  Member({
    this.id,
    required this.name,
    this.email,
    this.role = UserRole.member,
    this.fcmToken,
  });

  /// Converts a Member object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.toShortString(),
      'fcmToken': fcmToken,
    };
  }

  /// Creates a Member object from a Firestore DocumentSnapshot.
  factory Member.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      role: UserRoleExtension.fromShortString(data['role'] ?? 'member'),
      fcmToken: data['fcmToken'],
    );
  }

  /// Creates a copy of the Member object with updated values.
  Member copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? fcmToken,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
