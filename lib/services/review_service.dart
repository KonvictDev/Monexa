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
  static const int _targetCount = 3; // Trigger after 3 successful orders
  static const int _cooldownDays = 30; // 30-day cooldown

  // ➡️ Corrected Trigger logic
  Future<void> triggerReviewFlow() async {
    // 1. Get current count and IMMEDIATELY increment it.
    final int currentCount = _settingsBox.get(_promptCountKey, defaultValue: 0);
    final int newCount = currentCount + 1;

    // Save the new count (this is the value we'll check against the target)
    await _settingsBox.put(_promptCountKey, newCount);

    if (newCount >= _targetCount) {
      final lastPromptTimestamp = _settingsBox.get(_lastPromptKey);

      final bool recentlyPrompted = lastPromptTimestamp != null &&
          DateTime.now().difference(lastPromptTimestamp as DateTime).inDays < _cooldownDays;

      if (await _inAppReview.isAvailable() && !recentlyPrompted) {
        // 2. Show Review
        await _inAppReview.requestReview();

        // 3. Reset counter and timestamp
        await _settingsBox.put(_promptCountKey, 0);
        await _settingsBox.put(_lastPromptKey, DateTime.now());
      }
      // If the review is not available or recently prompted, the counter remains at 3 (or higher)
      // until the cooldown expires or the service becomes available.

    }
    // If newCount is < targetCount, we already saved the incremented value above, so we're done.
  }
}