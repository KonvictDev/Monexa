// lib/providers/subscription_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/settings_repository.dart';

// 1. Fetch the user's latest UserProfile document snapshots (Stream)
final userProfileStreamProvider = StreamProvider((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);

  final authRepo = ref.watch(authRepositoryProvider);

  // ➡️ FIX: Use the public getter for the Firestore instance
  final firestore = authRepo.firestoreInstance;

  // Return the stream of snapshots mapped to UserProfile
  return firestore.collection('users').doc(uid).snapshots().map((doc) {
    // ➡️ FIX: Use the exposed mapUserProfile helper
    return authRepo.mapUserProfile(doc);
  });
});

// 2. Expose a simple boolean: isPro (active and not expired)
final isProProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileStreamProvider).value;

  if (profile == null) {
    return false; // Not signed in/profile not loaded
  }

  if (!profile.isPro) {
    return false;
  }

  // Check if isPro is true AND the expiry date is in the future
  // Note: If proExpiry is null, we assume the subscription is perpetual or server-managed renewal.
  final bool isExpired = profile.proExpiry != null && profile.proExpiry!.isBefore(DateTime.now());

  return profile.isPro && !isExpired;
});

// 3. Expose the user's blocking status
final isBlockedProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileStreamProvider).value;

  // ⚠️ CRITICAL OFFLINE FALLBACK:
  // Read the local block status from Hive's settings box as a fallback/initial check
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final isLocalBlocked = settingsRepo.get('isUserBlocked', defaultValue: false);

  // Prioritize the live Firestore status if available, otherwise use the local state
  return profile?.isBlocked ?? isLocalBlocked;
});