// lib/screens/home/home_screen.dart (MODIFIED - Gating Export)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/csv_service.dart';
import '../../services/gating_service.dart'; // ➡️ Import Gating Service
import '../../widgets/filter_bar.dart';
import '../../widgets/metric_grid.dart';
import '../../widgets/sales_chart.dart';
import '../../widgets/summary_table.dart';
import '../../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final dashboard = ref.watch(dashboardProvider);
    final dashboardNotifier = ref.read(dashboardProvider.notifier);
    final theme = Theme.of(context);
    // ➡️ Read Gating Service
    final gatingService = ref.read(gatingServiceProvider);


    Future<void> _selectCustomDateRange(BuildContext context) async {
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
      // ➡️ GATING CHECK
      if (!gatingService.canAccessFeature(Feature.dataExport)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Export requires Monexa Pro.')));
        return;
      }

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
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
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
                    // Note: Date range filter capability is gated in ViewOrdersScreen,
                    // but the dashboard still allows the picker to show for Pro users.
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