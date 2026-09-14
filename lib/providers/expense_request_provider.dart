import 'package:flutter/material.dart';
import 'package:mess_manager/models/expense_request.dart';
import 'package:mess_manager/services/expense_request_service.dart';

class ExpenseRequestProvider with ChangeNotifier {
  final ExpenseRequestService _service;
  bool _isLoading = false;

  ExpenseRequestProvider(this._service);

  bool get isLoading => _isLoading;

  Stream<List<ExpenseRequest>> getPendingRequestsStream(String hostelId) {
    return _service.getPendingRequestsStream(hostelId);
  }

  Stream<List<ExpenseRequest>> getMyRequestsStream(
    String hostelId,
    String memberId,
  ) {
    return _service.getMyRequestsStream(hostelId, memberId);
  }

  Future<bool> submitRequest(ExpenseRequest request) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.addRequest(request);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<bool> approveRequest(ExpenseRequest request) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.approveRequest(request);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<bool> rejectRequest(String hostelId, String requestId) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.rejectRequest(hostelId, requestId);
    _isLoading = false;
    notifyListeners();
    return result;
  }
}
