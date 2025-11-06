// lib/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/order.dart';
import '../model/expense.dart';
import '../repositories/order_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/settings_repository.dart'; // <-- ADD THIS
import '../utils/date_filter.dart';

final dashboardProvider = ChangeNotifierProvider<DashboardProvider>((ref) {
  return DashboardProvider(ref);
});

// --- CORRECTED HELPER FOR ASYNC CALCULATION ---
// ... (this helper is unchanged) ...
double _calculateTotalProfitFromAmounts(List<dynamic> amountsData) {
  final List<double> orderAmounts = amountsData[0] as List<double>;
  final List<double> expenseAmounts = amountsData[1] as List<double>;

  final totalRevenue = orderAmounts.fold<double>(0.0, (sum, amount) => sum + amount);
  final totalExpenses = expenseAmounts.fold<double>(0.0, (sum, amount) => sum + amount);

  return totalRevenue - totalExpenses;
}
// --- END HELPER CORRECTION ---

class DashboardProvider with ChangeNotifier {
  final Ref _ref;
  late final OrderRepository _orderRepo;
  late final ExpenseRepository _expenseRepo;
  late final SettingsRepository _settingsRepo; // <-- ADD THIS

  DateFilter _selectedFilter = DateFilter.today;
  DateTime _startDate;
  DateTime _endDate;
  bool _isLoading = false;
  bool _isTotalProfitLoading = true;

  // --- NEW CATEGORY STATE ---
  List<String> _allCategories = [];
  String? _selectedCategory;
  // --- END NEW CATEGORY STATE ---

  List<Order> filteredOrders = [];
  List<Expense> filteredExpenses = [];
  double filteredRevenue = 0.0;
  double filteredExpensesTotal = 0.0;
  double filteredProfit = 0.0;
  int filteredOrderCount = 0;
  double filteredAvgOrderValue = 0.0;
  double totalProfit = 0.0;

  DateFilter get selectedFilter => _selectedFilter;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  bool get isTotalProfitLoading => _isTotalProfitLoading;

  // --- NEW GETTERS ---
  List<String> get allCategories => _allCategories;
  String? get selectedCategory => _selectedCategory;
  // --- END NEW GETTERS ---


  DashboardProvider(this._ref)
      : _startDate = DateTime.now(),
        _endDate = DateTime.now() {
    _orderRepo = _ref.read(orderRepositoryProvider);
    _expenseRepo = _ref.read(expenseRepositoryProvider);
    _settingsRepo = _ref.read(settingsRepositoryProvider); // <-- ADD THIS

    _updateDateRange(_selectedFilter, notify: false);

    _orderRepo.getListenable().addListener(_onDataChanged);
    _expenseRepo.getListenable().addListener(_onDataChanged);
    // Listen for category changes
    _settingsRepo.getListenable(keys: ['productCategories']).addListener(_loadCategories); // <-- ADD THIS

    _loadCategories(); // <-- ADD THIS
    _onDataChanged();
  }

  // --- NEW METHOD ---
  void _loadCategories() {
    _allCategories = _settingsRepo.getProductCategories();
    notifyListeners();
  }
  // --- END NEW METHOD ---

  void _onDataChanged() async {
    await _calculateTotalProfitAsync();
    _recalculateFilteredMetrics();
  }

  Future<void> _calculateTotalProfitAsync() async {
    // ... (this method is unchanged) ...
    if (!_isTotalProfitLoading) {
      _isTotalProfitLoading = true;
      notifyListeners();
    }
    final allOrders = _orderRepo.getAllOrders();
    final allExpenses = _expenseRepo.getAllExpenses();
    final List<double> orderAmounts = allOrders.map((o) => o.totalAmount).toList();
    final List<double> expenseAmounts = allExpenses.map((e) => e.amount).toList();
    totalProfit = await compute(_calculateTotalProfitFromAmounts, [orderAmounts, expenseAmounts]);
    _isTotalProfitLoading = false;
    notifyListeners();
  }

