import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a financial contribution made by a member.
class Contribution {
  String? id; // Firestore Document ID
  String memberId; // Reference to Member ID
  double amount;
  DateTime contributionDate;
  String? note; // Optional note (e.g., "Expense Refund")

  Contribution({
    this.id,
    required this.memberId,
    required this.amount,
    required this.contributionDate,
    this.note,
  });

  /// Converts a Contribution object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'amount': amount,
      'contributionDate': Timestamp.fromDate(contributionDate),
      'note': note,
    };
  }

  /// Creates a Contribution object from a Firestore DocumentSnapshot.
  factory Contribution.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contribution(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      contributionDate: (data['contributionDate'] as Timestamp).toDate(),
      note: data['note'] as String?,
    );
  }
}
