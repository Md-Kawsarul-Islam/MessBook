import 'package:cloud_firestore/cloud_firestore.dart';

enum NoticeType { normal, urgent }

extension NoticeTypeExtension on NoticeType {
  String toShortString() {
    return toString().split('.').last;
  }

  static NoticeType fromShortString(String value) {
    return NoticeType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => NoticeType.normal,
    );
  }
}

class Notice {
  String? id;
  String title;
  String description;
  DateTime date;
  NoticeType type;
  String authorName;
  String hostelId;

  Notice({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.type = NoticeType.normal,
    required this.authorName,
    required this.hostelId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type.toShortString(),
      'authorName': authorName,
      'hostelId': hostelId,
    };
  }

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: NoticeTypeExtension.fromShortString(data['type'] ?? 'normal'),
      authorName: data['authorName'] ?? 'Unknown',
      hostelId: data['hostelId'] ?? '',
    );
  }
}
