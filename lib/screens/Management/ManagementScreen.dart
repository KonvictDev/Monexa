// lib/screens/management_screen.dart
import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'expense_screen.dart';
import 'update_stocks_screen.dart';
import 'view_orders_screen.dart';
import 'customer_list_screen.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      _MenuItem(
        title: 'Add Product',
        icon: Icons.add_box_rounded,
        color: Colors.blue,
        screen: const AddProductScreen(),
      ),
      _MenuItem(
        title: 'Manage Stock',
        icon: Icons.warehouse_rounded,
        color: Colors.orange,
        screen: const UpdateStocksScreen(),
      ),
      _MenuItem(
        title: 'View Orders',
        icon: Icons.receipt_long_rounded,
        color: Colors.green,
        screen: const ViewOrdersScreen(),
      ),
      _MenuItem(
        title: 'Expenses',
        icon: Icons.currency_rupee_rounded,
        color: Colors.red,
        screen: const ExpenseScreen(),
      ),
      _MenuItem(
        title: 'Customer Hub',
        icon: Icons.people_alt_rounded,
        color: Colors.purple,
        screen: const CustomerListScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Management Hub'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ManagementCard(
              item: item,
              onTap: () => _navigateTo(context, item.screen),
              colorScheme: colorScheme,
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _ManagementCard extends StatefulWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ManagementCard({
    required this.item,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_ManagementCard> createState() => _ManagementCardState();
}

class _ManagementCardState extends State<_ManagementCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.97);
  void _onTapUp(_) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          elevation: 4,
          shadowColor: item.color.withOpacity(0.25),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            splashColor: item.color.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.color.withOpacity(0.12),
                    item.color.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Icon(item.icon, color: item.color, size: 42),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: widget.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
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
