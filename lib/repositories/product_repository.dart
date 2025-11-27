// lib/repositories/product_repository.dart (MODIFIED - Gating and Limit Fix)
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../model/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gating_service.dart';
import '../services/remote_config_service.dart';
import '../utils/constants.dart'; // ➡️ Import Gating Service

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  // ➡️ MODIFICATION 1: Pass Ref to the constructor.
  return ProductRepository(Hive.box<Product>('products'), ref);
});

class ProductRepository {
  final Box<Product> _productBox;
  final Ref _ref;
  final _uuid = const Uuid();

  // ➡️ MODIFICATION 2: Accept and store the Ref.
  ProductRepository(this._productBox, this._ref);

  Box<Product> get productBox => _productBox;

  Future<void> addProduct({
    required String name,
    required double price,
    required int quantity,
    required String description,
    required String category,
    required String imagePath,
    String? thumbnailPath,
  }) async {
    final gatingService = _ref.read(gatingServiceProvider);
    final remoteConfig = _ref.read(remoteConfigServiceProvider);

    // ➡️ LIMIT CHECK (Delegated to GatingService and Fixed)
    if (!gatingService.canUseFeature(Feature.products, _productBox.length)) {
      // ➡️ FIX: Message is now consistent with the intended 20-product limit
      throw Exception('Product limit reached. Free plan limit (${remoteConfig.freeProductLimit} products) reached. Upgrade to Pro for unlimited products.');
    }
    // ⬅️ END LIMIT CHECK

    final newProduct = Product(
      id: _uuid.v4(),
      name: name,
      price: price,
      description: description,
      category: category,
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