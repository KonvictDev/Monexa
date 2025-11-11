// lib/architecture/app_check_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// ➡️ CORRECTED IMPORT: Ensure this points to your consolidated providers file
import 'package:billing/providers/app_check_providers.dart';

class AppCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppCheckWrapper({super.key, required this.child});

  @override
  ConsumerState<AppCheckWrapper> createState() => _AppCheckWrapperState();
}

class _AppCheckWrapperState extends ConsumerState<AppCheckWrapper> {
  bool _isBlockedDialogShown = false;
  bool _isUpdateDialogShown = false;

  void _launchSupportEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@monexa.billing',
      query: 'subject=Account Blocked Inquiry',
    );
    _launchUri(emailLaunchUri, 'Could not open email app.');
  }

  void _launchStoreUrl(String url) async {
    final Uri storeUri = Uri.parse(url);
    _launchUri(storeUri, 'Could not open app store.', mode: LaunchMode.externalApplication);
  }

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

  bool _isUpdateRequired(String currentVersion, String minRequiredVersion) {
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
    // --- Block Check Listener ---
    // ✅ The Provider type is correctly inferred as AsyncValue<bool>
    //    because isBlockedProvider in app_check_providers.dart is a FutureProvider.
    ref.listen<AsyncValue<bool>>(isBlockedProvider, (prev, next) {
      // Safely check the resolved value
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
              minRequiredVersion!,
              'https://play.google.com/store/apps/details?id=com.monexa.billing'
          ),
        );
      }
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
      title: const Text("Access Restricted"),
      content: Text(
        "Your account has been temporarily blocked due to a security concern or a violation of our terms.\n\nPlease contact our support team to regain access.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.contact_support_outlined),
          label: const Text("Contact Support"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: () => _launchSupportEmail(context),
        ),
      ],
    );
  }

  Widget _buildUpdateDialog(BuildContext dialogContext, String minVersion, String storeUrl) {
    return AlertDialog(
      icon: Icon(
        Icons.system_update_alt,
        color: Theme.of(context).colorScheme.primary,
        size: 48,
      ),
      title: const Text("Update Required"),
      content: Text(
        "A new version of the app ($minVersion) is required to continue.\n\nPlease update to the latest version to keep using the app.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.update),
          label: const Text("Update Now"),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => _launchStoreUrl(storeUrl),
        ),
      ],
    );
  }
}