// lib/services/expense_prediction_service.dart

import 'dart:math'; // For pow, exp
import 'package:flutter/foundation.dart';

/// A service to predict future expenses using Linear Regression with Gradient Descent.
/// This model predicts a continuous value (expense amount) based on a continuous input (month index).
class ExpensePredictionService {
  // Model parameters (slope and intercept)
  double _m = 0.0; // Slope
  double _b = 0.0; // Intercept

  // Learning rate for gradient descent
  final double _learningRate;
  // Number of iterations for gradient descent
  final int _iterations;

  ExpensePredictionService({
    // Corrected: Parameter names should not start with an underscore
    double learningRate = 0.01,
    int iterations = 1000,
  }) : _learningRate = learningRate, // Assigning to private field
       _iterations = iterations; // Assigning to private field

  /// Trains the linear regression model using Gradient Descent.
  ///
  /// [historicalData]: A list of maps, where each map contains:
  ///   - 'monthIndex': The numerical representation of the month (e.g., months since a start date).
  ///   - 'totalExpense': The total expense for that month.
  ///
  /// The method updates the internal `_m` (slope) and `_b` (intercept) parameters.
  void train(List<Map<String, double>> historicalData) {
    if (historicalData.isEmpty) {
      debugPrint(
        "ExpensePredictionService: No historical data provided for training.",
      );
      _m = 0.0;
      _b = 0.0;
      return;
    }

    // Initialize m and b (can be random or 0)
    // Using 0.0 for simplicity for now.
    _m = 0.0;
    _b = 0.0;

    final n = historicalData.length; // Number of data points

    for (int i = 0; i < _iterations; i++) {
      double sumErrorM = 0.0; // Sum of partial derivatives for m
      double sumErrorB = 0.0; // Sum of partial derivatives for b

      for (var dataPoint in historicalData) {
        final x = dataPoint['monthIndex']!;
        final y = dataPoint['totalExpense']!;

        // Predict y (h(x))
        final yPredicted = _m * x + _b;

        // Calculate the error
        final error = yPredicted - y;

        // Calculate partial derivatives for m and b
        // Derivative of MSE with respect to m: (1/n) * sum( (h(x_i) - y_i) * x_i )
        // Derivative of MSE with respect to b: (1/n) * sum( (h(x_i) - y_i) )
        sumErrorM += error * x;
        sumErrorB += error;
      }

      // Update m and b using the gradient descent formula
      // m = m - learning_rate * (1/n) * sumErrorM
      // b = b - learning_rate * (1/n) * sumErrorB
      _m = _m - _learningRate * (1 / n) * sumErrorM;
      _b = _b - _learningRate * (1 / n) * sumErrorB;

      // Optional: Print cost (MSE) every N iterations to monitor convergence
      // if (i % 100 == 0) {
      //   print('Iteration $i, Cost: ${calculateCost(historicalData)}');
      // }
    }
    debugPrint("ExpensePredictionService: Training complete. m: $_m, b: $_b");
  }

  /// Predicts the total expense for a given month index.
  /// This method should only be called after the `train` method has been executed.
  ///
  /// [monthIndex]: The numerical representation of the future month.
  /// Returns the predicted total expense.
  double predict(double monthIndex) {
    if (_m == 0.0 && _b == 0.0) {
      debugPrint(
        "ExpensePredictionService: Model not trained or trained with no data. Returning 0 prediction.",
      );
      return 0.0;
    }
    return _m * monthIndex + _b;
  }

  /// Calculates the Mean Squared Error (MSE) cost for the current model parameters.
  /// This is used internally for monitoring training progress.
  double calculateCost(List<Map<String, double>> historicalData) {
    if (historicalData.isEmpty) return 0.0;

    double sumSquaredErrors = 0.0;
    for (var dataPoint in historicalData) {
      final x = dataPoint['monthIndex']!;
      final y = dataPoint['totalExpense']!;
      final yPredicted = _m * x + _b;
      sumSquaredErrors += pow((yPredicted - y), 2);
    }
    return (1 / historicalData.length) * sumSquaredErrors;
  }
}
