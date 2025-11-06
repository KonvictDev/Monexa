// Helper for confirmation dialogs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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