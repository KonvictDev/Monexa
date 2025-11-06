// lib/screens/auth/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final User firebaseUser;
  const RegisterScreen({super.key, required this.firebaseUser});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _businessName = TextEditingController();
  final _businessAddress = TextEditingController();
  final _gstin = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        uid: widget.firebaseUser.uid,
        phoneNumber: widget.firebaseUser.phoneNumber!,
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()),
        email: _email.text.trim(),
        businessName: _businessName.text.trim(),
        businessAddress: _businessAddress.text.trim(),
        gstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
      );

      await ref.read(authRepositoryProvider).saveUserProfile(profile);

      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.put('businessName', profile.businessName);
      await settingsRepo.put('businessAddress', profile.businessAddress);
      await settingsRepo.put('businessEmail', profile.email);
      await settingsRepo.put('businessOwnerName', profile.name);
      await settingsRepo.put('businessGstin', profile.gstin);
      await settingsRepo.put('profile_complete', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: _SmoothScrollBehavior(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  Text(
                    'Welcome! Let’s set up your business profile',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please fill in your details below to continue.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  TextFormField(
                    controller: _name,
                    decoration: _inputDecoration('Your Name*'),
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _age,
                    decoration: _inputDecoration('Your Age', hint: 'Optional'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: _inputDecoration('Email Address*'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _businessName,
                    decoration: _inputDecoration('Business Name*'),
                    validator: (v) => v!.isEmpty ? 'Business name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddress,
                    decoration: _inputDecoration('Business Address*'),
                    validator: (v) => v!.isEmpty ? 'Business address is required' : null,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstin,
                    decoration: _inputDecoration('GSTIN / Tax ID', hint: 'Optional'),
                  ),
                  const SizedBox(height: 36),

                  // Submit Button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save and Continue'),
                        onPressed: _registerUser,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isLoading)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom scroll behavior for smooth + bouncy effect across platforms
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use bouncy scroll on all platforms for consistency
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
