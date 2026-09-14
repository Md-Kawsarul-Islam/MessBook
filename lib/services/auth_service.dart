import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mess_manager/models/user.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/models/hostel.dart';
import 'package:mess_manager/services/notification_service.dart';
import 'package:mess_manager/utils/app_constants.dart';

/// Service class for user authentication and authorization using Firebase.
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Registers a new user with email and password.
  /// Creates a Firestore document for the user and an associated Member document (unless Admin).
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
    bool isInitialAdmin = false,
  }) async {
    // Create user in Firebase Auth
    final firebase_auth.UserCredential userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    final String uid = userCredential.user!.uid;
    final String? fcmToken = await _notificationService.getToken();

    UserRole role = UserRole.member;
    String? memberId;

    if (isInitialAdmin) {
      role = UserRole.admin;
      memberId = null;
    } else {
      // Create Member document first
      final memberRef =
          _firestore.collection(AppConstants.collectionMembers).doc();
      final member = Member(
        id: memberRef.id,
        name: name,
        email: email,
        fcmToken: fcmToken,
      );
      await memberRef.set(member.toFirestore());
      memberId = memberRef.id;
      role = UserRole.member;
    }

    // Create User document in Firestore
    final user = User(
      uid: uid,
      username: username,
      email: email,
      role: role,
      isActive: true, // Default to active? Or wait for admin approval?
      memberId: memberId,
    );

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .set(user.toFirestore());

    return user;
  }

  /// Logs in a user.
  Future<User?> loginUser(String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // Fetch user details from Firestore
      final DocumentSnapshot userDoc =
          await _firestore
              .collection(AppConstants.collectionUsers)
              .doc(uid)
              .get();

      if (userDoc.exists) {
        final user = User.fromFirestore(userDoc);
        if (user.isActive) {
          // Update FCM Token on successful login if Member exists
          if (user.memberId != null) {
            try {
              final token = await _notificationService.getToken();
              if (token != null) {
                await _firestore
                    .collection(AppConstants.collectionMembers)
                    .doc(user.memberId)
                    .update({'fcmToken': token});
              }
            } catch (e) {
              debugPrint('Failed to update FCM token during login: $e');
              // Continue login even if token update fails
            }
          }
          return user;
        } else {
          await logoutUser();
          throw Exception('User account is inactive.');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error logging in user: $e');
      return null;
    }
  }

  /// Logs out the current user.
  Future<void> logoutUser() async {
    await _firebaseAuth.signOut();
  }

  /// Checks if any admin user exists.
  Future<bool> isAdminRegistered() async {
    try {
      final QuerySnapshot result =
          await _firestore
              .collection(AppConstants.collectionUsers)
              .where('role', isEqualTo: UserRole.admin.toShortString())
              .limit(1)
              .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking admin registration: $e');
      // If permission is denied, it means security rules are active (Authenticated Only).
      // This implies the system is set up, so we assume an Admin exists to force the user to Login.
      if (e.toString().contains('permission-denied')) {
        return true;
      }
      return false;
    }
  }

  /// Gets the currently logged-in user details from Firestore.
  Future<User?> getCurrentUser() async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final DocumentSnapshot userDoc =
            await _firestore
                .collection(AppConstants.collectionUsers)
                .doc(firebaseUser.uid)
                .get();
        if (userDoc.exists) {
          return User.fromFirestore(userDoc);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Returns the current Firebase Auth ID.
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  /// Retrieves the Member associated with a given User ID.
  Future<Member?> getMemberForUser(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore
              .collection(AppConstants.collectionUsers)
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final user = User.fromFirestore(userDoc);
        if (user.memberId != null) {
          DocumentReference memberRef;

          if (user.currentHostelId != null) {
            memberRef = _firestore
                .collection('hostels')
                .doc(user.currentHostelId)
                .collection('members')
                .doc(user.memberId);
          } else {
            // Legacy fallback or global member
            memberRef = _firestore
                .collection(AppConstants.collectionMembers)
                .doc(user.memberId);
          }

          final DocumentSnapshot memberDoc = await memberRef.get();

          if (memberDoc.exists) {
            final member = Member.fromFirestore(memberDoc);
            // Ensure the member object has the correct role from the User record
            return member.copyWith(role: user.role);
          }
        } else if (user.role == UserRole.admin) {
          // Admin might not have a Member document, but we return a "Virtual" member if needed
          return Member(
            id: 'admin_${user.uid}',
            name: user.username,
            email: user.email,
            role: UserRole.admin,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting member for user: $e');
      return null;
    }
  }

  /// Retrieves all users for a specific hostel.
  Future<List<User>> getAllUsers(String hostelId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(AppConstants.collectionUsers)
              .where('currentHostelId', isEqualTo: hostelId)
              .get();

      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting hostel users: $e');
      return [];
    }
  }

  /// Updates a user's active status.
  Future<bool> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      debugPrint('Error updating user active status: $e');
      return false;
    }
  }

  /// Changes a user's role and manages associated member entries.
  Future<bool> changeUserRole(String userId, UserRole newRole) async {
    try {
      final userDocRef = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId);
      final userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) return false;

      User user = User.fromFirestore(userSnapshot);
      String? updatedMemberId = user.memberId;

      if (newRole == UserRole.admin) {
        // If changing to Admin, we typically strictly don't associate with a member in this schema,
        // OR we can keep it. The original logic removed it.
        // Let's keep consistent with original logic: Admin = no memberId.
        updatedMemberId = null;
      } else {
        if (user.memberId == null) {
          // Create new member if none exists
          final memberRef =
              _firestore.collection(AppConstants.collectionMembers).doc();
          final newMember = Member(
            id: memberRef.id,
            name: user.username,
            email: user.email,
          );
          await memberRef.set(newMember.toFirestore());
          updatedMemberId = memberRef.id;
        }
      }

      await userDocRef.update({
        'role': newRole.toShortString(),
        'memberId': updatedMemberId,
      });

      return true;
    } catch (e) {
      debugPrint('Error changing user role: $e');
      return false;
    }
  }

  /// Deletes a user (Note: This only deletes Firestore data.
  /// Deleting Firebase Auth user requires Admin SDK or re-authentication of that user).
  Future<bool> deleteUser(String userId) async {
    try {
      final userDocRef = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId);
      final userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) return false;
      User user = User.fromFirestore(userSnapshot);

      await userDocRef.delete();

      if (user.memberId != null) {
        await _firestore
            .collection(AppConstants.collectionMembers)
            .doc(user.memberId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Creates a new Hostel and assigns the current user as Admin.
  /// Generates a unique 4-character random ID (Invite Code).
  Future<String?> createHostel({
    required String name,
    required String address,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("No authenticated user");

      // Generate unique 4-char ID
      String inviteCode = _generateRandomId();
      bool isUnique = false;
      int attempts = 0;

      while (!isUnique && attempts < 10) {
        final query =
            await _firestore
                .collection('hostels')
                .where('inviteCode', isEqualTo: inviteCode)
                .get();
        if (query.docs.isEmpty) {
          isUnique = true;
        } else {
          inviteCode = _generateRandomId();
          attempts++;
        }
      }

      if (!isUnique) throw Exception("Failed to generate unique Hostel ID.");

      final hostelRef = _firestore.collection('hostels').doc();
      final hostel = Hostel(
        id: hostelRef.id,
        name: name,
        address: address,
        inviteCode: inviteCode, // Auto-generated ID
        ownerId: user.uid,
        createdAt: DateTime.now(),
      );

      await hostelRef.set(hostel.toFirestore());

      // Update User: Set role to Admin and currentHostelId
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .update({
            'role': UserRole.admin.toShortString(),
            'currentHostelId': hostelRef.id,
          });

      // Create a Member entry for the admin in the new hostel context
      final memberRef = hostelRef.collection('members').doc();
      final member = Member(
        id: memberRef.id,
        name: user.displayName ?? user.email!.split('@')[0],
        email: user.email,
        role: UserRole.admin,
      );
      await memberRef.set(member.toFirestore());

      // Link User to this Member ID (Optional but good for quick lookup)
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .update({'memberId': memberRef.id});

      return hostelRef.id;
    } catch (e) {
      debugPrint('Error creating hostel: $e');
      return null;
    }
  }

  String _generateRandomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  /// Joins an existing hostel by ID.
  Future<bool> joinHostel(String hostelId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("No authenticated user");

      DocumentSnapshot? hostelDoc;

      // 1. Try by ID
      final docRef = _firestore.collection('hostels').doc(hostelId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        hostelDoc = docSnap;
      } else {
        // 2. Try by Invite Code
        final codeQuery =
            await _firestore
                .collection('hostels')
                .where('inviteCode', isEqualTo: hostelId)
                .limit(1)
                .get();

        if (codeQuery.docs.isNotEmpty) {
          hostelDoc = codeQuery.docs.first;
        }
        // Removed Name lookup as per requirement "Only this generated ID will be used"
      }

      if (hostelDoc == null || !hostelDoc.exists) {
        throw Exception("Hostel not found. Check the ID (4-char code).");
      }

      // Use the actual ID from the found document
      final String actualHostelId = hostelDoc.id;

      // Create Member in the hostel
      final memberRef =
          _firestore
              .collection('hostels')
              .doc(actualHostelId)
              .collection('members')
              .doc();

      final member = Member(
        id: memberRef.id,
        name: user.displayName ?? user.email!.split('@')[0],
        email: user.email,
        role: UserRole.member,
      );

      await memberRef.set(member.toFirestore());

      // Update User
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .update({
            'currentHostelId': actualHostelId,
            'memberId': memberRef.id,
            'role': UserRole.member.toShortString(),
          });

      return true;
    } catch (e) {
      debugPrint('Error joining hostel: $e');
      return false; // Or rethrow to show specific error in UI
    }
  }
}
