import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a market schedule entry, including a duty title.
class MarketSchedule {
  String? id; // Firestore Document ID
  String memberId; // Reference to Member ID
  DateTime scheduleDate;
  String dutyTitle; // New field for duty title
  String description;

  MarketSchedule({
    this.id,
    required this.memberId,
    required this.scheduleDate,
    required this.dutyTitle,
    required this.description,
  });

  /// Converts a MarketSchedule object into a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'scheduleDate': Timestamp.fromDate(scheduleDate),
      'dutyTitle': dutyTitle,
      'description': description,
    };
  }

  /// Creates a MarketSchedule object from a Firestore DocumentSnapshot.
  factory MarketSchedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MarketSchedule(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      scheduleDate: (data['scheduleDate'] as Timestamp).toDate(),
      dutyTitle: data['dutyTitle'] ?? '',
      description: data['description'] ?? '',
    );
  }
}
