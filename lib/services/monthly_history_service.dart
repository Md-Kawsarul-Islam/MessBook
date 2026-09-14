import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/monthly_history.dart';

class MonthlyHistoryService {
  final CollectionReference _historyCollection = FirebaseFirestore.instance
      .collection('monthly_history');

  Future<void> saveMonthlyHistory(MonthlyHistory history) async {
    try {
      await _historyCollection.add(history.toFirestore());
    } catch (e) {
      throw Exception('Error saving monthly history: $e');
    }
  }

  Future<List<MonthlyHistory>> fetchMonthlyHistory(String hostelId) async {
    try {
      final snapshot =
          await _historyCollection
              .where('hostelId', isEqualTo: hostelId)
              .orderBy('year', descending: true)
              .orderBy('month', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => MonthlyHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching monthly history: $e');
    }
  }
}
