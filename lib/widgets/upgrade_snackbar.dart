// lib/widgets/upgrade_snackbar.dart

import 'package:flutter/material.dart';
import '../screens/subscription/subscription_screen.dart';

/**
 * A reusable SnackBar dedicated to prompting the user to upgrade to Monexa Pro
 * when they hit a freemium limit.
 */
void showUpgradeSnackbar(BuildContext context, String message) {
  final theme = Theme.of(context);

  final SnackBarAction action = SnackBarAction(
    label: 'UPGRADE',
    // Text color should contrast heavily with the error background
    textColor: theme.colorScheme.surface,
    onPressed: () {
      // Dismiss the snackbar before navigating
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Navigate the user to the subscription screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const SubscriptionScreen()),
      );
    },
  );

  final snackBar = SnackBar(
    content: Text(
      message,
      style: TextStyle(
        color: theme.colorScheme.surface, // Ensures white text on red background
        fontWeight: FontWeight.w500,
      ),
    ),
    // Use theme's error color for critical limits/warnings
    backgroundColor: theme.colorScheme.error,
    // Provide a button for the upgrade action
    action: action,
    // Longer duration since this is a critical call-to-action
    duration: const Duration(seconds: 8),
    behavior: SnackBarBehavior.floating,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}