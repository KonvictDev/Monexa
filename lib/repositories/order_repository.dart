// lib/repositories/order_repository.dart (MODIFIED - Gating and Limit Fix)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/order.dart';
import '../services/gating_service.dart';
import '../services/remote_config_service.dart';
import '../utils/date_filter.dart'; // ➡️ Import Gating Service

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Hive.box<Order>('orders'), ref);
});

class OrderRepository {
  final Box<Order> _orderBox;
  final Ref _ref;

  OrderRepository(this._orderBox, this._ref);

  Box<Order> get orderBox => _orderBox;

  /// Helper to calculate the current month's order count
  int _calculateMonthlyOrderCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _orderBox.values.where((o) {
      return o.orderDate.isAfter(startOfMonth);
    }).length;
  }

  /// Adds a new order to the box.
  Future<void> addOrder(Order order) async {
    final gatingService = _ref.read(gatingServiceProvider);
    final remoteConfig = _ref.read(remoteConfigServiceProvider);

    // ➡️ LIMIT CHECK (Delegated to GatingService and Fixed)
    final monthlyOrders = _calculateMonthlyOrderCount();

    if (!gatingService.canUseFeature(Feature.orders, monthlyOrders)) {
      // ➡️ FIX: Message is now consistent with the logic (30 orders)
      throw Exception('Free plan limit (${remoteConfig.freeOrderLimit} orders per month) reached. Upgrade to Pro.');
    }
    // ⬅️ END LIMIT CHECK

    await _orderBox.add(order);
  }

  Future<void> deleteOrder(Order order) async {
    await order.delete();
  }

  List<Order> getAllOrders() {
    return _orderBox.values.toList();
  }

  Future<void> clearAll() async {
    await _orderBox.clear();
  }

  List<Order> getOrdersInDateRange(DateTime start, DateTime end) {
    return _orderBox.values.where((order) {
      return !order.orderDate.isBefore(start) && !order.orderDate.isAfter(end);
    }).toList();
  }

  List<Order> getOrdersByCustomerName(String customerName) {
    return _orderBox.values
        .where((order) => order.customerName.toLowerCase() == customerName.toLowerCase())
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  /// Searches orders by query (Invoice # or Customer Name) and optionally filters by date.
  List<Order> searchAndFilterOrders({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final lowercaseQuery = query.toLowerCase();

    // Start with all orders, sorted newest first
    List<Order> results = _orderBox.values.toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    // 1. Filter by Search Query
    if (query.isNotEmpty) {
      results = results.where((order) {
        final customerMatch = order.customerName.toLowerCase().contains(lowercaseQuery);
        final invoiceMatch = order.invoiceNumber.toLowerCase().contains(lowercaseQuery);
        return customerMatch || invoiceMatch;
      }).toList();
    }

    // 2. Filter by Start Date
    if (startDate != null) {
      results = results.where((order) {
        return !order.orderDate.isBefore(startDate);
      }).toList();
    }

    // 3. Filter by End Date
    if (endDate != null) {
      // Ensure the end date includes the entire day
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      results = results.where((order) {
        return !order.orderDate.isAfter(endOfDay);
      }).toList();
    }

    return results;
  }

  /// Returns a ValueListenable for the order box.
  ValueListenable<Box<Order>> getListenable() {
    return _orderBox.listenable();
  }
}