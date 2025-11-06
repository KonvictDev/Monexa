import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'product_repository.dart';
import 'order_repository.dart';
import 'expense_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box('settings'), ref);
});

class SettingsRepository {
  final Box _settingsBox;
  final Ref _ref;
  static const _productCategoriesKey = 'productCategories'; // <-- ADD THIS

  SettingsRepository(this._settingsBox, this._ref);

  // --- Invoice Logic ---
  Future<String> getNextInvoiceNumber() async {
    int currentCounter = get<int>('invoiceCounter', defaultValue: 1000);
    int nextCounter = currentCounter + 1;
    await put('invoiceCounter', nextCounter);
    return 'INV-${currentCounter.toString().padLeft(6, '0')}';
  }

  // --- NEW CATEGORY METHODS ---
  List<String> getProductCategories() {
    // Get list from Hive, default to an empty list
    return _settingsBox.get(_productCategoriesKey, defaultValue: <String>[]);
  }

  Future<void> addProductCategory(String category) async {
    if (category.isEmpty) return;
    final categories = getProductCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _settingsBox.put(_productCategoriesKey, categories);
    }
  }
  // --- END NEW CATEGORY METHODS ---

  // --- Generic Getters/Setters ---
  T get<T>(String key, {required T defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> put(String key, dynamic value) async {
    await _settingsBox.put(key, value);
    // Hive automatically updates its listenable; no manual notify needed.
  }

  ValueListenable<Box> getListenable({List<String>? keys}) {
    return _settingsBox.listenable(keys: keys);
  }

  // --- System Methods ---
  Future<void> resetOnboarding() async {
    await put('onboarding_completed', false);
  }

  Future<void> clearAllData() async {
    await _ref.read(productRepositoryProvider).clearAll();
    await _ref.read(orderRepositoryProvider).clearAll();
    await _ref.read(expenseRepositoryProvider).clearAll();
    await _settingsBox.clear();
  }
}