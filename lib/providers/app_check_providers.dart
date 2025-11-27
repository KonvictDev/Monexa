// lib/providers/app_check_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:billing/repositories/settings_repository.dart';
import '../repositories/auth_repository.dart';
import 'user_profile_providers.dart';


final minVersionProvider = FutureProvider<String?>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance.doc('app_config/settings').get();
    return doc.data()?['min_version'] as String?;
  } catch (e) {
    debugPrint("Error fetching min_version: $e");
    return null;
  }
});

final currentVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final isBlockedProvider = FutureProvider<bool>((ref) async {
  final profileAsync = ref.watch(userProfileStreamProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final uid = ref.watch(authStateProvider).value?.uid;

  final String cacheKey = 'cached_is_blocked_${uid}';
  final isLocalBlocked = settingsRepo.get(cacheKey, defaultValue: false);

  if (profileAsync.hasError || !profileAsync.hasValue) {
    return isLocalBlocked;
  }

  final profile = profileAsync.value;

  return profile?.isBlocked ?? isLocalBlocked;
});