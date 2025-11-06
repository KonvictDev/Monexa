// lib/repositories/product_repository.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../model/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  // ➡️ MODIFICATION 1: Pass Ref to the constructor.
  return ProductRepository(Hive.box<Product>('products'), ref);
});

class ProductRepository {
  final Box<Product> _productBox;
  final Ref _ref; // ⬅️ NEW FIELD: Store the Riverpod Ref
  final _uuid = const Uuid();

  // ➡️ MODIFICATION 2: Accept and store the Ref.
  ProductRepository(this._productBox, this._ref);

  // 🛠️ FIX: Public getter to expose the Box for the sync/restore logic
  Box<Product> get productBox => _productBox;

  Future<void> addProduct({
    required String name,
    required double price,
    required int quantity,
    required String description,
    required String category, // <-- ADD THIS
    required String imagePath,
    String? thumbnailPath,
  }) async {
    // ➡️ MODIFICATION 3: Use the stored Ref to read the provider.
    final isPro = _ref.read(isProProvider);

    // ➡️ LIMIT CHECK (Corrected)
    if (!isPro) {
      if (_productBox.length >= 20) {
        throw Exception('Free plan limit (20 products) reached. Upgrade to Pro.');
      }
    }
    // ⬅️ END LIMIT CHECK

    final newProduct = Product(
      id: _uuid.v4(),
      name: name,
      price: price,
      description: description,
      category: category, // <-- ADD THIS
      imagePath: imagePath,
      quantity: quantity,
      thumbnailPath:thumbnailPath,
    );

    await _productBox.put(newProduct.id, newProduct);
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
  }

  Future<void> deleteProduct(Product product) async {
    await product.delete();
  }

  Product? getProductById(String id) {
    return _productBox.get(id);
  }

  List<Product> getAllProducts() {
    return _productBox.values.toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) {
      return [];
    }
    final lowercaseQuery = query.toLowerCase();

    return _productBox.values
        .where((product) => product.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  List<Product> getRecentProducts({int limit = 30}) {
    return _productBox.values.take(limit).toList();
  }

  ValueListenable<Box<Product>> getListenable() {
    return _productBox.listenable();
  }

  Future<void> clearAll() async {
    await _productBox.clear();
  }
}