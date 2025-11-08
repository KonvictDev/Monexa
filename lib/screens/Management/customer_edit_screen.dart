// lib/screens/management/customer_edit_screen.dart (MODIFIED - Gating and Tag Passing)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/customer.dart';
import '../../repositories/customer_repository.dart';
import '../../utils/settings_utils.dart';
import '../../services/gating_service.dart'; // ➡️ Import Gating Service

class CustomerEditScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerEditScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _tagController;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _tagController = TextEditingController(text: widget.customer?.tag ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _showUpgradeModal(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Customer $action requires Monexa Pro.')),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    // ➡️ GATING CHECK: Creation is restricted
    if (!_isEditing && !ref.read(gatingServiceProvider).canAccessFeature(Feature.customerManagement)) {
      _showUpgradeModal('creation');
      return;
    }

    final repo = ref.read(customerRepositoryProvider);

    try {
      if (_isEditing) {
        final existing = widget.customer!;
        existing
          ..name = _nameController.text
          ..phoneNumber = _phoneController.text
          ..email = _emailController.text
          ..address = _addressController.text
          ..tag = _tagController.text;
        await repo.updateCustomer(existing);
      } else {
        await repo.addCustomer(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          tag: _tagController.text, // ➡️ PASS TAG
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Customer updated' : 'Customer added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _deleteCustomer() {
    if (!_isEditing) return;

    // ➡️ GATING CHECK: Deletion is restricted
    if (!ref.read(gatingServiceProvider).canAccessFeature(Feature.customerManagement)) {
      _showUpgradeModal('deletion');
      return;
    }

    showConfirmationDialog(
      context,
      title: 'Delete Customer?',
      content: 'Are you sure you want to delete ${widget.customer!.name}?',
      onConfirm: () async {
        await ref.read(customerRepositoryProvider).deleteCustomer(widget.customer!);
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ➡️ GATING CHECK: Editing is implicitly gated by the save button now, but we grey out delete
    final canManage = ref.read(gatingServiceProvider).canAccessFeature(Feature.customerManagement);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            _isEditing ? 'Edit Customer' : 'Add Customer',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Tag (e.g., VIP, New)',
                    prefixIcon: Icon(Icons.label_important_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Save / Delete Buttons
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canManage ? _deleteCustomer : null,
                          icon: Icon(Icons.delete_outline, color: canManage ? Colors.red : Colors.grey),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: canManage ? Colors.red : Colors.grey,
                            side: BorderSide(color: canManage ? Colors.red : Colors.grey.shade400),
                          ),
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        // Save button is only enabled if: 1. Adding a new customer (gated above) or 2. Editing existing (and they can manage)
                        onPressed: canManage ? _saveCustomer : null,
                        icon: Icon(Icons.save, color: canManage ? Colors.white : Colors.grey.shade600),
                        label: Text(_isEditing ? 'Save Changes' : 'Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canManage ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}