  // --- MODIFIED METHOD ---
  void _recalculateFilteredMetrics() {
    filteredOrders = _orderRepo.getOrdersInDateRange(_startDate, _endDate);
    filteredExpenses = _expenseRepo.getExpensesInDateRange(_startDate, _endDate);

    // --- REVENUE CALCULATION LOGIC ---
    if (_selectedCategory == null) {
      // Original logic: Sum total amount of all orders
      filteredRevenue = filteredOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    } else {
      // New logic: Sum only items matching the category
      double revenue = 0.0;
      for (final order in filteredOrders) {
        for (final item in order.items) {
          if (item.category == _selectedCategory) {
            revenue += (item.price * item.quantity);
          }
        }
      }
      filteredRevenue = revenue;
    }
    // --- END REVENUE LOGIC ---

    filteredExpensesTotal = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    filteredProfit = filteredRevenue - filteredExpensesTotal;

    // Order count is now "Orders containing this category" if filtered
    if (_selectedCategory == null) {
      filteredOrderCount = filteredOrders.length;
    } else {
      filteredOrderCount = filteredOrders
          .where((o) => o.items.any((i) => i.category == _selectedCategory))
          .length;
    }

    filteredAvgOrderValue =
    filteredOrderCount == 0 ? 0.0 : filteredRevenue / filteredOrderCount;

    notifyListeners();
  }
  // --- END MODIFIED METHOD ---


  Future<void> refreshData() async {
    // ... (this method is unchanged) ...
    setLoading(true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _calculateTotalProfitAsync();
    _recalculateFilteredMetrics();
    setLoading(false);
  }

  void setLoading(bool loading) {
    // ... (this method is unchanged) ...
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // --- NEW METHOD ---
  void setCategoryFilter(String? category) {
    // If category is "All Categories", set to null
    _selectedCategory = (category == 'All Categories') ? null : category;
    _recalculateFilteredMetrics();
  }
  // --- END NEW METHOD ---

  Future<void> selectCustomDateRange(DateTimeRange? picked) async {
    // ... (this method is unchanged) ...
    if (picked != null) {
      _selectedFilter = DateFilter.custom;
      _startDate = picked.start;
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      _recalculateFilteredMetrics();
    }
  }

  void updateDateFilter(DateFilter newFilter) {
    // ... (this method is unchanged) ...
    if (newFilter == DateFilter.custom) {
      return;
    }
    _updateDateRange(newFilter);
  }

  void _updateDateRange(DateFilter newFilter, {bool notify = true}) {
    // ... (this method is unchanged) ...
    DateTime now = DateTime.now();
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime newStart = now;
    DateTime newEnd = endOfToday;

    switch (newFilter) {
      case DateFilter.today:
        newStart = DateTime(now.year, now.month, now.day);
        newEnd = endOfToday;
        break;
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        newStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
        newEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case DateFilter.last7Days:
        final startDate = now.subtract(const Duration(days: 6));
        newStart = DateTime(startDate.year, startDate.month, startDate.day);
        newEnd = endOfToday;
        break;
      case DateFilter.last30Days:
        final startDate = now.subtract(const Duration(days: 29));
        newStart = DateTime(startDate.year, startDate.month, startDate.day);
        newEnd = endOfToday;
        break;
      case DateFilter.custom:
        return;
    }

    if (_selectedFilter != newFilter || _startDate != newStart || _endDate != newEnd) {
      _selectedFilter = newFilter;
      _startDate = newStart;
      _endDate = newEnd;

      if (notify) {
        _recalculateFilteredMetrics();
      }
    }
  }

  @override
  void dispose() {
    _orderRepo.getListenable().removeListener(_onDataChanged);
    _expenseRepo.getListenable().removeListener(_onDataChanged);
    _settingsRepo.getListenable(keys: ['productCategories']).removeListener(_loadCategories); // <-- ADD THIS
    super.dispose();
  }
}