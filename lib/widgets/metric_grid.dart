// lib/widgets/metric_grid.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_filter.dart'; // Ensure this import is correct

class MetricGrid extends StatelessWidget {
  final DateFilter filter;
  final double revenue;
  final double expenses;
  final double profit;
  final int orders;
  final double avgOrder;
  final double totalProfit;
  // --- NEW PARAMETER ---
  final bool isTotalProfitLoading;
  // --- END NEW PARAMETER ---

  const MetricGrid({
    super.key,
    required this.filter,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.orders,
    required this.avgOrder,
    required this.totalProfit,
    required this.isTotalProfitLoading, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    // --- MODIFIED TOTAL PROFIT DATA ---
    final List<(String, String?, IconData, Color, {bool isLoading})> metrics = [
      ('Revenue', nf.format(revenue), Icons.trending_up_rounded, Colors.green, isLoading: false),
      ('Expenses', nf.format(expenses), Icons.trending_down_rounded, Colors.red, isLoading: false),
      ('Profit', nf.format(profit), Icons.currency_rupee_rounded, profit >= 0 ? Colors.green : Colors.red, isLoading: false),
      ('Orders', '$orders', Icons.shopping_cart_rounded, Colors.blue, isLoading: false),
      ('Avg Order', nf.format(avgOrder), Icons.receipt_long_rounded, Colors.orange, isLoading: false),
      // Pass null for value if loading, and pass the loading flag
      ('Total Profit', isTotalProfitLoading ? null : nf.format(totalProfit), Icons.account_balance_rounded, Colors.teal, isLoading: isTotalProfitLoading),
    ];
    // --- END MODIFICATION ---

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth / 2) - 16;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics
            .map((m) => SizedBox(
          width: itemWidth,
          child: _MetricCard(
            title: m.$1,
            value: m.$2, // Can be null now
            icon: m.$3,
            color: m.$4,
            isLoading: m.isLoading, // Pass loading state
          ),
        ))
            .toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String? value; // Value can be null
  final IconData icon;
  final Color color;
  final bool isLoading; // New flag

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  // --- CONDITIONAL DISPLAY ---
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0), // Adjust alignment
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Text(
                      value ?? 'N/A', // Show value or N/A if null
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  // --- END CONDITIONAL DISPLAY ---
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}