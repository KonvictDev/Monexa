import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import '../../model/order.dart';
import '../../repositories/order_repository.dart';

// 1. Convert to ConsumerStatefulWidget
class ViewOrdersScreen extends ConsumerStatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  ConsumerState<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends ConsumerState<ViewOrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Use ValueListenableBuilder's listener to rebuild, just set state
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

  // 2. Add Date Range Picker
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // 3. Add Clear Filters
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
    });
  }

  // 4. Keep the bottom sheet (no changes needed)
  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final formattedDate =
        DateFormat.yMMMMd().add_jm().format(order.orderDate);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Order Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Customer info
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${order.customerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Date: $formattedDate',
                          style: TextStyle(color: colorScheme.outline)),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),

                // List of items
                ...order.items.map((item) => Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle:
                    Text('Qty: ${item.quantity} × ₹${item.price}'),
                    trailing: Text(
                      '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Close'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderRepository = ref.watch(orderRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 5. Determine if filters are active
    final bool hasFilters =
        _searchQuery.isNotEmpty || _startDate != null || _endDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Orders'),
        elevation: 0,
      ),
      body: Column(
        // 6. Wrap in Column
        children: [
          // --- START FILTER BAR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Customer or Invoice #',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear,
                    )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _startDate == null
                              ? 'Filter by Date'
                              : '${DateFormat.yMd().format(_startDate!)} - ${DateFormat.yMd().format(_endDate!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_list_off_outlined),
                        tooltip: 'Clear Filters',
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          // --- END FILTER BAR ---

          // --- START ORDER LIST ---
          Expanded(
            // 7. Make ListView expanded
            child: ValueListenableBuilder(
              valueListenable: orderRepository.getListenable(),
              builder: (context, Box<Order> box, _) {
                // 8. Call new repository method
                final orders = orderRepository.searchAndFilterOrders(
                  query: _searchQuery,
                  startDate: _startDate,
                  endDate: _endDate,
                );

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      hasFilters
                          ? 'No orders match your filters.'
                          : 'No orders yet.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjust padding
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final o = orders[i]; // Use the filtered list

                    final itemSummary = o.items
                        .map((item) => '${item.name} ×${item.quantity}')
                        .join(', ');
                    final formattedDate =
                    DateFormat.yMMMd().add_jm().format(o.orderDate);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        onTap: () => _showOrderDetails(context, o),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                o.customerName,
                                style:
                                const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              o.invoiceNumber,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Items: $itemSummary\nDate: $formattedDate\nTotal: ₹${o.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => orderRepository.deleteOrder(o),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}