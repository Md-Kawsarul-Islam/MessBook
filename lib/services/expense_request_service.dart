import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/expense_request.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:flutter/foundation.dart';

class ExpenseRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new request
  Future<bool> addRequest(ExpenseRequest request) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(request.hostelId)
          .collection('expense_requests')
          .add(request.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error adding expense request: $e');
      return false;
    }
  }

  // Stream pending requests for a hostel (Manager View)
  Stream<List<ExpenseRequest>> getPendingRequestsStream(String hostelId) {
    return _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('expense_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            ExpenseRequest request = ExpenseRequest.fromFirestore(doc);
            request.hostelId = hostelId;
            return request;
          }).toList();
        });
  }

  // Stream my requests for a member (Member View)
  Stream<List<ExpenseRequest>> getMyRequestsStream(
    String hostelId,
    String memberId,
  ) {
    return _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('expense_requests')
        .where('memberId', isEqualTo: memberId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            ExpenseRequest request = ExpenseRequest.fromFirestore(doc);
            request.hostelId = hostelId;
            return request;
          }).toList();
        });
  }

  // Approve request: Update status AND create Expense
  Future<bool> approveRequest(ExpenseRequest request) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore
            .collection('hostels')
            .doc(request.hostelId)
            .collection('expense_requests')
            .doc(request.id);

        // 1. Update Request Status
        transaction.update(requestRef, {
          'status': RequestStatus.approved.toShortString(),
          'processedDate': Timestamp.now(),
        });

        // 2. Create Expense
        final expenseRef =
            _firestore
                .collection('hostels')
                .doc(request.hostelId)
                .collection('expenses')
                .doc(); // Auto-ID

        final newExpense = Expense(
          id: expenseRef.id,
          description: '${request.items} (by ${request.memberName})',
          amount: request.amount,
          expenseDate:
              DateTime.now(), // Or use requestDate? Usually approval date is expense date for accounting.
          category: 'Entry Request', // Or General? Let's use specific category.
        );

        // Note: Expense model doesn't store memberId, but description includes name.
        transaction.set(expenseRef, newExpense.toFirestore());
        return true;
      });
    } catch (e) {
      debugPrint('Error approving request: $e');
      return false;
    }
  }

  // Reject request
  Future<bool> rejectRequest(String hostelId, String requestId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('expense_requests')
          .doc(requestId)
          .update({
            'status': RequestStatus.rejected.toShortString(),
            'processedDate': Timestamp.now(),
          });
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }
}
