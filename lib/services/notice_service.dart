import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/notice.dart';
import 'package:flutter/foundation.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new notice
  Future<bool> addNotice(Notice notice) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(notice.hostelId)
          .collection('notices')
          .add(notice.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error adding notice: $e');
      return false;
    }
  }

  // Delete a notice
  Future<bool> deleteNotice(String noticeId, String hostelId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('notices')
          .doc(noticeId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notice: $e');
      return false;
    }
  }

  // Fetch notices for a hostel (Ordered by Date Descending)
  Stream<List<Notice>> getNoticesStream(String hostelId) {
    return _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('notices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
        });
  }
}
