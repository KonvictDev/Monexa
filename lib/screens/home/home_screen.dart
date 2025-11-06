import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../services/csv_service.dart';

// Modular widgets
import '../../widgets/filter_bar.dart';
import '../../widgets/metric_grid.dart';
import '../../widgets/sales_chart.dart';
import '../../widgets/summary_table.dart';

import '../../utils/date_filter.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final dashboard = ref.watch(dashboardProvider);
    final dashboardNotifier = ref.read(dashboardProvider.notifier);
    final theme = Theme.of(context);

    Future<void> _selectCustomDateRange(BuildContext context) async {
      // ... (this method is unchanged) ...
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: dashboard.startDate,
          end: dashboard.endDate,
        ),
      );
      dashboardNotifier.selectCustomDateRange(picked);
    }

    Future<void> _exportData() async {
      // ... (this method is unchanged) ...
      dashboardNotifier.setLoading(true);
      final csvService = CsvService();

      final result = await csvService.exportData(
        startDate: dashboard.startDate,
        endDate: dashboard.endDate,
        orders: dashboard.filteredOrders,
        expenses: dashboard.filteredExpenses,
      );

      dashboardNotifier.setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    }

    // --- CATEGORY FILTER WIDGET ---
    Widget _buildCategoryFilter() {
      // Create list with "All Categories" at the start
      final categories = ['All Categories', ...dashboard.allCategories];
      // Set value to null if it's "All Categories", otherwise use the selected value
      final String? currentValue = dashboard.selectedCategory == null
          ? 'All Categories'
          : dashboard.selectedCategory;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentValue,
                  isExpanded: true,
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      dashboardNotifier.setCategoryFilter(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    // --- END CATEGORY FILTER WIDGET ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          // ... (refresh button is unchanged) ...
          dashboard.isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => dashboardNotifier.refreshData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: ValueKey(dashboard.selectedFilter),
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 80), // Reduced top padding
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MODIFIED FILTER AREA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FilterBar(
                selectedFilter: dashboard.selectedFilter,
                isLoading: dashboard.isLoading,
                startDate: dashboard.startDate,
                endDate: dashboard.endDate,
                onFilterChanged: (DateFilter newFilter) async {
                  if (newFilter == DateFilter.custom) {
                    await _selectCustomDateRange(context);
                  } else {
                    dashboardNotifier.updateDateFilter(newFilter);
                  }
                },
                onExport: _exportData,
              ),
            ),

            // --- ADDED CATEGORY FILTER ---
            _buildCategoryFilter(),
            // --- END ADDED FILTER ---

            MetricGrid(
              filter: dashboard.selectedFilter,
              revenue: dashboard.filteredRevenue,
              expenses: dashboard.filteredExpensesTotal,
              profit: dashboard.filteredProfit,
              orders: dashboard.filteredOrderCount,
              avgOrder: dashboard.filteredAvgOrderValue,
              totalProfit: dashboard.totalProfit,
              isTotalProfitLoading: dashboard.isTotalProfitLoading,
            ),

            const SizedBox(height: 20),

            SalesChartWidget(
              startDate: dashboard.startDate,
              endDate: dashboard.endDate,
              filter: dashboard.selectedFilter,
              orders: dashboard.filteredOrders,
              expenses: dashboard.filteredExpenses,
            ),

            const SizedBox(height: 20),

            SummaryTable(
              startDate: dashboard.startDate,
              endDate: dashboard.endDate,
              orders: dashboard.filteredOrders,
              expenses: dashboard.filteredExpenses,
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Data updated: ${DateFormat.yMd().add_Hms().format(DateTime.now())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}