// lib/providers/app_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ➡️ 1. IMPORT YOUR SETTINGS REPOSITORY
import 'package:billing/repositories/settings_repository.dart'; // Make sure this path is correct

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

// --- AUTH PROVIDER (Unchanged) ---

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// --- BLOCK PROVIDER (UPDATED WITH OFFLINE CACHING) ---

// lib/providers/app_providers.dart

final isBlockedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authProvider).value;

  if (user == null) {
    print("Block Check: User is NOT LOGGED IN");
    return false;
  }

  // Get the local settings repository
  final settingsRepo = ref.read(settingsRepositoryProvider);

  // Create a user-specific cache key
  final String cacheKey = 'cached_is_blocked_${user.uid}';

  try {
    // --- 1. NETWORK ATTEMPT ---
    print("Block Check (Network): User ${user.uid}. Trying Firestore...");
    final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();

    final bool isBlockedFromNetwork = doc.data()?['isBlocked'] as bool? ?? false;

    // --- 2. NETWORK SUCCESS ---
    // Save the latest status to the local cache

    // 👇 THE CORRECTED LINE
    await settingsRepo.put(cacheKey, isBlockedFromNetwork);

    print("Block Check (Network): Success. Value is $isBlockedFromNetwork. Saved to cache.");
    return isBlockedFromNetwork;

  } catch (e) {
    // --- 3. NETWORK FAILURE (OFFLINE) ---
    print("Block Check (Offline): Network failed. Reading from cache. Error: $e");

    // Get the last known value (your 'get' method is perfect for this)
    final bool isBlockedFromCache = settingsRepo.get(cacheKey, defaultValue: false);

    print("Block Check (Offline): Cached value is $isBlockedFromCache");
    return isBlockedFromCache;
  }
});