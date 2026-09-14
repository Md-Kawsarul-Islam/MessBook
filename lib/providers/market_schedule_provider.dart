import 'package:flutter/material.dart';
import 'package:mess_manager/models/market_schedule.dart';
import 'package:mess_manager/services/market_schedule_service.dart';

/// Provider for managing MarketSchedule data.
class MarketScheduleProvider with ChangeNotifier {
  final MarketScheduleService _marketScheduleService;
  List<MarketSchedule> _marketSchedules = [];
  List<MarketSchedule> _upcomingMarketSchedules = [];

  MarketScheduleProvider(this._marketScheduleService);

  List<MarketSchedule> get marketSchedules => _marketSchedules;
  List<MarketSchedule> get upcomingMarketSchedules => _upcomingMarketSchedules;

  /// Fetches all market schedules for a specific hostel.
  Future<void> fetchAllMarketSchedules(String hostelId) async {
    _marketSchedules = await _marketScheduleService.getAllMarketSchedules(
      hostelId,
    );
    notifyListeners();
  }

  /// Fetches market schedules for a specific member in a specific hostel.
  Future<List<MarketSchedule>> fetchMarketSchedulesByMember(
    String memberId,
    String hostelId,
  ) async {
    return await _marketScheduleService.getMarketSchedulesByMember(
      memberId,
      hostelId,
    );
  }

  /// Fetches upcoming market schedules for a specific hostel.
  Future<void> fetchUpcomingMarketSchedules(String hostelId) async {
    _upcomingMarketSchedules = await _marketScheduleService
        .getUpcomingMarketSchedules(hostelId);
    notifyListeners();
  }

  /// Adds a new market schedule to a specific hostel.
  Future<bool> addMarketSchedule(
    MarketSchedule schedule,
    String hostelId,
  ) async {
    final String id = await _marketScheduleService.addMarketSchedule(
      schedule,
      hostelId,
    );
    if (id.isNotEmpty) {
      await fetchAllMarketSchedules(hostelId); // Refresh all schedules
      await fetchUpcomingMarketSchedules(
        hostelId,
      ); // Refresh upcoming schedules
      return true;
    }
    return false;
  }

  /// Updates an existing market schedule in a specific hostel.
  Future<bool> updateMarketSchedule(
    MarketSchedule schedule,
    String hostelId,
  ) async {
    final bool success = await _marketScheduleService.updateMarketSchedule(
      schedule,
      hostelId,
    );
    if (success) {
      await fetchAllMarketSchedules(hostelId); // Refresh all schedules
      await fetchUpcomingMarketSchedules(
        hostelId,
      ); // Refresh upcoming schedules
    }
    return success;
  }

  /// Deletes a market schedule from a specific hostel.
  Future<bool> deleteMarketSchedule(String id, String hostelId) async {
    final bool success = await _marketScheduleService.deleteMarketSchedule(
      id,
      hostelId,
    );
    if (success) {
      await fetchAllMarketSchedules(hostelId); // Refresh all schedules
      await fetchUpcomingMarketSchedules(
        hostelId,
      ); // Refresh upcoming schedules
    }
    return success;
  }
}
