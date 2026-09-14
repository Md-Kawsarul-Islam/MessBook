import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/market_schedule.dart';
import 'package:mess_manager/utils/app_constants.dart';

/// Service class for managing market schedule data in Firestore.
class MarketScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new market schedule entry to a specific hostel.
  Future<String> addMarketSchedule(
    MarketSchedule schedule,
    String hostelId,
  ) async {
    final docRef =
        _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMarketSchedules)
            .doc();
    await docRef.set(schedule.toFirestore());
    return docRef.id;
  }

  /// Retrieves all market schedule entries for a specific hostel.
  Future<List<MarketSchedule>> getAllMarketSchedules(String hostelId) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMarketSchedules)
            .get();
    return snapshot.docs
        .map((doc) => MarketSchedule.fromFirestore(doc))
        .toList();
  }

  /// Retrieves upcoming market schedule entries (from today onwards) for a specific hostel.
  Future<List<MarketSchedule>> getUpcomingMarketSchedules(
    String hostelId,
  ) async {
    // Current date at midnight
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMarketSchedules)
            .where(
              'scheduleDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today),
            )
            .orderBy('scheduleDate', descending: false)
            .get();

    return snapshot.docs
        .map((doc) => MarketSchedule.fromFirestore(doc))
        .toList();
  }

  /// Retrieves market schedule entries for a specific member in a specific hostel.
  Future<List<MarketSchedule>> getMarketSchedulesByMember(
    String memberId,
    String hostelId,
  ) async {
    final QuerySnapshot snapshot =
        await _firestore
            .collection('hostels')
            .doc(hostelId)
            .collection(AppConstants.collectionMarketSchedules)
            .where('memberId', isEqualTo: memberId)
            .orderBy('scheduleDate', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => MarketSchedule.fromFirestore(doc))
        .toList();
  }

  /// Updates an existing market schedule entry in a specific hostel.
  Future<bool> updateMarketSchedule(
    MarketSchedule schedule,
    String hostelId,
  ) async {
    if (schedule.id == null) return false;
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionMarketSchedules)
          .doc(schedule.id)
          .update(schedule.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a market schedule entry by its ID from a specific hostel.
  Future<bool> deleteMarketSchedule(String id, String hostelId) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection(AppConstants.collectionMarketSchedules)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
