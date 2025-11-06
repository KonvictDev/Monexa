import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/order.dart'; // Make sure this import path is correct
import '../model/expense.dart'; // Make sure this import path is correct

class SummaryTable extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<Order> orders;
  final List<Expense> expenses;

  const SummaryTable({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.orders,
    required this.expenses,
  });

  // Helper widget for the header (unchanged)
  Widget _buildHeader(BuildContext context) {
    final headerStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Date', style: headerStyle)),
          Expanded(flex: 3, child: Text('Revenue', style: headerStyle, textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text('Expenses', style: headerStyle, textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text('Profit', style: headerStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ✅ MODIFIED: Helper widget for each data row
  Widget _buildDataRow(
      BuildContext context,
      DateTime date,
      double rev,
      double exp,
      double profit, {
        required bool isLast, // Flag to prevent drawing divider on last item
      }) {
    final profitStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
    );

    // Replaced the decorated Container with a Column
    return Column(
      children: [
        // This Container holds the text content, same as before but no decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(DateFormat('dd/MM/yy').format(date))),
              Expanded(flex: 3, child: Text('₹${rev.toStringAsFixed(2)}', textAlign: TextAlign.right)),
              Expanded(flex: 3, child: Text('₹${exp.toStringAsFixed(2)}', textAlign: TextAlign.right)),
              Expanded(
                flex: 3,
                child: Text(
                  '₹${profit.toStringAsFixed(2)}',
                  style: profitStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Conditionally add an indented Divider
        if (!isLast)
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: Colors.grey.shade600,
            indent: 16.0, // Starts where the text starts
            endIndent: 16.0, // Ends where the text ends
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Data processing logic (unchanged) ---
    final Map<DateTime, double> revenueByDay = {};
    final Map<DateTime, double> expenseByDay = {};

    for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final day = DateTime(startDate.year, startDate.month, startDate.day + i);
      revenueByDay[day] = 0;
      expenseByDay[day] = 0;
    }

    for (final o in orders) {
      final d = DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day);
      if (revenueByDay.containsKey(d)) {
        revenueByDay[d] = revenueByDay[d]! + o.totalAmount;
      }
    }

    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (expenseByDay.containsKey(d)) {
        expenseByDay[d] = expenseByDay[d]! + e.amount;
      }
    }

    final rows = revenueByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    if (rows.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no data
    }
    // --- End of data processing ---

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Daily Profit Summary",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          _buildHeader(context),

          // ✅ MODIFIED: Use asMap().entries.map() to get the index
          Column(
            children: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              final isLast = index == rows.length - 1; // Check if last

              final rev = revenueByDay[d]!;
              final exp = expenseByDay[d]!;
              final profit = rev - exp;

              // Pass the isLast flag to the build method
              return _buildDataRow(context, d, rev, exp, profit, isLast: isLast);
            }).toList(),
          ),

          // No need for the extra SizedBox, the last item just won't have a line.
          // If you want padding after the last item, you can add it here.
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}