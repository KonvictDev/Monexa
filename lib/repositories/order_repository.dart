// lib/repositories/order_repository.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/order.dart';
import '../providers/subscription_provider.dart';

// ➡️ MODIFICATION 1: Pass Ref to the constructor.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  // Pass the Ref here.
  return OrderRepository(Hive.box<Order>('orders'), ref);
});

class OrderRepository {
  final Box<Order> _orderBox;
  final Ref _ref; // ⬅️ NEW FIELD: Store the Riverpod Ref

  // ➡️ MODIFICATION 2: Accept and store the Ref.
  OrderRepository(this._orderBox, this._ref);

  // 🛠️ FIX: Public getter to expose the Box for the sync/restore logic
  Box<Order> get orderBox => _orderBox;

  /// Adds a new order to the box.
  Future<void> addOrder(Order order) async {
    // ➡️ MODIFICATION 3: Use the stored Ref to read the provider.
    final isPro = _ref.read(isProProvider);

    // ➡️ LIMIT CHECK (Simplified and Corrected)
    if (!isPro) {
      final monthlyOrders = _orderBox.values.where((o) {
        final now = DateTime.now();
        // Check orders from the beginning of the current month
        final startOfMonth = DateTime(now.year, now.month, 1);
        return o.orderDate.isAfter(startOfMonth);
      }).length;

      if (monthlyOrders >= 50) {
        throw Exception('Free plan limit (50 orders per month) reached. Upgrade to Pro.');
      }
    }
    // ⬅️ END LIMIT CHECK

    await _orderBox.add(order);
  }

  // ... (getOrdersInDateRange logic remains fine as it doesn't need Ref) ...
  // No need for a separate monthly calculation method, the logic is in addOrder.

  /// Deletes an order.
  Future<void> deleteOrder(Order order) async {
    await order.delete();
  }

  /// Gets a list of all orders.
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
    // Note: This relies on exact string match, but Hive is fast.
    return _orderBox.values
        .where((order) => order.customerName.toLowerCase() == customerName.toLowerCase())
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate)); // Sort newest first
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