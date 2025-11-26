// Helper for confirmation dialogs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> showConfirmationDialog(
    BuildContext context, {
      required String title,
      required String content,
      required VoidCallback onConfirm,
      // 1. ADD THE NEW PARAMETER with a default value
      String confirmText = 'Confirm',
      String cancelText = 'Cancel', // Optional: Define cancel text too
    }) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText), // Use cancelText
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmText), // 2. USE THE NEW PARAMETER HERE
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------
// Reusable text field builder for all settings screens
// ---------------------------------------------------------------------
TextFormField buildSettingsTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  int maxLines = 1,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
}) {
  return TextFormField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.brown.shade400,
          width: 1.8,
        ),
      ),
    ),
    maxLines: maxLines,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    validator: validator,
  );
}
class AppInfoUtil {
  // Static variable to cache the info once loaded
  static PackageInfo? _packageInfo;

  /// Loads package info once and returns the PackageInfo object.
  static Future<PackageInfo> getPackageInfo() async {
    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
    return _packageInfo!;
  }

  /// Returns the formatted application version string (e.g., 1.0.0 (Build 1)).
  static Future<String> getAppVersionString() async {
    final info = await getPackageInfo();
    return 'Version ${info.version} (${info.buildNumber})';
  }

  /// Returns the application name.
  static Future<String> getAppName() async {
    final info = await getPackageInfo();
    return info.appName;
  }
}
