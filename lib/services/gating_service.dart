// lib/services/gating_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';

final gatingServiceProvider = Provider((ref) => GatingService(ref));

enum Feature {
  // Volume Limits (Orders and Products)
  orders,
  products,

  // Feature Access (UI/Gated)
  cloudSync,
  dataRestore,
  dataExport,
  advancedFiltering,
  customerManagement, // Add/Edit/Delete Customers
  categoryCustomization, // Add new categories
  receiptCustomization, // Edit receipt footer/toggles
  ltvAnalytics, // Customer LTV metrics
  changeSecurityPin, // Changing the PIN
}

class GatingService {
  final Ref _ref;
  GatingService(this._ref);

  // Checks if the user is Pro
  bool get isPro => _ref.read(isProProvider);

  // --- 1. FEATURE ACCESS CHECK ---
  bool canAccessFeature(Feature feature) {
    if (isPro) return true;

    switch (feature) {
      case Feature.orders:
      case Feature.products:
      case Feature.ltvAnalytics:
      case Feature.cloudSync:
      case Feature.dataRestore:
      case Feature.dataExport:
      case Feature.advancedFiltering:
      case Feature.customerManagement:
      case Feature.receiptCustomization:
        return false; // All restricted to Pro

      case Feature.changeSecurityPin:
      case Feature.categoryCustomization:
        return true; // Security feature is free
    }
  }

  // --- 2. USAGE LIMIT CHECK (For transactional features) ---
  bool canUseFeature(Feature feature, int currentUsage) {
    if (isPro) return true; // Unlimited access for Pro

    switch (feature) {
      case Feature.orders:
      // Free limit: 30 orders/month
        return currentUsage < 3;
      case Feature.products:
      // Free limit: 20 total products (Fixed limit bug)
        return currentUsage < 2;
      default:
        return true;
    }
  }
}