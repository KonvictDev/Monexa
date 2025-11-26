import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/order.dart';
import '../model/order_item.dart';
import '../model/product.dart';
// 1. IMPORT THE REPOSITORIES
import '../repositories/product_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/review_service.dart';
import '../utils/date_filter.dart';

// 2. MODIFY THE PROVIDER DEFINITION
// We now pass the `ref` to the CartProvider's constructor.
final cartProvider = ChangeNotifierProvider<CartProvider>((ref) {
  return CartProvider(ref);
});

class CartProvider with ChangeNotifier {
  final _uuid = const Uuid();
  List<OrderItem> _cart = [];
  String _customerName = 'Customer';
  PaymentOption _paymentMethod = PaymentOption.cash;
  double _discountAmount = 0.0;
  late double _taxRate;

  // 3. ADD REPOSITORY FIELDS
  final Ref _ref;
  late final ProductRepository _productRepository;
  late final OrderRepository _orderRepository;
  late final SettingsRepository _settingsRepository;

  // --- Public Getters (No Change) ---
  List<OrderItem> get cart => _cart;
  String get customerName => _customerName;
  PaymentOption get paymentMethod => _paymentMethod;
  double get discountAmount => _discountAmount;
  double get taxRate => _taxRate;

  // --- Calculated Getters (No Change) ---
  double get subtotal => _cart.fold(
    0.0,
        (sum, i) => sum + (i.price * i.quantity),
  );

  double get taxableAmount => (subtotal - _discountAmount).clamp(0.0, subtotal);

  double get taxAmount => taxableAmount * (_taxRate / 100.0);

  double get finalTotal => taxableAmount + taxAmount;

  int get totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);

  // --- 4. MODIFY CONSTRUCTOR ---
  CartProvider(this._ref) {
    // 5. INITIALIZE REPOSITORIES
    // We use ref.read() here because we only need to get them once.
    _productRepository = _ref.read(productRepositoryProvider);
    _orderRepository = _ref.read(orderRepositoryProvider);
    _settingsRepository = _ref.read(settingsRepositoryProvider);

    // Load the tax rate using the new repository
    _loadTaxRate();
  }

  // --- 6. UPDATE _loadTaxRate ---
  void _loadTaxRate() {
    // Load tax rate from settings repository
    _taxRate = _settingsRepository.get('taxRate', defaultValue: 0.0);
  }

  // --- Public Methods (No change to these) ---
  String? addToCart(Product product) {
    final existing = _cart.indexWhere((i) => i.productId == product.id);

    if (existing != -1) {
      if (product.quantity > _cart[existing].quantity) {
        _cart[existing].quantity++;
      } else {
        return 'Cannot add: Out of stock!';
      }
    } else {
      if (product.quantity > 0) {
        _cart.add(OrderItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          category: product.category, // <-- ADD THIS
        ));
      } else {
        return 'Cannot add: Out of stock!';
      }
    }
    notifyListeners();
    return null;
  }

  void updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].quantity = newQuantity;
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void updateDiscount(double amount) {
    _discountAmount = amount.clamp(0.0, subtotal);
    notifyListeners();
  }

  void updatePaymentMethod(PaymentOption method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void updateCustomerName(String name) {
    _customerName = name.isEmpty ? 'Walk-in Customer' : name;
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    _customerName = 'Walk-in Customer';
    _paymentMethod = PaymentOption.cash;
    _discountAmount = 0.0;
    notifyListeners();
  }

  Future<(Order?,String?)> placeOrder() async {
    if (_cart.isEmpty) return(null, null);

    try {
      // 1. GENERATE THE SEQUENTIAL INVOICE NUMBER
      final String invoiceNumber = await _settingsRepository.getNextInvoiceNumber();

      // 2. Update product stock (USING PRODUCT REPOSITORY)
      for (var item in _cart) {
        final product = _productRepository.getProductById(item.productId);

        if (product == null) {
          throw Exception('Product ${item.name} not found in database.');
        }

        product.quantity =
            (product.quantity - item.quantity).clamp(0, product.quantity);

        await _productRepository.updateProduct(product);
      }

      // 3. Create the new Order
      final newOrder = Order(
        id: _uuid.v4(),
        customerName: _customerName,
        items: List.from(_cart),
        subtotal: subtotal,
        discountAmount: _discountAmount,
        taxRate: _taxRate,
        taxAmount: taxAmount,
        totalAmount: finalTotal,
        orderDate: DateTime.now(),
        paymentMethod: _paymentMethod.name,
        invoiceNumber: invoiceNumber, // <-- ADDED
      );

      // 4. Save the new Order
      await _orderRepository.addOrder(newOrder);


      clearCart();
// ➡️ Trigger review flow after a successful order
      _ref.read(reviewServiceProvider).triggerReviewFlow();
      return (newOrder, null);
    } catch (e) {
      debugPrint('Error placing order: $e');
      return (null, e.toString());
    }
  }
}