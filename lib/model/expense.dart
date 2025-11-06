import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart'; // This file will be generated

@HiveType(typeId: 3) // Assuming 0 is Product and 1 is Order
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
    // Expense doesn't have an 'id' field, so we use its Hive key for the document ID,
    // but we don't include the key in the document data itself.
    return {
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(), // Convert DateTime to String
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }
// -------------------------------------
}