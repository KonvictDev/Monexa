import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/customer.dart';
import '../../model/order.dart';
import '../../model/order_item.dart'; // <-- Ensure OrderItem is available
import '../../repositories/customer_repository.dart';
import '../../repositories/order_repository.dart';
import 'customer_edit_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final dynamic customerKey;

  const CustomerDetailScreen({super.key, required this.customerKey});

  void _showEditSheet(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CustomerEditScreen(customer: customer),
      ),
    );
  }

  // --- NEW: Reusable Order Details Modal Function ---
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
                  'Order Details (INV: ${order.invoiceNumber})',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Order Summary Info
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
                      Text('Payment: ${order.paymentMethod.toUpperCase()}',
                          style: TextStyle(color: colorScheme.outline)),
                      const SizedBox(height: 8),
                      Text(
                        'Grand Total: ₹${order.totalAmount.toStringAsFixed(2)}',
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
                // Add totals breakdown here if needed (Discount, Tax, Subtotal)

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
  // --- END NEW: Reusable Order Details Modal Function ---


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerRepo = ref.watch(customerRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: customerRepo.getListenable(),
      builder: (context, Box<Customer> box, child) {
        final Customer? currentCustomer = box.get(customerKey);

        if (currentCustomer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Not Found')),
            body: const Center(child: Text('This customer no longer exists.')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentCustomer.name),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditSheet(context, currentCustomer),
                  tooltip: 'Edit Customer',
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Profile', icon: Icon(Icons.person_outline)),
                  Tab(text: 'Orders', icon: Icon(Icons.receipt_long_outlined)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _CustomerProfileTab(customer: currentCustomer),
                // Pass the modal function down to the Order History Tab
                _CustomerOrderHistoryTab(
                  customer: currentCustomer,
                  onOrderTap: (order) => _showOrderDetails(context, order),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------------
// Customer Profile Tab (UNCHANGED)
// -------------------------------------------------------------------

class _CustomerProfileTab extends ConsumerWidget {
  final Customer customer;
  const _CustomerProfileTab({required this.customer});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Show snackbar or log error
    }
  }

  void _callCustomer(String number) => _launchUrl('tel:$number');
  void _smsCustomer(String number) => _launchUrl('sms:$number');
  void _emailCustomer(String email) => _launchUrl('mailto:$email');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orderRepo = ref.watch(orderRepositoryProvider);
    final orders = orderRepo.getOrdersByCustomerName(customer.name);

    final int transactionCount = orders.length;
    final double totalSpent = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final double averageOrderValue = transactionCount == 0 ? 0.0 : totalSpent / transactionCount;
    final DateTime? lastOrderDate = orders.isNotEmpty ? orders.first.orderDate : null;
    final String aovDisplay = NumberFormat.simpleCurrency(name: '₹').format(averageOrderValue);
    final String lastOrderDisplay = lastOrderDate != null ? DateFormat.yMMMd().format(lastOrderDate) : 'N/A';
    final String frequencyDisplay = transactionCount > 0
        ? '${transactionCount} orders total'
        : 'No history';


    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // 👈 smooth + bouncy scroll
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, customer.name, customer.tag),
          const SizedBox(height: 20),

          _buildCommunicationSection(theme, customer),
          const SizedBox(height: 20),

          Text(
            'Customer Health',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  _buildMetricCard(theme, 'Average Order Value', aovDisplay, Icons.payments_outlined, cardWidth),
                  _buildMetricCard(theme, 'Last Order Date', lastOrderDisplay, Icons.calendar_today_outlined, cardWidth),
                  _buildMetricCard(theme, 'Transaction Count', frequencyDisplay, Icons.shopping_bag_outlined, cardWidth),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          Text(
            'Contact Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildDetailCard(
            theme,
            title: 'Phone Number',
            value: customer.phoneNumber,
            icon: Icons.phone_outlined,
          ),
          _buildDetailCard(
            theme,
            title: 'Email Address',
            value: customer.email,
            icon: Icons.email_outlined,
          ),
          _buildDetailCard(
            theme,
            title: 'Address',
            value: customer.address,
            icon: Icons.location_on_outlined,
            isAddress: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String name, String tag) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (tag.isNotEmpty)
            Chip(
              label: Text(tag),
              backgroundColor: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
              labelStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
              visualDensity: VisualDensity.compact,
            )
          else
            Text(
              'Customer Record',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunicationSection(ThemeData theme, Customer customer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CommsButton(
          label: 'Call',
          icon: Icons.call_outlined,
          enabled: customer.phoneNumber.isNotEmpty,
          onPressed: () => _callCustomer(customer.phoneNumber),
        ),
        _CommsButton(
          label: 'SMS',
          icon: Icons.sms_outlined,
          enabled: customer.phoneNumber.isNotEmpty,
          onPressed: () => _smsCustomer(customer.phoneNumber),
        ),
        _CommsButton(
          label: 'Email',
          icon: Icons.email_outlined,
          enabled: customer.email.isNotEmpty,
          onPressed: () => _emailCustomer(customer.email),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      ThemeData theme,
      String title,
      String value,
      IconData icon,
      double width,
      ) {
    return SizedBox(
      width: width, // ✅ each card gets half the screen width
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ height = content height
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildDetailCard(ThemeData theme, {required String title, required String value, required IconData icon, bool isAddress = false}) {
    final valueDisplay = value.isEmpty ? 'N/A' : value;
    final color = value.isEmpty ? theme.hintColor : theme.colorScheme.onSurface;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          valueDisplay,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            height: isAddress ? 1.4 : 1.0,
          ),
          maxLines: isAddress ? 3 : 1,
          overflow: isAddress ? null : TextOverflow.ellipsis,
        ),
        isThreeLine: isAddress,
      ),
    );
  }
}

class _CommsButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _CommsButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: enabled ? onPressed : null,
          color: theme.colorScheme.primary,
          iconSize: 32,
          tooltip: enabled ? label : '$label Unavailable',
        ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: enabled ? theme.colorScheme.primary : theme.hintColor,
          ),
        ),
      ],
    );
  }
}


// -------------------------------------------------------------------
// Customer Order History Tab (MODIFIED to accept onOrderTap)
// -------------------------------------------------------------------

class _CustomerOrderHistoryTab extends ConsumerWidget {
  final Customer customer;
  final Function(Order) onOrderTap; // <-- ADDED

  const _CustomerOrderHistoryTab({required this.customer, required this.onOrderTap}); // <-- MODIFIED CONSTRUCTOR

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: orderRepo.getListenable(),
      builder: (context, box, _) {
        final List<Order> orders = orderRepo.getOrdersByCustomerName(customer.name);

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No past orders found for ${customer.name}.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          );
        }

        final double totalSpent = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
        final String formattedSpent = NumberFormat.simpleCurrency(name: '₹').format(totalSpent);

        return ListView.builder(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lifetime Value (LTV)', style: theme.textTheme.titleSmall),
                      Text(
                        formattedSpent,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${orders.length} total transactions', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            }

            final order = orders[index - 1];
            final formattedDate = DateFormat.yMMMd().format(order.orderDate);
            final formattedTotal = NumberFormat.simpleCurrency(name: '₹').format(order.totalAmount);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              child: ListTile(
                title: Text(order.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Items: ${order.items.length} • $formattedDate'),
                trailing: Text(
                  formattedTotal,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => onOrderTap(order), // <-- IMPLEMENTED ONTAP
              ),
            );
          },
        );
      },
    );
  }
}