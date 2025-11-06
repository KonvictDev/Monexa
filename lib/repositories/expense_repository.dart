// lib/repositories/expense_repository.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/expense.dart';

// Riverpod provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(Hive.box<Expense>('expenses'));
});

class ExpenseRepository {
  final Box<Expense> _expenseBox;

  ExpenseRepository(this._expenseBox);

  // 🛠️ FIX: Public getter to expose the Box for the sync/restore logic
  Box<Expense> get expenseBox => _expenseBox;

  /// Adds a new expense.
  Future<void> addExpense(Expense expense) async {
    await _expenseBox.add(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await expense.save();
  }

  /// Deletes an expense.
  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
  }

  /// Gets a list of all expenses.
  List<Expense> getAllExpenses() {
    return _expenseBox.values.toList();
  }
  Future<void> clearAll() async {
    await _expenseBox.clear();
  }

  List<Expense> getExpensesInDateRange(DateTime start, DateTime end) {
    return _expenseBox.values.where((expense) {
      return !expense.date.isBefore(start) && !expense.date.isAfter(end);
    }).toList();
  }

  /// Returns a ValueListenable for the expense box.
  ValueListenable<Box<Expense>> getListenable() {
    return _expenseBox.listenable();
  }
}