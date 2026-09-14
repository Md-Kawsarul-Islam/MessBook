import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/expense.dart';
import 'package:mess_manager/models/contribution.dart';
import 'package:mess_manager/utils/app_constants.dart';

/// Service class for managing expense and contribution related data in Firestore.
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Expenses ---

  /// Adds a new expense to a specific hostel.
  Future<String> addExpense(Expense expense, String hostelId) async {
    final docRef =
        _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionExpenses)
            .doc();
    await docRef.set(expense.toFirestore());
    return docRef.id;
  }

  /// Retrieves all expenses for a specific hostel.
  Future<List<Expense>> getAllExpenses(String hostelId) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionExpenses)
            .orderBy('expenseDate', descending: true)
            .get();
    return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
  }

  /// Updates an existing expense in a hostel.
  Future<bool> updateExpense(Expense expense, String hostelId) async {
    if (expense.id == null) return false;
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionExpenses)
          .doc(expense.id)
          .update(expense.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes an expense by its ID from a hostel.
  Future<bool> deleteExpense(String id, String hostelId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionExpenses)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculates the total expenses for the entire mess for a given month and year in a hostel.
  Future<double> getMonthlyTotalExpensesForMess(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionExpenses)
              .where(
                'expenseDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('expenseDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Retrieves all expenses for a given month and year in a hostel.
  Future<List<Expense>> getExpensesForMonth(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionExpenses)
              .where(
                'expenseDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('expenseDate', isLessThan: Timestamp.fromDate(endOfMonth))
              .orderBy('expenseDate', descending: true)
              .get();

      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Contributions ---

  /// Adds a new contribution to a specific hostel.
  Future<String> addContribution(
    Contribution contribution,
    String hostelId,
  ) async {
    final docRef =
        _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionContributions)
            .doc();
    await docRef.set(contribution.toFirestore());
    return docRef.id;
  }

  /// Retrieves all contributions for a specific hostel.
  Future<List<Contribution>> getAllContributions(String hostelId) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionContributions)
            .orderBy('contributionDate', descending: true)
            .get();
    return snapshot.docs.map((doc) => Contribution.fromFirestore(doc)).toList();
  }

  /// Retrieves contributions by a specific member in a hostel.
  Future<List<Contribution>> getContributionsByMember(
    String memberId,
    String hostelId,
  ) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionContributions)
            .where('memberId', isEqualTo: memberId)
            .orderBy('contributionDate', descending: true)
            .get();
    return snapshot.docs.map((doc) => Contribution.fromFirestore(doc)).toList();
  }

  /// Updates an existing contribution in a hostel.
  Future<bool> updateContribution(
    Contribution contribution,
    String hostelId,
  ) async {
    if (contribution.id == null) return false;
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionContributions)
          .doc(contribution.id)
          .update(contribution.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a contribution by its ID from a hostel.
  Future<bool> deleteContribution(String id, String hostelId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionContributions)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculates the total contributions for the entire mess for a given month and year in a hostel.
  Future<double> getMonthlyTotalContributionsForMess(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionContributions)
              .where(
                'contributionDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where(
                'contributionDate',
                isLessThan: Timestamp.fromDate(endOfMonth),
              )
              .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Retrieves all contributions for a given month and year in a hostel.
  Future<List<Contribution>> getContributionsForMonth(
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionContributions)
              .where(
                'contributionDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where(
                'contributionDate',
                isLessThan: Timestamp.fromDate(endOfMonth),
              )
              .orderBy('contributionDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => Contribution.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves contributions for a specific member for a given month and year in a hostel.
  Future<List<Contribution>> getMemberContributionsForMonth(
    String memberId,
    int month,
    int year,
    String hostelId,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .collection(AppConstants.collectionContributions)
              .where('memberId', isEqualTo: memberId)
              .where(
                'contributionDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where(
                'contributionDate',
                isLessThan: Timestamp.fromDate(endOfMonth),
              )
              .orderBy('contributionDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => Contribution.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
