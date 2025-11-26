import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:billing/screens/settings/webview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding_screen.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/settings_utils.dart';
import '../auth/phone_sign_in_screen.dart';
import '../auth/register_screen.dart';
import '../subscription/subscription_screen.dart';
import 'business_profile_screen.dart';
import 'financial_defaults_screen.dart';
import 'receipt_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'change_pin_screen.dart';

// Imports for Auth & Sync
import '../../repositories/firebase_sync_repository.dart';
import '../../repositories/auth_repository.dart';
import 'package:billing/providers/pin_auth_provider.dart';
import 'package:billing/auth_wrapper.dart';
import '../../providers/user_profile_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? dataSizeBytes;
  bool _isLoading = false;
  String _appVersion = 'Loading...';
  String _appName = 'Monexa'; // Default fallback

  @override
  void initState() {
    super.initState();
    _calculateDataSize();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    // ➡️ Use the static methods from the utility class
    final name = await AppInfoUtil.getAppName();
    final version = await AppInfoUtil.getAppVersionString();

    if (mounted) {
      setState(() {
        _appName = name;
        _appVersion = version;
      });
    }
  }

  /// Calculates the total local data size (in bytes)
  Future<void> _calculateDataSize() async {
    final dir = await getApplicationDocumentsDirectory();
    int totalSize = 0;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    if (mounted) {
      setState(() => dataSizeBytes = totalSize);
    }
  }

  /// Shows the modal loading bottom sheet
  void _showLoadingSheet(BuildContext context, String text,
      {required VoidCallback onCancel}) {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return _LoadingSheetContent(
          title: text,
          onCancel: onCancel,
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Hides the modal loading bottom sheet
  void _hideLoadingSheet() {
    if (_isLoading && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Formats bytes into KB / MB / GB for readability
  String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  /// Handles Upgrade Modal for Gated Features
  void _showUpgradeModal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature requires Monexa Pro subscription. Please upgrade.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  // --- Sync Logic ---
  Future<void> _handleSync() async {
    if (_isLoading) return;

    final authRepo = ref.read(authRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    User? currentUser = authRepo.currentUser;
    if (currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneSignInScreen()),
      );
      return;
    }

    bool profileComplete = settingsRepo.get('profile_complete', defaultValue: false);

    if (!profileComplete) {
      final profileExists = await authRepo.doesProfileExist(currentUser.uid);
      if (!profileExists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterScreen(firebaseUser: currentUser),
          ),
        );
        return;
      } else {
        await settingsRepo.put('profile_complete', true);
      }
    }

    _showLoadingSheet(
      context,
      "Uploading data to Firebase...",
      onCancel: () => _hideLoadingSheet(),
    );

    String snackBarMessage;
    Color? snackBarColor;

    try {
      await ref.read(firebaseSyncRepositoryProvider).syncAllDataToFirebase();
      snackBarMessage = 'All local data successfully uploaded to Firebase!';
      snackBarColor = Colors.blue;
    } catch (e) {
      snackBarMessage =
      'Sync error: $e. Check your Firebase setup and network.';
      snackBarColor = Colors.red;
    }

    _hideLoadingSheet();

    if (context.mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          backgroundColor: snackBarColor,
        ),
      );
    }
  }

  // --- Restore Logic ---
  Future<void> _handleRestore() async {
    if (_isLoading) return;

    final authRepo = ref.read(authRepositoryProvider);

    if (authRepo.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first to restore data.')),
      );
      return;
    }

    showConfirmationDialog(
      context,
      title: 'Restore Data?',
      content:
      'This will DELETE ALL local orders, products, and expenses and replace them with data from the cloud. Continue?',
      confirmText: 'Restore',
      onConfirm: () async {
        if (_isLoading) return;
        _showLoadingSheet(
          context,
          "Restoring data from Firebase...",
          onCancel: () => _hideLoadingSheet(),
        );

        String snackBarMessage;
        Color? snackBarColor;
        bool success = false;

        try {
          await ref
              .read(firebaseSyncRepositoryProvider)
              .restoreAllDataFromFirebase();
          snackBarMessage = 'Data successfully restored!';
          snackBarColor = Colors.green;
          success = true;
        } catch (e) {
          snackBarMessage = 'Restore failed: $e. Check console and network.';
          snackBarColor = Colors.red;
        }

        _hideLoadingSheet();

        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackBarMessage),
              backgroundColor: snackBarColor,
            ),
          );
          if (success) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      },
    );
  }

  // --- Clear Data Logic ---
  void _handleClearAllData() {
    if (_isLoading) return;

    showConfirmationDialog(
      context,
      title: 'Delete All Data?',
      content:
      'This will delete all orders, products, and expenses permanently (${formatBytes(dataSizeBytes ?? 0)}).',
      onConfirm: () async {
        if (_isLoading) return;
        _showLoadingSheet(
          context,
          "Clearing all data...",
          onCancel: () => _hideLoadingSheet(),
        );

        try {
          await ref.read(settingsRepositoryProvider).clearAllData();

          _hideLoadingSheet();

          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
            );
          }
        } catch (e) {
          _hideLoadingSheet();
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to clear data: $e')),
            );
          }
        }
      },
    );
  }

  // --- Sign Out Method ---
  void _handleSignOut() {
    showConfirmationDialog(
      context,
      title: 'Sign Out?',
      content: 'Are you sure you want to sign out? You will need to verify your phone number to sign back in.',
      confirmText: 'Sign Out',
      onConfirm: () async {
        await ref.read(authRepositoryProvider).signOut();
        await ref.read(pinAuthProvider.notifier).resetPinAuth();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ➡️ FIX: Watch the isProProvider
    final isPro = ref.watch(isProProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        children: [
          // ➡️ NEW SECTION: Account & Subscription
          _sectionTitle(context, 'Account & Subscription'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: isPro ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
              title: isPro ? 'Monexa Pro Active' : 'Upgrade to Monexa Pro',
              subtitle: isPro ? 'Thank you for your support!' : 'Cloud Sync, Unlimited Data, and Advanced Analytics.',
              iconColor: isPro ? Colors.amber : Colors.green,
              titleColor: isPro ? Colors.amber.shade700 : Colors.green.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context, 'General & Business'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.business_center_rounded,
              title: 'Business Profile',
              subtitle: 'Edit business name, address, and tax details.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.monetization_on_rounded,
              title: 'Financial Defaults',
              subtitle: 'Set default tax rate and currency.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FinancialDefaultsScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'Receipt Customization',
              subtitle: 'Adjust receipt footer and shown details.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReceiptSettingsScreen()),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _sectionTitle(context, 'Appearance & Data'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.palette_rounded,
              title: 'App Appearance',
              subtitle: 'Switch theme or color scheme.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AppearanceSettingsScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.lock_reset_rounded,
              title: 'Change Security PIN',
              subtitle: 'Update your 4-digit passcode.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePinScreen()),
              ),
            ),
            // ➡️ GATED: Upload Data (Sync)
            _settingTile(
              context,
              icon: Icons.cloud_upload_rounded,
              title: 'Upload Data (Sync)',
              subtitle: isPro ? 'Send local data to Firebase.' : 'Requires Monexa Pro.',
              iconColor: isPro ? Colors.blue : Colors.grey,
              titleColor: isPro ? Colors.blue.shade700 : Colors.grey.shade600,
              onTap: isPro ? _handleSync : () => _showUpgradeModal(context),
            ),
            // ➡️ GATED: Download Data (Restore)
            _settingTile(
              context,
              icon: Icons.cloud_download_rounded,
              title: 'Download Data (Restore)',
              subtitle: isPro ? 'Overwrite local data with cloud backup.' : 'Requires Monexa Pro.',
              iconColor: isPro ? Colors.orange : Colors.grey,
              titleColor: isPro ? Colors.orange.shade700 : Colors.grey.shade600,
              onTap: isPro ? _handleRestore : () => _showUpgradeModal(context),
            ),
            _settingTile(
              context,
              icon: Icons.warning_amber_rounded,
              title: 'Clear All Data',
              subtitle: dataSizeBytes == null
                  ? 'Calculating data size...'
                  : 'Delete all app data permanently (${formatBytes(dataSizeBytes!)})',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: _handleClearAllData,
            ),
          ]),

          const SizedBox(height: 24),

          _sectionTitle(context, 'Legal & Information'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.gavel_rounded,
              title: 'Terms and Conditions',
              subtitle: 'Read official terms of use.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewScreen(
                      title: 'Terms & Conditions',
                      url:
                      'https://konvictdev.github.io/monexa_privacy/terms/index.html',
                    ),
                  ),
                );
              },
            ),
            _settingTile(
              context,
              icon: Icons.security_rounded,
              title: 'Privacy Policy',
              subtitle: 'Learn how your data is handled.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewScreen(
                      title: 'Privacy Policy',
                      url:
                      'https://konvictdev.github.io/monexa_privacy/privacy/index.html',
                    ),
                  ),
                );
              },
            ),
            _settingTile(
              context,
              icon: Icons.code_rounded,
              title: 'Open Source Licenses',
              subtitle: 'View app dependencies.',
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: _appName,
                  applicationVersion: _appVersion,
                );
              },
            ),
          ]),

          const SizedBox(height: 24),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Sign out of your Firebase account.',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: _handleSignOut,
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '$_appVersion • $_appName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Helper UI methods ---
  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _settingsCard(BuildContext context, List<Widget> children) => Card(
    elevation: 1,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Column(children: children),
  );

  Widget _settingTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        Color? iconColor,
        Color? titleColor,
      }) {
    return ListTile(
      leading:
      Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}

/// A dedicated StatefulWidget to manage the loading sheet's progress animation
class _LoadingSheetContent extends StatefulWidget {
  const _LoadingSheetContent({
    required this.title,
    required this.onCancel,
  });

  final String title;
  final VoidCallback onCancel;

  @override
  State<_LoadingSheetContent> createState() => _LoadingSheetContentState();
}

class _LoadingSheetContentState extends State<_LoadingSheetContent> {
  double _progress = 0.0;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isMounted) return false;

      if (mounted) {
        setState(() {
          _progress = (_progress + 0.03).clamp(0.0, 1.0);
        });
      }

      return _isMounted && _progress < 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (_progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Drag Handle ---
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // --- Title ---
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 36),

            // --- Animated Circular Progress ---
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor:
                    AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
                Text(
                  "$progressPercent%",
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --- Status text ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _progress < 1.0
                    ? "Processing your data..."
                    : "All done!",
                key: ValueKey(_progress < 1.0),
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Cancel Button ---
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text("Cancel"),
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                foregroundColor: theme.colorScheme.error,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}