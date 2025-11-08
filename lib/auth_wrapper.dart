// lib/auth_wrapper.dart (REFACTORED)

import 'package:billing/providers/pin_auth_provider.dart';
import 'package:billing/repositories/settings_repository.dart';
import 'package:billing/screens/auth/pin_lock_screen.dart';
import 'package:billing/screens/auth/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ➡️ Import the new wrapper
import 'app_check_wrapper.dart';
// ➡️ Import your other screens
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

// ❌ The version providers are no longer needed here
// ❌ The isBlockedProvider is no longer needed here

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ FAST CHECK 1: Onboarding (Local)
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final onboardingCompleted = settingsRepo.get('onboarding_completed', defaultValue: false);

    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    // 2️⃣ FAST CHECK 2: PIN State (Local)
    final pinAuth = ref.watch(pinAuthProvider);

    switch (pinAuth.lockState) {
      case AppLockState.unknown:
      // This is the only "loading" state we should show.
      // It should be very brief, just while checking local storage for a PIN.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AppLockState.noPinSet:
        return const PinSetupScreen();
      case AppLockState.locked:
        return const PinLockScreen();
      case AppLockState.unlocked:
      // ➡️ 3️⃣ DELEGATE SLOW CHECKS
      // The user is unlocked, so show the main app.
      // We wrap it in AppCheckWrapper to run network checks
      // in the background *while* the user sees the main app.
        return const AppCheckWrapper(
          child: MainNavigationScreen(),
        );
    }
  }

// ❌ _isUpdateRequired method is removed from here
}