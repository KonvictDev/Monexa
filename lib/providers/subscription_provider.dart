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

  // Use the public getter for the Firestore instance
  final firestore = authRepo.firestoreInstance;

  // Return the stream of snapshots mapped to UserProfile
  return firestore.collection('users').doc(uid).snapshots().map((doc) {
    // This relies on authRepo.mapUserProfile being robust (see AuthRepository fix)
    return authRepo.mapUserProfile(doc);
  });
});

// 2. Expose a simple boolean: isPro (active and not expired)
final isProProvider = Provider<bool>((ref) {
  // Use .valueOrNull for safe access
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;

  if (profile == null) {
    return false; // Not signed in/profile not loaded
  }

  if (!profile.isPro) {
    return false;
  }

  final bool isExpired = profile.proExpiry != null && profile.proExpiry!.isBefore(DateTime.now());

  return profile.isPro && !isExpired;
});

// 3. Expose the user's blocking status
final isBlockedProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider);

  // CRITICAL OFFLINE FALLBACK:
  // Read the local block status from Hive's settings box as a fallback/initial check
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final isLocalBlocked = settingsRepo.get('isUserBlocked', defaultValue: false);

  // ⚠️ FIX: If loading or error, fall back to the local blocked status.
  if (profileAsync.hasError || !profileAsync.hasValue) {
    return isLocalBlocked;
  }

  // Use the resolved value
  final profile = profileAsync.value;

  // Prioritize the live Firestore status if available, otherwise use the local state
  return profile?.isBlocked ?? isLocalBlocked;
});