// lib/providers/user_profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// 1. Fetch the user's latest UserProfile document snapshots (Stream)
final userProfileStreamProvider = StreamProvider((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);

  final authRepo = ref.watch(authRepositoryProvider);

  // Use the public getter for the Firestore instance
  final firestore = authRepo.firestoreInstance;

  // Return the stream of snapshots mapped to UserProfile
  return firestore.collection('users').doc(uid).snapshots().map((doc) {
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