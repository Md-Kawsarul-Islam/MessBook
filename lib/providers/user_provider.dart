import 'package:flutter/material.dart';
import 'package:mess_manager/models/user.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/models/hostel.dart';
import 'package:mess_manager/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for managing the current authenticated user's state.
class UserProvider with ChangeNotifier {
  User? _currentUser;
  Member? _currentMember;
  final AuthService _authService;

  UserProvider(this._authService);

  User? get currentUser => _currentUser;
  Member? get currentMember => _currentMember;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isMember => _currentUser?.role == UserRole.member;

  /// Loads the current user and their associated member on app start.
  Future<void> loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null) {
      // Accessing uid instead of id, assuming user.uid matches doc id
      // Since currentUser might have uid as null in some models if not careful,
      // but fromFirestore ensures it.
      if (_currentUser!.uid != null) {
        _currentMember = await _authService.getMemberForUser(
          _currentUser!.uid!,
        );
      }
    } else {
      _currentMember = null;
    }
    notifyListeners();
  }

  /// Handles user login.
  /// Note: Firebase Auth uses email, so we expect email here.
  Future<bool> login(String email, String password) async {
    _currentUser = await _authService.loginUser(email, password);
    if (_currentUser != null && _currentUser!.uid != null) {
      _currentMember = await _authService.getMemberForUser(_currentUser!.uid!);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Handles user logout.
  Future<void> logout() async {
    await _authService.logoutUser();
    _currentUser = null;
    _currentMember = null;
    notifyListeners();
  }

  /// Updates the current user object and notifies listeners.
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Updates the current member object and notifies listeners.
  void updateCurrentMember(Member member) {
    _currentMember = member;
    notifyListeners();
  }

  /// Fetches all hostels owned by the current user.
  Future<List<Hostel>> fetchOwnedHostels() async {
    if (_currentUser == null) return [];
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('hostels')
              .where('ownerId', isEqualTo: _currentUser!.uid)
              .get();
      return snapshot.docs.map((doc) => Hostel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching owned hostels: $e');
      return [];
    }
  }

  /// Switches the user's current hostel context.
  Future<bool> switchHostel(String hostelId) async {
    if (_currentUser == null) return false;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'currentHostelId': hostelId});

      // Reload user to refresh context
      await loadCurrentUser();
      return true;
    } catch (e) {
      debugPrint('Error switching hostel: $e');
      return false;
    }
  }

  Future<bool> createHostel(String name, String address) async {
    final hostelId = await _authService.createHostel(
      name: name,
      address: address,
    );
    if (hostelId != null) {
      await loadCurrentUser(); // Reload to get new role and member info
      return true;
    }
    return false;
  }

  Future<bool> joinHostel(String hostelId) async {
    final success = await _authService.joinHostel(hostelId);
    if (success) {
      await loadCurrentUser();
      return true;
    }
    return false;
  }
}
