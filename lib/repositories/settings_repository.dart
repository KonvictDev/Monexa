import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'product_repository.dart';
import 'order_repository.dart';
import 'expense_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box('settings'), ref);
});

class SettingsRepository {
  final Box _settingsBox;
  final Ref _ref;
  static const _productCategoriesKey = 'category';

  // Removed showcase flow keys

  SettingsRepository(this._settingsBox, this._ref);

  // --- Invoice Logic ---
  Future<String> getNextInvoiceNumber() async {
    int currentCounter = get<int>('invoiceCounter', defaultValue: 1000);
    int nextCounter = currentCounter + 1;
    await put('invoiceCounter', nextCounter);
    return 'INV-${currentCounter.toString().padLeft(6, '0')}';
  }

  // lib/repositories/settings_repository.dart

  // ... inside SettingsRepository class ...

  Future<void> mergeCategories(List<String> newCategories) async {
    // 1. Get current
    final currentRaw = _settingsBox.get('categories');
    List<String> currentList = [];

    if (currentRaw != null) {
      currentList = List<String>.from(currentRaw);
    } else {
      currentList = ['General'];
    }

    // 2. Merge unique
    final Set<String> uniqueSet = {...currentList, ...newCategories};

    // 3. Save
    await _settingsBox.put('categories', uniqueSet.toList());
    print("DEBUG: Categories merged and saved: $uniqueSet");
  }

  List<String> getProductCategories() {
    // 1. Get raw data
    final dynamic rawData = _settingsBox.get('categories');

    // 🔥 DEBUG PRINT: See exactly what is in the box
    print("--------------------------------------------------");
    print("DEBUG: fetching categories from Hive 'settings' box");
    print("DEBUG: Raw Data found: $rawData");

    if (rawData == null) {
      print("DEBUG: Data is null, returning defaults");
      return ['General'];
    }

    try {
      // 2. Safely cast
      final List<String> result = List<String>.from(rawData);
      print("DEBUG: Successfully cast to List<String>: $result");
      print("--------------------------------------------------");
      return result;
    } catch (e) {
      print("DEBUG: Error casting categories: $e");
      return ['General']; // Fallback
    }
  }

  Future<void> addProductCategory(String category) async {
    if (category.isEmpty) return;
    final categories = getProductCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _settingsBox.put(_productCategoriesKey, categories);
    }
  }

  bool get isStaffMode => get<bool>('is_staff_mode', defaultValue: false);
  // --- Generic Getters/Setters ---
  Future<void> setStaffMode(bool value) async {
    await put('is_staff_mode', value);
  }

  // ✅ NEW: Low Stock Threshold Logic
  int get lowStockThreshold => get<int>('low_stock_limit', defaultValue: 5);

  Future<void> setLowStockThreshold(int value) async {
    await put('low_stock_limit', value);
  }

  // ✅ NEW: Sync Rate Limiting Logic
  bool canSync(int limit) {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String lastSyncDate = get<String>('last_sync_date_tracker', defaultValue: '');

    // If it's a new day, reset the counter
    if (lastSyncDate != today) {
      put('last_sync_date_tracker', today);
      put('daily_sync_count', 0);
      return true; // Count is 0, so allowed
    }

    final int currentCount = get<int>('daily_sync_count', defaultValue: 0);
    return currentCount < limit;
  }

  Future<void> incrementSyncCount() async {
    final int currentCount = get<int>('daily_sync_count', defaultValue: 0);
    await put('daily_sync_count', currentCount + 1);

    // Also update "Last Synced Time" for display
    await put('last_successful_sync_time', DateTime.now().toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final String? str = _settingsBox.get('last_successful_sync_time');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  int getRemainingSyncs(int limit) {
    final int currentCount = get<int>('daily_sync_count', defaultValue: 0);
    // Safety check if new day logic hasn't run yet
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String lastSyncDate = get<String>('last_sync_date_tracker', defaultValue: '');
    if (lastSyncDate != today) return limit;

    return (limit - currentCount).clamp(0, limit);
  }

  T get<T>(String key, {required T defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> put(String key, dynamic value) async {
    await _settingsBox.put(key, value);
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