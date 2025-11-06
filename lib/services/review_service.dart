// lib/services/review_service.dart

import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  final _settingsBox = Hive.box('settings');
  static const _promptCountKey = 'review_prompt_count';
  static const _lastPromptKey = 'review_last_prompt_timestamp';

  // ➡️ Trigger logic: Call this after a successful order is placed
  Future<void> triggerReviewFlow() async {
    final int currentCount = _settingsBox.get(_promptCountKey, defaultValue: 0);
    final int targetCount = 3; // Trigger after 3 successful orders

    if (currentCount >= targetCount) {
      final lastPrompt = _settingsBox.get(_lastPromptKey);
      final bool recentlyPrompted = lastPrompt != null &&
          DateTime.now().difference(lastPrompt as DateTime).inDays < 30; // 30-day cooldown

      if (await _inAppReview.isAvailable() && !recentlyPrompted) {
        await _inAppReview.requestReview();
        _settingsBox.put(_promptCountKey, 0); // Reset counter after prompt
        _settingsBox.put(_lastPromptKey, DateTime.now());
      }
    } else {
      _settingsBox.put(_promptCountKey, currentCount + 1);
    }
  }
}