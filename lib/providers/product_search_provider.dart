// lib/providers/product_search_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/product.dart';
import '../repositories/product_repository.dart';

final productSearchProvider = ChangeNotifierProvider<ProductSearchProvider>((ref) {
  return ProductSearchProvider(ref);
});

class ProductSearchProvider with ChangeNotifier {
  final Ref _ref;
  late final ProductRepository _productRepo;

  List<Product> _initialProducts = []; // Holds the 30 default products
  List<Product> _filteredProducts = [];
  String _searchQuery = '';

  List<Product> get filteredProducts => _filteredProducts;
  String get searchQuery => _searchQuery;

  ProductSearchProvider(this._ref) {
    _productRepo = _ref.read(productRepositoryProvider);

    // 1. ADD LISTENER BACK
    // This makes sure our initial list updates if a product is added/deleted
    _productRepo.getListenable().addListener(_onDataChanged);

    // 2. LOAD INITIAL DATA
    _onDataChanged();
  }

  /// 3. CREATE _onDataChanged
  /// Called on init and when the product box changes.
  void _onDataChanged() {
    // Load the 30 "default" products
    _initialProducts = _productRepo.getRecentProducts(limit: 30);
    // Re-apply the current filter
    _runFilter();
  }

  /// Public method for the UI to call
  void filterProducts(String query) {
    _searchQuery = query.toLowerCase();
    _runFilter();
  }

  /// 4. UPDATE _runFilter LOGIC
  void _runFilter() {
    if (_searchQuery.isEmpty) {
      // If search is empty, show the 30 default products
      _filteredProducts = _initialProducts;
    } else {
      // If search is not empty, run the efficient query
      _filteredProducts = _productRepo.searchProducts(_searchQuery);
    }
    notifyListeners();
  }

  /// 5. ADD dispose() BACK
  @override
  void dispose() {
    _productRepo.getListenable().removeListener(_onDataChanged);
    super.dispose();
  }
}