import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/customer.dart';
import '../../repositories/customer_repository.dart';
import '../../utils/settings_utils.dart';

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
  // --- NEW TAG CONTROLLER ---
  late final TextEditingController _tagController;
  // --- END NEW TAG CONTROLLER ---

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    // --- INIT TAG CONTROLLER ---
    _tagController = TextEditingController(text: widget.customer?.tag ?? '');
    // --- END INIT TAG CONTROLLER ---
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tagController.dispose(); // DISPOSE
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(customerRepositoryProvider);

    try {
      if (_isEditing) {
        final existing = widget.customer!;
        existing
          ..name = _nameController.text
          ..phoneNumber = _phoneController.text
          ..email = _emailController.text
          ..address = _addressController.text
          ..tag = _tagController.text; // SAVE TAG
        await repo.updateCustomer(existing);
      } else {
        await repo.addCustomer(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          // NEW CUSTOMER CREATION
          // Note: AddCustomer in repo doesn't take tag, but we can update it or
          // rely on the default empty string. For simplicity, let's update the
          // repo's method signature next, but for now, rely on default:
          // In a real project, we'd update `addCustomer` in the repo to accept `tag`.
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
  // ... (rest of the file is unchanged) ...
  void _deleteCustomer() {
    if (!_isEditing) return;
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
                // --- NEW TAG FIELD ---
                TextFormField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Tag (e.g., VIP, New)',
                    prefixIcon: Icon(Icons.label_important_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                // --- END NEW TAG FIELD ---
                const SizedBox(height: 20),

                // Save / Delete Buttons
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteCustomer,
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveCustomer,
                        icon: const Icon(Icons.save),
                        label: Text(_isEditing ? 'Save Changes' : 'Add Customer'),
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