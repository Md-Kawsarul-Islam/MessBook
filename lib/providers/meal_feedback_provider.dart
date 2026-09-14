import 'package:flutter/material.dart';
import 'package:mess_manager/models/meal_feedback.dart';
import 'package:mess_manager/services/meal_feedback_service.dart';

class MealFeedbackProvider with ChangeNotifier {
  final MealFeedbackService _service;

  MealFeedbackProvider(this._service);

  Future<void> submitFeedback(MealFeedback feedback) async {
    await _service.addFeedback(feedback);
    notifyListeners();
  }

  Stream<List<MealFeedback>> getRecentFeedback(String hostelId) {
    return _service.getRecentFeedbackStream(hostelId);
  }

  Future<double> getMonthlyAverageRating(String hostelId) async {
    final now = DateTime.now();
    return await _service.getAverageRatingForMonth(
      hostelId,
      now.month,
      now.year,
    );
  }
}
