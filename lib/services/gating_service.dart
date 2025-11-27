import 'package:billing/services/remote_config_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_profile_providers.dart';
import '../utils/constants.dart';

final gatingServiceProvider = Provider((ref) => GatingService(ref));

class GatingService {
  final Ref _ref;
  late final RemoteConfigService _remoteConfigService;
  GatingService(this._ref){
    _remoteConfigService = _ref.read(remoteConfigServiceProvider);
  }

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
        return currentUsage < _remoteConfigService.freeOrderLimit;
      case Feature.products:
      // Free limit: 20 total products (Fixed limit bug)
        return currentUsage < _remoteConfigService.freeProductLimit;
      default:
        return true;
    }
  }
}