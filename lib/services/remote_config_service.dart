// lib/services/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteConfigServiceProvider = Provider((ref) => RemoteConfigService());

class RemoteConfigService {
  final _remoteConfig = FirebaseRemoteConfig.instance;

  int get freeOrderLimit => _remoteConfig.getInt('free_order_limit_monthly');

  int get freeProductLimit => _remoteConfig.getInt('free_product_limit');

  String get subscriptionProductList => _remoteConfig.getString('subscription_product_ids');

}

Future<void> setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    // Use a low interval during development for testing, standard in production
    minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 12),
  ));

  // Set default values for critical remote parameters
  await remoteConfig.setDefaults(<String, dynamic>{
    // Add default subscription product IDs for IAP Service
    'subscription_product_ids': 'monexa_pro_monthly,monexa_pro_annual',
    'free_order_limit_monthly': 30,
    'free_product_limit': 20,
  });

  try {
    await remoteConfig.fetchAndActivate();
    debugPrint("Remote Config successfully fetched and activated.");
  } catch (e) {
    debugPrint("Remote Config fetch failed: $e. Using default values.");
  }
}