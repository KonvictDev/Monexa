import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:billing/screens/settings/webview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main_navigation_screen.dart';
import '../../onboarding_screen.dart';
import '../../repositories/settings_repository.dart';
import '../../services/remote_config_service.dart';
import '../../utils/settings_utils.dart';
import '../../widgets/upgrade_snackbar.dart';
import '../auth/phone_sign_in_screen.dart';
import '../auth/register_screen.dart';
import '../subscription/subscription_screen.dart';
import 'business_profile_screen.dart';
import 'financial_defaults_screen.dart';
import 'receipt_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'change_pin_screen.dart';
import 'package:share_plus/share_plus.dart'; // ✅ NEW: For Sharing
import 'package:url_launcher/url_launcher.dart'; // ✅ NEW: For Email

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

  void _showUpgradeModal(BuildContext context) {
    showUpgradeSnackbar(context, 'Cloud Feature requires Monexa Pro subscription.');
  }

  void _enableStaffMode() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to size itself correctly
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          // Add safe area padding for bottom navigation bar gesture area
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Drag Handle ---
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // --- Hero Icon ---
            Center(
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge_rounded,
                  size: 32,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Title & Description ---
            Text(
              "Enter Staff Mode?",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "This restricts the app to 'Billing Only'.\nYour Dashboard, Settings, and Inventory will be hidden.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Warning / Info Card ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.tertiaryContainer,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: colorScheme.tertiary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin PIN Required",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "You will need your 4-digit PIN to exit this mode.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Actions ---
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact(); // Tactile confirmation
                      // 1. Enable Staff Mode
                      await ref
                          .read(settingsRepositoryProvider)
                          .setStaffMode(true);

                      if (mounted) {
                        // 2. Restart App Navigation
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen()),
                              (route) => false,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Enter Mode"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ✅ NEW: Delete Account Logic (Fixed Spacing Issue)
  void _launchDeleteAccountEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = user?.phoneNumber ?? 'Unknown';
    final uid = user?.uid ?? 'Unknown';

    // Helper to force %20 encoding for spaces instead of +
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@appsbyanandakumar.com',
      query: encodeQueryParameters({
        'subject': 'Request to Delete Account',
        'body':
        'I request the permanent deletion of my account and all associated data.\n\nPhone Number: $phoneNumber\nUser ID: $uid\n\nI understand this action is irreversible.',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  // ✅ NEW: Share App Logic (Viral Growth)
  void _shareApp() {
    Share.share(
      'Check out Monexa - the simple billing app for small businesses!\n\nDownload here: https://play.google.com/store/apps/details?id=com.appsbyanandakumar.billing',
    );
  }


  // --- Sync Logic ---
  Future<void> _handleSync() async {
    if (_isLoading) return;
    // ✅ NEW: Check Rate Limit (Owner also has limit to save costs)
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final remoteConfig = ref.read(remoteConfigServiceProvider);

    // Check limit
    if (!settingsRepo.canSync(remoteConfig.dailySyncLimit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily sync limit reached. Try tomorrow.')),
      );
      return;
    }


    final authRepo = ref.read(authRepositoryProvider);

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
      await settingsRepo.incrementSyncCount();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Drag Handle ---
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // --- Hero Icon (Red for Logout) ---
            Center(
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Title & Description ---
            Text(
              "Sign Out?",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You will be disconnected from your account.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Warning Info Card ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.phonelink_ring_rounded,
                      color: colorScheme.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Verification Required",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "To sign back in, you will need to verify your phone number again.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Actions ---
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      // 1. Sign Out Logic
                      await ref.read(authRepositoryProvider).signOut();
                      await ref.read(pinAuthProvider.notifier).resetPinAuth();

                      if (mounted) {
                        // 2. Navigate to Auth Wrapper
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthWrapper()),
                              (route) => false,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Sign Out"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          // 1️⃣ SUBSCRIPTION (Highlighted at top)
          _sectionTitle(context, 'Monexa Pro'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: isPro ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
              title: isPro ? 'Monexa Pro Active' : 'Upgrade to Monexa Pro',
              subtitle: isPro
                  ? 'Thank you for your support!'
                  : 'Unlock Cloud Sync, Unlimited Data & Analytics.',
              iconColor: isPro ? Colors.amber : Colors.green,
              titleColor: isPro ? Colors.amber.shade700 : Colors.green.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // 2️⃣ BUSINESS & CUSTOMIZATION (The "Setup" stuff)
          _sectionTitle(context, 'Business & Personalization'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.storefront_rounded, // Better icon for profile
              title: 'Business Profile',
              subtitle: 'Name, address, and tax details.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.currency_rupee_rounded,
              title: 'Financial Defaults',
              subtitle: 'Tax rate and currency symbol.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinancialDefaultsScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'Receipt Design',
              subtitle: 'Customize footer and print options.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptSettingsScreen()),
              ),
            ),
            _settingTile(
              context,
              icon: Icons.palette_rounded,
              title: 'App Appearance',
              subtitle: 'Theme colors and dark mode.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // 3️⃣ SECURITY & ACCESS (The "Control" stuff)
          _sectionTitle(context, 'Security & Access'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.badge_outlined,
              title: 'Staff Mode',
              subtitle: 'Restrict app access for employees.',
              iconColor: Colors.deepPurple,
              titleColor: Colors.deepPurple.shade700,
              onTap: _enableStaffMode,
            ),
            _settingTile(
              context,
              icon: Icons.lock_reset_rounded,
              title: 'Change Master PIN',
              subtitle: 'Update your 4-digit security code.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePinScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // 4️⃣ DATA & CLOUD (The "Heavy" stuff)
          _sectionTitle(context, 'Data Management'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.cloud_upload_rounded,
              title: 'Sync to Cloud',
              subtitle: isPro ? 'Backup local data to Firebase.' : 'Requires Monexa Pro.',
              iconColor: Colors.blue,
              onTap: isPro ? _handleSync : () => _showUpgradeModal(context),
            ),
            _settingTile(
              context,
              icon: Icons.cloud_download_rounded,
              title: 'Restore from Cloud',
              subtitle: isPro ? 'Overwrite app with cloud backup.' : 'Requires Monexa Pro.',
              iconColor: Colors.orange,
              onTap: isPro ? _handleRestore : () => _showUpgradeModal(context),
            ),
            _settingTile(
              context,
              icon: Icons.delete_sweep_rounded,
              title: 'Clear Local Data',
              subtitle: dataSizeBytes == null
                  ? 'Calculating...'
                  : 'Delete on-device data (${formatBytes(dataSizeBytes!)})',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: _handleClearAllData,
            ),
          ]),
          const SizedBox(height: 24),

          // 5️⃣ ABOUT & LEGAL (The "Footer" stuff)
          _sectionTitle(context, 'About & Support'),
          _settingsCard(context, [
            _settingTile(
              context,
              icon: Icons.favorite_rounded, // Friendly icon
              title: 'Tell a Friend',
              subtitle: 'Share Monexa with others.',
              iconColor: Colors.pink,
              onTap: _shareApp,
            ),
            _settingTile(
              context,
              icon: Icons.policy_rounded,
              title: 'Legal & Privacy',
              subtitle: 'Terms, Privacy Policy, and Licenses.',
              onTap: () {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allows content to determine height
                  backgroundColor: colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16, // Safe area
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. Drag Handle ---
                        Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // --- 2. Header Title ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Text(
                            "Legal Information",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // --- 3. Menu Items ---
                        _buildLegalTile(
                          context,
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WebViewScreen(
                                  title: 'Terms & Conditions',
                                  url: 'https://konvictdev.github.io/monexa_privacy/terms/index.html',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildLegalTile(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WebViewScreen(
                                  title: 'Privacy Policy',
                                  url: 'https://konvictdev.github.io/monexa_privacy/privacy/index.html',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildLegalTile(
                          context,
                          icon: Icons.code_rounded,
                          title: 'Open Source Licenses',
                          onTap: () {
                            Navigator.pop(context);
                            showLicensePage(
                              context: context,
                              applicationName: _appName,
                              applicationVersion: _appVersion,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            _settingTile(
              context,
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Disconnect your account.',
              onTap: _handleSignOut,
            ),
            _settingTile(
              context,
              icon: Icons.no_accounts_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account.',
              iconColor: Colors.grey,
              onTap: _launchDeleteAccountEmail,
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '$_appName $_appVersion',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).hintColor.withOpacity(0.5),
              ),
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
  Widget _buildLegalTile(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.outline,
        size: 20,
      ),
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