// SettingsRepository.dart

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
  static const _productCategoriesKey = 'productCategories';

  // Removed showcase flow keys

  SettingsRepository(this._settingsBox, this._ref);

  // --- Invoice Logic ---
  Future<String> getNextInvoiceNumber() async {
    int currentCounter = get<int>('invoiceCounter', defaultValue: 1000);
    int nextCounter = currentCounter + 1;
    await put('invoiceCounter', nextCounter);
    return 'INV-${currentCounter.toString().padLeft(6, '0')}';
  }

  // --- Category Methods ---
  List<String> getProductCategories() {
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

  // --- Generic Getters/Setters ---
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

  // Removed showcase helper methods and getters:
  // setShowcaseStepComplete, hasSeenShowcase, shouldShowManagementHubShowcase, etc.

  // Placeholder for showcase helpers to avoid dependent errors elsewhere,
  // but logically removed. If these are used by other files, replace them
  // with simple non-showcase defaults.

  // Re-adding the minimal structure needed by other files:
  static const showcaseFlow1 = 'showcase_management_tap';
  static const showcaseFlow2 = 'showcase_product_add';
  static const showcaseFlow3 = 'showcase_billing_start';
  static const showcaseFlow4 = 'showcase_billing_checkout';
  static const showcaseFlow5 = 'showcase_billing_confirm';

  // These dummy getters prevent errors in the cleaned files above, assuming
  // they were only used for showcase flow control.
  bool get shouldShowManagementHubShowcase => false;
  bool get shouldShowProductAddShowcase => false;
  bool get shouldShowBillingStartShowcase => false;
  bool get shouldShowBillingCheckoutShowcase => false;
  bool get shouldShowBillingConfirmShowcase => false;
  bool get isAnyShowcaseActive => false;
  Future<void> setShowcaseStepComplete(String key) async {}
}