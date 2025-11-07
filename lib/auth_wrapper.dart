// lib/auth_wrapper.dart (CORRECTED)

import 'package:billing/providers/pin_auth_provider.dart';
import 'package:billing/repositories/settings_repository.dart';
import 'package:billing/screens/auth/pin_lock_screen.dart';
import 'package:billing/screens/auth/pin_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';
import 'screens/force_update_screen.dart';
import 'providers/subscription_provider.dart';

// Provider to fetch the minimum required version from Firebase
final minVersionProvider = FutureProvider<String?>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance.doc('app_config/settings').get();
    // Safety: Ensure key exists and is a String
    return doc.data()?['min_version'] as String?;
  } catch (e) {
    // Log the Firestore PERMISSION_DENIED error here
    debugPrint('Error fetching min version: $e');
    return null;
  }
});

// Provider to asynchronously fetch the current app version
final currentVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ Watch all necessary asynchronous data
    final minVersionAsync = ref.watch(minVersionProvider);
    final currentVersionAsync = ref.watch(currentVersionProvider);

    // Combine loading states for all initial asynchronous data (minVersion, currentVersion)
    if (minVersionAsync.isLoading || currentVersionAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Use valueOrNull for safe access
    final minRequiredVersion = minVersionAsync.valueOrNull;
    final currentVersion = currentVersionAsync.valueOrNull;

    // Check for Force Update only if both versions are available
    if (minRequiredVersion != null && currentVersion != null && _isUpdateRequired(currentVersion, minRequiredVersion)) {
      const storeUrl = 'https://play.google.com/store/apps/details?id=com.monexa.billing';
      return ForceUpdateScreen(minVersion: minRequiredVersion, storeUrl: storeUrl);
    }

    // 2️⃣ Check for User Blocking
    // This now uses the fixed isBlockedProvider which handles AsyncError safely.
    final isBlocked = ref.watch(isBlockedProvider);
    if (isBlocked) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Blocked. Please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    // 3️⃣ Normal Flow (Onboarding, PIN, Main App)
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final onboardingCompleted = settingsRepo.get('onboarding_completed', defaultValue: false);

    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    final pinAuth = ref.watch(pinAuthProvider);

    switch (pinAuth.lockState) {
      case AppLockState.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AppLockState.noPinSet:
        return const PinSetupScreen();
      case AppLockState.locked:
        return const PinLockScreen();
      case AppLockState.unlocked:
        return const MainNavigationScreen();
    }
  }

  bool _isUpdateRequired(String currentVersion, String minRequiredVersion) {
    final minParts = minRequiredVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < minParts.length; i++) {
      if (currentParts.length <= i || currentParts[i] < minParts[i]) {
        return true;
      }
      if (currentParts[i] > minParts[i]) {
        return false;
      }
    }
    return false;
  }
}