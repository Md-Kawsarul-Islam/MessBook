// lib/providers/expense_prediction_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mess_manager/services/expense_prediction_service.dart';
import 'package:mess_manager/services/monthly_history_service.dart';

/// Provider for managing and providing expense predictions.
/// It depends on ExpenseProvider and MealProvider to get historical data.
class ExpensePredictionProvider with ChangeNotifier {
  final ExpensePredictionService _predictionService;
  final MonthlyHistoryService _monthlyHistoryService;

  double _predictedNextMonthExpense = 0.0;
  bool _isPredictionLoading = false;
  final DateTime _predictionForMonth = DateTime.now().add(
    const Duration(days: 30),
  ); // Default to next month

  ExpensePredictionProvider(
    this._predictionService,
    this._monthlyHistoryService,
  );

  double get predictedNextMonthExpense => _predictedNextMonthExpense;
  bool get isPredictionLoading => _isPredictionLoading;
  DateTime get predictionForMonth => _predictionForMonth;

  Future<void> initializePrediction(String hostelId) async {
    _isPredictionLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Closed Monthly History
      final historyList = await _monthlyHistoryService.fetchMonthlyHistory(
        hostelId,
      );

      // Sort oldest first for training
      historyList.sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return a.month.compareTo(b.month);
      });

      List<Map<String, double>> historicalData = [];
      int monthIndexCounter = 0;

      for (var history in historyList) {
        historicalData.add({
          'monthIndex': monthIndexCounter.toDouble(),
          'totalExpense': history.totalExpenses,
        });
        monthIndexCounter++;
      }

      // If we have history, predict based on it
      if (historicalData.isNotEmpty) {
        _predictionService.train(historicalData);
        // Predict next month (index = length)
        _predictedNextMonthExpense = _predictionService.predict(
          historicalData.length.toDouble(),
        );
      } else {
        // Fallback: If no history (new system), maybe use current live month?
        // keeping 0.0 for now to encourage closing a month to get predictions
        _predictedNextMonthExpense = 0.0;
      }

      if (_predictedNextMonthExpense < 0) {
        _predictedNextMonthExpense = 0.0;
      }
    } catch (e) {
      debugPrint('Error during expense prediction initialization: $e');
      _predictedNextMonthExpense = 0.0;
    } finally {
      _isPredictionLoading = false;
      notifyListeners();
    }
  }
}
