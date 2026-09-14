import 'package:cloud_firestore/cloud_firestore.dart';

class Hostel {
  String? id;
  String name;
  String? address;
  String? inviteCode; // Optional: Simple code for joining
  String ownerId; // The user who created the hostel
  DateTime createdAt;
  DateTime activeMonth; // The current month being managed
  bool isMonthOpen; // Whether the current month is open for entries

  Hostel({
    this.id,
    required this.name,
    this.address,
    this.inviteCode,
    required this.ownerId,
    required this.createdAt,
    DateTime? activeMonth,
    this.isMonthOpen = true,
  }) : activeMonth =
           activeMonth ??
           DateTime(DateTime.now().year, DateTime.now().month, 1);

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'activeMonth': Timestamp.fromDate(activeMonth),
      'isMonthOpen': isMonthOpen,
    };
  }

  factory Hostel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Hostel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'],
      inviteCode: data['inviteCode'],
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      activeMonth:
          data['activeMonth'] != null
              ? (data['activeMonth'] as Timestamp).toDate()
              : null,
      isMonthOpen: data['isMonthOpen'] ?? true,
    );
  }
}
