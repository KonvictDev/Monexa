// lib/providers/app_check_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:billing/repositories/settings_repository.dart';
import '../repositories/auth_repository.dart';
import 'user_profile_providers.dart'; // ⬅️ NEW: Import the profile status

// --- VERSION PROVIDERS (Unchanged) ---

final minVersionProvider = FutureProvider<String?>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance.doc('app_config/settings').get();
    return doc.data()?['min_version'] as String?;
  } catch (e) {
    print("Error fetching min_version: $e");
    return null;
  }
});

final currentVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

// ❌ REMOVED: authProvider is now defined in AuthRepository, accessible via authStateProvider

// --- BLOCK PROVIDER (MODIFIED to use user_profile_providers.dart) ---

final isBlockedProvider = FutureProvider<bool>((ref) async {
  // Use the live profile stream
  final profileAsync = ref.watch(userProfileStreamProvider);

  // Read the local settings repository for cache fallback
  final settingsRepo = ref.read(settingsRepositoryProvider);
  // Key must match the one used in app_check_wrapper.dart for caching
  final uid = ref.watch(authStateProvider).value?.uid;
  final String cacheKey = 'cached_is_blocked_${uid}';
  final isLocalBlocked = settingsRepo.get(cacheKey, defaultValue: false);


  // If loading, error, or no value, fall back to the local cached status.
  if (profileAsync.hasError || !profileAsync.hasValue) {
    return isLocalBlocked;
  }

  // Use the resolved value
  final profile = profileAsync.value;

  // Prioritize the live Firestore status if available
  return profile?.isBlocked ?? isLocalBlocked;
});