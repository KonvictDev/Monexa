// lib/screens/business_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/settings_utils.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(settingsRepositoryProvider);
    _businessNameController = TextEditingController(text: repo.get('businessName', defaultValue: ''));
    _businessAddressController = TextEditingController(text: repo.get('businessAddress', defaultValue: ''));
    _taxIdController = TextEditingController(text: repo.get('businessTaxId', defaultValue: ''));
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _saveProfileSettings() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(settingsRepositoryProvider);
    repo.put('businessName', _businessNameController.text);
    repo.put('businessAddress', _businessAddressController.text);
    repo.put('businessTaxId', _taxIdController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Profile Saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Company Details', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 12),
              buildSettingsTextField(
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.storefront_rounded,
                validator: (v) => v!.isEmpty ? 'Please enter your business name' : null,
              ),
              const SizedBox(height: 16),
              buildSettingsTextField(
                controller: _businessAddressController,
                label: 'Business Address',
                icon: Icons.location_on_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              buildSettingsTextField(
                controller: _taxIdController,
                label: 'GSTIN / Tax ID',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 40),
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveProfileSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
