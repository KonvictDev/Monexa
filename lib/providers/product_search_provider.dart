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
  String? _selectedCategory; // ADDED: Tracks selected category

  List<Product> get filteredProducts => _filteredProducts;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory; // ADDED: Getter

  ProductSearchProvider(this._ref) {
    _productRepo = _ref.read(productRepositoryProvider);

    // 1. ADD LISTENER BACK
    // This makes sure our initial list updates if a product is added/deleted
    _productRepo.getListenable().addListener(_onDataChanged);

    // 2. LOAD INITIAL DATA
    _onDataChanged();
  }

  /// Called on init and when the product box changes.
  void _onDataChanged() {
    // Load the 30 "default" products
    _initialProducts = _productRepo.getRecentProducts(limit: 30);
    // Re-apply the current filter
    _runFilter();
  }

  /// Public method for the UI to call for text search
  void filterProducts(String query) {
    _searchQuery = query.toLowerCase();
    _runFilter();
  }

  /// ADDED: Public method for the UI to call for category filtering
  void setCategoryFilter(String? category) {
    _selectedCategory = (category == 'All Categories' || category == 'All') ? null : category;
    _runFilter();
  }

  /// UPDATE _runFilter LOGIC TO HANDLE BOTH
  void _runFilter() {
    Iterable<Product> baseList;

    if (_searchQuery.isEmpty) {
      if (_selectedCategory != null) {
        // If a category is selected, search ALL products, not just the recent 30
        baseList = _productRepo.getAllProducts().where((p) => p.category == _selectedCategory);
      } else {
        // If search is empty and no category is selected, show the 30 default products
        baseList = _initialProducts;
      }
    } else {
      // If search is not empty, run the efficient query
      baseList = _productRepo.searchProducts(_searchQuery);
      // Apply category filter on top if it exists
      if (_selectedCategory != null) {
        baseList = baseList.where((p) => p.category == _selectedCategory);
      }
    }

    _filteredProducts = baseList.toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _productRepo.getListenable().removeListener(_onDataChanged);
    super.dispose();
  }
}