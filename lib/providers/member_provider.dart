import 'package:flutter/material.dart';
import 'package:mess_manager/models/member.dart';
import 'package:mess_manager/services/member_service.dart';
import 'package:mess_manager/services/auth_service.dart';

/// Provider for managing Member data.
class MemberProvider with ChangeNotifier {
  final MemberService _memberService;
  final AuthService _authService;
  List<Member> _members = [];
  List<Member> _activeMembers =
      []; // Members associated with active non-admin users

  MemberProvider(this._memberService, this._authService);

  List<Member> get members => _members;
  List<Member> get activeMembers => _activeMembers;

  /// Fetches all members for a specific hostel.
  Future<void> fetchAllMembers(String hostelId) async {
    _members = await _memberService.getAllMembers(hostelId);
    await _fetchActiveMembersInternal(hostelId);
    notifyListeners();
  }

  /// Fetches only members who are associated with active non-admin users for a specific hostel.
  Future<void> fetchActiveMembers(String hostelId) async {
    _members = await _memberService.getAllMembers(hostelId);
    await _fetchActiveMembersInternal(hostelId);
    notifyListeners();
  }

  /// Internal helper to fetch active members without notifying listeners immediately.
  Future<void> _fetchActiveMembersInternal(String hostelId) async {
    // Optimization: query users by hostelId if possible, but for now we rely on the existing pattern
    // or maybe AuthService can just return users for this hostel?
    // Let's stick to existing logic for safety, but we might filter users by hostelId if AuthService supported it.
    // Ideally: _authService.getUsersByHostel(hostelId)
    // For now, assuming getAllUsers() returns valid users.
    // Note: If we have multiple hostels, this logic finds ALL active users in the system.
    // Then filters members matching those users. Since _members is scoped to hostelId,
    // we only get active members OF THIS HOSTEL. So logic holds.
    final allUsers = await _authService.getAllUsers(hostelId);
    final activeUserMemberIds =
        allUsers
            .where(
              (user) =>
                  user.isActive &&
                  user.memberId != null &&
                  user.currentHostelId == hostelId,
            )
            .map((user) => user.memberId!)
            .toSet();

    _activeMembers =
        _members
            .where(
              (member) =>
                  member.id != null && activeUserMemberIds.contains(member.id),
            )
            .toList();
  }

  /// Adds a new member to a specific hostel.
  Future<bool> addMember(Member member, String hostelId) async {
    final String id = await _memberService.addMember(member, hostelId);
    if (id.isNotEmpty) {
      await fetchAllMembers(hostelId); // Refresh list
      return true;
    }
    return false;
  }

  /// Updates an existing member in a specific hostel.
  Future<bool> updateMember(Member member, String hostelId) async {
    final bool success = await _memberService.updateMember(member, hostelId);
    if (success) {
      await fetchAllMembers(hostelId); // Refresh list
    }
    return success;
  }

  /// Deletes a member from a specific hostel.
  Future<bool> deleteMember(String id, String hostelId) async {
    final bool success = await _memberService.deleteMember(id, hostelId);
    if (success) {
      await fetchAllMembers(hostelId); // Refresh list
    }
    return success;
  }

  /// Retrieves a member by ID from the currently loaded list.
  Member? getMemberById(String id) {
    try {
      return _members.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }
}
