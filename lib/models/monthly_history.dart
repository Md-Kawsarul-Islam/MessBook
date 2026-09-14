import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyHistory {
  String? id;
  String hostelId;
  int month;
  int year;
  double totalMeals;
  double totalExpenses;
  double totalContributions;
  double mealRate;
  List<MonthlyMemberBalance> memberBalances;
  DateTime timestamp;

  MonthlyHistory({
    this.id,
    required this.hostelId,
    required this.month,
    required this.year,
    required this.totalMeals,
    required this.totalExpenses,
    required this.totalContributions,
    required this.mealRate,
    required this.memberBalances,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'hostelId': hostelId,
      'month': month,
      'year': year,
      'totalMeals': totalMeals,
      'totalExpenses': totalExpenses,
      'totalContributions': totalContributions,
      'mealRate': mealRate,
      'memberBalances': memberBalances.map((e) => e.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MonthlyHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MonthlyHistory(
      id: doc.id,
      hostelId: data['hostelId'] ?? '',
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      totalMeals: (data['totalMeals'] ?? 0.0).toDouble(),
      totalExpenses: (data['totalExpenses'] ?? 0.0).toDouble(),
      totalContributions: (data['totalContributions'] ?? 0.0).toDouble(),
      mealRate: (data['mealRate'] ?? 0.0).toDouble(),
      memberBalances:
          (data['memberBalances'] as List<dynamic>?)
              ?.map((e) => MonthlyMemberBalance.fromMap(e))
              .toList() ??
          [],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class MonthlyMemberBalance {
  String memberId;
  String memberName;
  double personalMeals;
  double personalContributions;
  double shareOfExpenses;
  double balance;

  MonthlyMemberBalance({
    required this.memberId,
    required this.memberName,
    required this.personalMeals,
    required this.personalContributions,
    required this.shareOfExpenses,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'personalMeals': personalMeals,
      'personalContributions': personalContributions,
      'shareOfExpenses': shareOfExpenses,
      'balance': balance,
    };
  }

  factory MonthlyMemberBalance.fromMap(Map<String, dynamic> map) {
    return MonthlyMemberBalance(
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? 'Unknown',
      personalMeals: (map['personalMeals'] ?? 0.0).toDouble(),
      personalContributions: (map['personalContributions'] ?? 0.0).toDouble(),
      shareOfExpenses: (map['shareOfExpenses'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
    );
  }
}
