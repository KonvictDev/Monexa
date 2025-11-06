// lib/services/csv_service.dart

import 'dart:io';
import 'package:billing/model/customer.dart';
import 'package:billing/model/expense.dart';
import 'package:billing/model/order.dart';
import 'package:billing/model/product.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvService {

  // --- EXISTING METHOD (FOR DASHBOARD DATE RANGE EXPORT) ---
  Future<String> exportData({
    required DateTime startDate,
    required DateTime endDate,
    required List<Order> orders,
    required List<Expense> expenses,
  }) async {
    try {
      final String orderCsv = _generateOrderCsv(orders);
      final String expenseCsv = _generateExpenseCsv(expenses);

      final tempDir = await getTemporaryDirectory();
      final String dateTag =
      '${DateFormat.yMd().format(startDate)}_${DateFormat.yMd().format(endDate)}'.replaceAll('/', '-');

      final String orderPath = '${tempDir.path}/orders_export_$dateTag.csv';
      final String expensePath = '${tempDir.path}/expenses_export_$dateTag.csv';

      final File orderFile = await File(orderPath).writeAsString(orderCsv);
      final File expenseFile = await File(expensePath).writeAsString(expenseCsv);

      await Share.shareXFiles(
        [XFile(orderFile.path), XFile(expenseFile.path)],
        text: 'Data Export for $dateTag',
      );

      return 'Data exported successfully!';
    } catch (e) {
      return 'Error exporting data: $e';
    }
  }

  // --- NEW METHOD (FOR FULL APP DATA EXPORT from Settings) ---
  Future<String> exportAllData({
    required List<Product> products,
    required List<Order> orders,
    required List<Expense> expenses,
    required List<Customer> customers, // Include customers
  }) async {
    try {
      final String productCsv = _generateProductCsv(products);
      final String orderCsv = _generateOrderCsv(orders);
      final String expenseCsv = _generateExpenseCsv(expenses);
      final String customerCsv = _generateCustomerCsv(customers);

      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final List<XFile> filesToShare = [];

      // Write and collect all files (CORRECTED to pass file path string)
      if (products.isNotEmpty) {
        final filePath = '${tempDir.path}/products_all_$timestamp.csv';
        await File(filePath).writeAsString(productCsv);
        filesToShare.add(XFile(filePath));
      }

      if (orders.isNotEmpty) {
        final filePath = '${tempDir.path}/orders_all_$timestamp.csv';
        await File(filePath).writeAsString(orderCsv);
        filesToShare.add(XFile(filePath));
      }

      if (expenses.isNotEmpty) {
        final filePath = '${tempDir.path}/expenses_all_$timestamp.csv';
        await File(filePath).writeAsString(expenseCsv);
        filesToShare.add(XFile(filePath));
      }

      if (customers.isNotEmpty) {
        final filePath = '${tempDir.path}/customers_all_$timestamp.csv';
        await File(filePath).writeAsString(customerCsv);
        filesToShare.add(XFile(filePath));
      }

      if (filesToShare.isEmpty) {
        return 'No data found to export.';
      }

      await Share.shareXFiles(
        filesToShare,
        text: 'Full Data Export from App ($timestamp)',
      );

      return 'All data exported successfully!';
    } catch (e) {
      // In a real app, you would log this error to Sentry/Crashlytics
      return 'Error exporting data: $e';
    }
  }

  // --- PRIVATE: Generates the Order CSV String ---
  String _generateOrderCsv(List<Order> orders) {
    List<List<dynamic>> rows = [];
    rows.add([
      "Invoice No",
      "Order ID",
      "Date",
      "Time",
      "Customer",
      "Items",
      "Subtotal",
      "Discount",
      "Taxable Amount",
      "Tax Rate (%)",
      "Tax Amount",
      "Grand Total",
      "Payment Method"
    ]);

    final dateFormat = DateFormat.yMd();
    final timeFormat = DateFormat.jms();

    for (var order in orders) {
      final itemSummary = order.items
          .map((item) => '${item.name} (x${item.quantity})')
          .join(', ');

      final taxableAmount = order.subtotal - order.discountAmount;

      rows.add([
        order.invoiceNumber,
        order.id,
        dateFormat.format(order.orderDate),
        timeFormat.format(order.orderDate),
        order.customerName,
        itemSummary,
        order.subtotal,
        order.discountAmount,
        taxableAmount,
        order.taxRate,
        order.taxAmount,
        order.totalAmount,
        order.paymentMethod
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // --- PRIVATE: Generates the Expense CSV String ---
  String _generateExpenseCsv(List<Expense> expenses) {
    List<List<dynamic>> rows = [];
    rows.add(["Date", "Time", "Description", "Amount"]);
    final dateFormat = DateFormat.yMd();
    final timeFormat = DateFormat.jms();

    for (var expense in expenses) {
      rows.add([
        dateFormat.format(expense.date),
        timeFormat.format(expense.date),
        expense.description,
        expense.amount
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // --- PRIVATE: Product CSV Generator ---
  String _generateProductCsv(List<Product> products) {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Name", "Price", "Stock Quantity", "Description", "Image Path", "Thumbnail Path"]);

    for (var product in products) {
      rows.add([
        product.id,
        product.name,
        product.price,
        product.quantity,
        product.description,
        product.imagePath,
        product.thumbnailPath ?? '',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // --- PRIVATE: Customer CSV Generator ---
  String _generateCustomerCsv(List<Customer> customers) {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Name", "Phone Number", "Email", "Address"]);

    for (var customer in customers) {
      rows.add([
        customer.id,
        customer.name,
        customer.phoneNumber,
        customer.email,
        customer.address,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }
}