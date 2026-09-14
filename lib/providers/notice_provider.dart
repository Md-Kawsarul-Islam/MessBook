import 'package:flutter/material.dart';
import 'package:mess_manager/models/notice.dart';
import 'package:mess_manager/services/notice_service.dart';

class NoticeProvider with ChangeNotifier {
  final NoticeService _noticeService;
  final List<Notice> _notices = [];
  bool _isLoading = false;

  NoticeProvider(this._noticeService);

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;

  // Subscribe to notices stream for real-time updates
  Stream<List<Notice>> getNoticesStream(String hostelId) {
    return _noticeService.getNoticesStream(hostelId);
  }

  Future<bool> addNotice(Notice notice) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _noticeService.addNotice(notice);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteNotice(String noticeId, String hostelId) async {
    return await _noticeService.deleteNotice(noticeId, hostelId);
  }
}
