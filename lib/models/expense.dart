import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a mess expense.
class Expense {
  String? id; // Firestore Document ID
  String description;
  double amount;
  DateTime expenseDate;
  String category;
  // Removed incurredByMemberId as expenses are from general mess balance
  // In a more complex app, we might want to track who added the expense (createdBy)

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.category = 'General',
  });

  /// Converts an Expense object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'category': category,
    };
  }

  /// Creates an Expense object from a Firestore DocumentSnapshot.
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: (data['expenseDate'] as Timestamp).toDate(),
      category: data['category'] ?? 'General',
    );
  }
}
