import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/member.dart';

/// Service class for managing member data in Firestore.
class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new member to a specific hostel.
  Future<String> addMember(Member member, String hostelId) async {
    final docRef =
        _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection('members')
            .doc();

    // Check if ID is already set on member (unlikely for new, but good practice)
    final memberData = member.toFirestore();
    // We expect the caller to set the ID on the object if needed,
    // but typically we let Firestore generate it or use the one provided.
    // Here we use docRef.id.

    // If the member object passed in has an ID (e.g. reused), we might want to respect it,
    // but 'add' suggests new. logic:
    await docRef.set(memberData);
    return docRef.id;
  }

  /// Retrieves all members of a specific hostel.
  Future<List<Member>> getAllMembers(String hostelId) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection('members')
            .get();
    return snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList();
  }

  /// Retrieves a single member by ID from a specific hostel.
  Future<Member?> getMemberById(String hostelId, String memberId) async {
    final DocumentSnapshot doc =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection('members')
            .doc(memberId)
            .get();
    if (doc.exists) {
      return Member.fromFirestore(doc);
    }
    return null;
  }

  /// Updates an existing member in a specific hostel.
  Future<bool> updateMember(Member member, String hostelId) async {
    if (member.id == null) return false;
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('members')
          .doc(member.id)
          .update(member.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a member by ID from a specific hostel.
  Future<bool> deleteMember(String hostelId, String memberId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('members')
          .doc(memberId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
