// lib/app_check_wrapper.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:billing/providers/app_providers.dart';
// ❌ We no longer import or use ForceUpdateScreen
// import 'package:billing/screens/force_update_screen.dart';

// 1. Convert to ConsumerStatefulWidget
class AppCheckWrapper extends ConsumerStatefulWidget {
  final Widget child; // This will be MainNavigationScreen

  const AppCheckWrapper({super.key, required this.child});

  @override
  ConsumerState<AppCheckWrapper> createState() => _AppCheckWrapperState();
}

class _AppCheckWrapperState extends ConsumerState<AppCheckWrapper> {
  // 2. Add state variable to track the block dialog
  bool _isBlockedDialogShown = false;
  // 3. ➡️ NEW: Add state variable to track the update dialog
  bool _isUpdateDialogShown = false;

  // Helper method for Support Button
  void _launchSupportEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@monexa.billing', // ⬅️ *** YOUR SUPPORT EMAIL ***
      query: 'subject=Account Blocked Inquiry',
    );
    _launchUri(emailLaunchUri, 'Could not open email app.');
  }

  // 4. ➡️ NEW: Helper method to launch the store URL
  void _launchStoreUrl(String url) async {
    final Uri storeUri = Uri.parse(url);
    // Use externalApplication mode to ensure it opens the Play Store app
    _launchUri(storeUri, 'Could not open app store.', mode: LaunchMode.externalApplication);
  }

  // 5. ➡️ NEW: Generic URI Launcher
  void _launchUri(Uri uri, String fallbackMessage, {LaunchMode mode = LaunchMode.platformDefault}) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: mode);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fallbackMessage Please contact support.')),
        );
      }
    } catch (e) {
      print('Could not launch $uri: $e');
    }
  }


  // Helper method for version comparison
  bool _isUpdateRequired(String currentVersion, String minRequiredVersion) {
    // ... (this method is unchanged)
    final minParts = minRequiredVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < minParts.length; i++) {
      if (currentParts.length <= i || currentParts[i] < minParts[i]) {
        return true;
      }
      if (currentParts[i] > minParts[i]) {
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 6. ➡️ MODIFIED: Use ref.listen for *both* checks

    // --- Block Check Listener ---
    ref.listen<AsyncValue<bool>>(isBlockedProvider, (prev, next) {
      final isBlocked = next.value == true;

      if (isBlocked && !_isBlockedDialogShown) {
        // User IS blocked and dialog ISN'T shown -> SHOW DIALOG
        setState(() {
          _isBlockedDialogShown = true;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _buildBlockedDialog(dialogContext),
        );

      } else if (!isBlocked && _isBlockedDialogShown) {
        // User IS NOT blocked, but dialog IS shown -> DISMISS DIALOG
        setState(() {
          _isBlockedDialogShown = false;
        });
        Navigator.of(context).pop(); // Pops the dialog
      }
    });

    // --- Force Update Check (re-runs on build) ---
    final minVersionAsync = ref.watch(minVersionProvider);
    final currentVersionAsync = ref.watch(currentVersionProvider);
    final minRequiredVersion = minVersionAsync.value;
    final currentVersion = currentVersionAsync.value;

    bool isUpdateNeeded = false;
    if (minRequiredVersion != null && currentVersion != null) {
      if (_isUpdateRequired(currentVersion, minRequiredVersion)) {
        isUpdateNeeded = true;
      }
    }

    // Use a post-frame callback to safely show the dialog *after* build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isUpdateNeeded && !_isUpdateDialogShown) {
        setState(() {
          _isUpdateDialogShown = true;
        });
        showDialog(
          context: context,
          barrierDismissible: false, // Non-dismissible
          builder: (dialogContext) => _buildUpdateDialog(
              dialogContext,
              minRequiredVersion!, // We know this is not null if isUpdateNeeded is true
              'https://play.google.com/store/apps/details?id=com.monexa.billing'
          ),
        );
      }
      // Note: We don't add an "else" to dismiss this dialog.
      // A force update is final until the user updates and restarts the app.
    });


    // 7. ALWAYS return the child.
    return widget.child;
  }


  // --- Dialog Builders ---

  Widget _buildBlockedDialog(BuildContext dialogContext) {
    return AlertDialog(
      icon: Icon(
        Icons.gpp_bad_outlined,
        color: Theme.of(context).colorScheme.error,
        size: 48,
      ),
      title: Text("Access Restricted"),
      content: Text(
        "Your account has been temporarily blocked due to a security concern or a violation of our terms.\n\nPlease contact our support team to regain access.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        FilledButton.icon(
          icon: Icon(Icons.contact_support_outlined),
          label: Text("Contact Support"),
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, 44),
          ),
          onPressed: () => _launchSupportEmail(context),
        ),
      ],
    );
  }

  // 8. ➡️ NEW: Dialog builder for the force update
  Widget _buildUpdateDialog(BuildContext dialogContext, String minVersion, String storeUrl) {
    return AlertDialog(
      icon: Icon(
        Icons.system_update_alt,
        color: Theme.of(context).colorScheme.primary,
        size: 48,
      ),
      title: Text("Update Required"),
      content: Text(
        "A new version of the app ($minVersion) is required to continue.\n\nPlease update to the latest version to keep using the app.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        FilledButton.icon(
          icon: Icon(Icons.update),
          label: Text("Update Now"),
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, 44),
          ),
          onPressed: () => _launchStoreUrl(storeUrl),
        ),
      ],
    );
  }
}