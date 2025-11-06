import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/settings_utils.dart';

class FinancialDefaultsScreen extends ConsumerStatefulWidget {
  const FinancialDefaultsScreen({super.key});

  @override
  ConsumerState<FinancialDefaultsScreen> createState() =>
      _FinancialDefaultsScreenState();
}

class _FinancialDefaultsScreenState
    extends ConsumerState<FinancialDefaultsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taxRateController;
  late TextEditingController _currencySymbolController;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(settingsRepositoryProvider);
    _taxRateController = TextEditingController(
        text: repo.get('taxRate', defaultValue: 0.0).toString());
    _currencySymbolController =
        TextEditingController(text: repo.get('currencySymbol', defaultValue: '₹'));
  }

  void _saveFinancialSettings() {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(settingsRepositoryProvider);
      repo.put('taxRate', double.tryParse(_taxRateController.text) ?? 0.0);
      repo.put('currencySymbol', _currencySymbolController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financial defaults saved!')),
      );
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Defaults'),


      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Default Financial Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These apply automatically to new transactions.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: buildSettingsTextField(
                          controller: _taxRateController,
                          label: 'Default Tax Rate (%)',
                          icon: Icons.percent,
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: buildSettingsTextField(
                          controller: _currencySymbolController,
                          label: 'Symbol',
                          icon: Icons.currency_rupee_rounded,
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),


                    ],




                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _saveFinancialSettings, // or _saveProfileSettings / _saveFinancialSettings etc.
                    ),
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
