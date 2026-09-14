import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, rejected }

extension RequestStatusExtension on RequestStatus {
  String toShortString() {
    return toString().split('.').last;
  }

  static RequestStatus fromShortString(String status) {
    return RequestStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => RequestStatus.pending,
    );
  }
}

class ExpenseRequest {
  String? id;
  String memberId;
  String memberName;
  String hostelId;
  String items; // Description of items bought
  double amount;
  DateTime requestDate;
  RequestStatus status;
  DateTime? processedDate;

  ExpenseRequest({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.hostelId,
    required this.items,
    required this.amount,
    required this.requestDate,
    this.status = RequestStatus.pending,
    this.processedDate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      // 'hostelId': hostelId, // Typically stored in subcollection, but redundant field helps queries
      // Wait, standard practice here is subcollection: hostels/{hostelId}/expense_requests
      // So hostelId is implicit. But let's check Expense model. Expense is subcollection?
      // ExpenseService uses: hostels/{hostelId}/expenses.
      // So we will use: hostels/{hostelId}/expense_requests.
      // So we don't strictly need to store hostelId in the doc, but it hurts nothing.
      'items': items,
      'amount': amount,
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status.toShortString(),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
    };
  }

  factory ExpenseRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseRequest(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? 'Unknown',
      hostelId:
          '', // Contextual, or fetched from parent path if needed, but for now placeholder or we can ignore
      items: data['items'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      status: RequestStatusExtension.fromShortString(
        data['status'] ?? 'pending',
      ),
      processedDate:
          data['processedDate'] != null
              ? (data['processedDate'] as Timestamp).toDate()
              : null,
    );
  }
}
