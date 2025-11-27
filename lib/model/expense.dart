import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 3)
class Expense extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  Expense({
    required this.description,
    required this.amount,
    required this.date,
  });

  // --- NEW METHOD FOR FIRESTORE SYNC ---
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(), // Convert DateTime to String
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }
}