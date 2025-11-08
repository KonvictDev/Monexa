// lib/repositories/customer_repository.dart (MODIFIED - Added 'tag' parameter to addCustomer)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../model/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(Hive.box<Customer>('customers'));
});

class CustomerRepository {
  final Box<Customer> _customerBox;
  final _uuid = const Uuid();

  CustomerRepository(this._customerBox);

  Box<Customer> get customerBox => _customerBox;

  /// Adds a new customer
  Future<void> addCustomer({
    required String name,
    String phoneNumber = '',
    String email = '',
    String address = '',
    String tag = '', // ➡️ ADDED: Tag parameter
  }) async {
    final newCustomer = Customer(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      address: address,
      tag: tag, // ➡️ ASSIGNED: New tag field
    );
    await _customerBox.put(newCustomer.id, newCustomer);
  }

  /// Updates an existing customer
  Future<void> updateCustomer(Customer customer) async {
    await customer.save();
  }

  /// Deletes a customer
  Future<void> deleteCustomer(Customer customer) async {
    await customer.delete();
  }

  /// Gets a customer by their ID
  Customer? getCustomerById(String id) {
    return _customerBox.get(id);
  }

  /// Gets a list of all customers
  List<Customer> getAllCustomers() {
    return _customerBox.values.toList();
  }

  /// Searches for customers by name or phone number
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) {
      return getAllCustomers(); // Return all if search is empty
    }
    final lowercaseQuery = query.toLowerCase();
    return _customerBox.values.where((customer) {
      return customer.name.toLowerCase().contains(lowercaseQuery) ||
          customer.phoneNumber.contains(query);
    }).toList();
  }

  /// Returns a ValueListenable for the UI to listen to
  ValueListenable<Box<Customer>> getListenable() {
    return _customerBox.listenable();
  }

  /// Gets the first [limit] customers from the box.
  List<Customer> getRecentCustomers({int limit = 30}) {
    final allCustomers = _customerBox.values.toList();
    return allCustomers.reversed.take(limit).toList();
  }

  /// Clears all customers
  Future<void> clearAll() async {
    await _customerBox.clear();
  }
}