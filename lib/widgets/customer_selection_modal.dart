// lib/widgets/customer_selection_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/customer.dart';
import '../repositories/customer_repository.dart';
import '../providers/cart_provider.dart';

class CustomerSelectionModal extends ConsumerStatefulWidget {
  const CustomerSelectionModal({super.key});

  @override
  ConsumerState<CustomerSelectionModal> createState() =>
      _CustomerSelectionModalState();
}

class _CustomerSelectionModalState
    extends ConsumerState<CustomerSelectionModal> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer? customer) {
    // If customer is null, it's a "Walk-in Customer"
    final customerName = customer?.name ?? 'Walk-in Customer';
    ref.read(cartProvider.notifier).updateCustomerName(customerName);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(customerRepositoryProvider);
    // Get the list of customers based on the search
    final customers = repo.searchCustomers(_searchQuery);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Select Customer',
              style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // --- Default "Walk-in Customer" Option ---
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.storefront),
            ),
            title: const Text('Walk-in Customer', style: TextStyle(fontStyle: FontStyle.italic)),
            onTap: () => _selectCustomer(null), // Pass null
          ),
          const Divider(),
          // --- Customer List ---
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.phoneNumber),
                  onTap: () => _selectCustomer(customer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}