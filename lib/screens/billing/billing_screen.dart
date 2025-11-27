// BillingScreen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Removed showcaseview import

import '../../main_navigation_screen.dart';
import '../../model/product.dart';
import '../../model/order_item.dart';

import '../../providers/cart_provider.dart';
import '../../providers/product_search_provider.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/constants.dart';
import '../../widgets/upgrade_snackbar.dart';

import '../../widgets/customer_selection_modal.dart';
import 'order_success_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  // Removed _keys initialization
  // late final ShowcaseKeys _keys;

  @override
  void initState() {
    super.initState();
    // _keys = ref.read(showcaseKeysProvider); // Removed
    _searchController.addListener(() {
      ref.read(productSearchProvider.notifier).filterProducts(_searchController.text);
    });
    // Removed showcase check in addPostFrameCallback
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Removed _checkAndStartShowcase method

  void _addToCart(Product product) {
    HapticFeedback.lightImpact();
    final error = ref.read(cartProvider.notifier).addToCart(product);
    if (error != null) {
      _showSnackbar(error);
    }
    // Removed showcase flow completion logic
  }

  void _clearCart() {
    HapticFeedback.mediumImpact();
    ref.read(cartProvider.notifier).clearCart();
    _showSnackbar('Cart cleared.');
  }

  void _showSnackbar(String message) {
    if (mounted) {
      if (message.contains('limit') || message.contains('Upgrade')) {
        showUpgradeSnackbar(context, message);
        return;
      }

      final isError = message.contains('Error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCustomerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CustomerSelectionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productSearch = ref.watch(productSearchProvider);

    // 1. Wrap the entire Scaffold in a GestureDetector to detect taps on the background
    return GestureDetector(
      onTap: () {
        // This hides the keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Order'),
          actions: [
            TextButton.icon(
              onPressed: _showCustomerModal,
              icon: const Icon(Icons.person_outline),
              label: Text(
                cart.customerName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                maximumSize: const Size(180, 100),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(productSearchProvider.notifier)
                          .filterProducts('');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            final filteredProducts = productSearch.filteredProducts;
            final String searchQuery = productSearch.searchQuery;

            if (filteredProducts.isEmpty && searchQuery.isEmpty) {
              return const Center(
                child: Text('No products in inventory.'),
              );
            }

            if (filteredProducts.isEmpty && searchQuery.isNotEmpty) {
              return const Center(
                child: Text('No products found for your search.'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0), // Increased padding
              itemCount: filteredProducts.length,
              // 2. Optimization: Dismiss keyboard immediately when user drags the list
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // 🔥 CHANGE: Fixed 2 columns, taller aspect ratio for rectangular look
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1, // Lower number = Taller rectangle
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _ProductTile(
                  product: product,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _addToCart(product);
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: _CartFooter(
          cart: cart.cart,
          total: cart.finalTotal,
          onCheckout: () => _showCartDialog(context),
          onViewCart: () => _showCartDialog(context),
        ),
      ),
    );
  }

  void _showCartDialog(BuildContext context, {bool startShowcase = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final cart = ref.watch(cartProvider);
            final cartNotifier = ref.read(cartProvider.notifier);
            final settingsRepo = ref.read(settingsRepositoryProvider);

            // Removed Showcase 5 check and start logic

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Cart',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Clear Cart'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: cart.cart.isEmpty
                            ? null
                            : () {
                          HapticFeedback.mediumImpact();
                          cartNotifier.clearCart();
                          _showSnackbar('Cart cleared.');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),

                  if (cart.cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 64,
                              color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Your cart is empty',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: cart.cart.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = cart.cart[index];
                            final productBox = Hive.box<Product>('products');
                            Product? product;
                            try {
                              product = productBox.values
                                  .firstWhere((p) => p.id == item.productId);
                            } catch (_) {
                              return const SizedBox.shrink();
                            }

                            final bool canIncrease =
                                product.quantity > item.quantity;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              title: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                '₹${item.price.toStringAsFixed(2)} each',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [ IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      cartNotifier.updateItemQuantity(index, item.quantity - 1);
                                    } else {
                                      cartNotifier.removeFromCart(index);
                                      _showSnackbar('${item.name} removed from cart.');
                                    }
                                  },
                                ),
                                  Text(
                                    '${item.quantity}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: canIncrease
                                        ? () => cartNotifier.updateItemQuantity(
                                        index, item.quantity + 1)
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ─── Payment Chips ───────────────
                  SegmentedButton<PaymentOption>(
                    segments: const <ButtonSegment<PaymentOption>>[
                      ButtonSegment<PaymentOption>(
                        value: PaymentOption.cash,
                        label: Text('Cash'),
                        icon: Icon(Icons.money),
                      ),
                      ButtonSegment<PaymentOption>(
                        value: PaymentOption.online,
                        label: Text('Online / Card'),
                        icon: Icon(Icons.credit_card),
                      ),
                    ],
                    selected: {cart.paymentMethod},
                    onSelectionChanged: (Set<PaymentOption> newSelection) {
                      cartNotifier.updatePaymentMethod(newSelection.first);
                    },
                  ),

                  Divider(color: Theme.of(context).colorScheme.outlineVariant),

                  // ... (Summary Section remains the same)
                  _summaryTile(
                      'Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
                  _summaryTile(
                    'Discount',
                    '- ₹${cart.discountAmount.toStringAsFixed(2)}',
                    leading: TextButton(
                      child: Text(cart.discountAmount > 0 ? 'EDIT' : 'ADD'),
                      onPressed: () =>
                          _showDiscountDialog(context, cartNotifier),
                    ),
                  ),
                  _summaryTile('Taxable Amount',
                      '₹${cart.taxableAmount.toStringAsFixed(2)}'),
                  _summaryTile('Tax (${cart.taxRate.toStringAsFixed(1)}%)',
                      '+ ₹${cart.taxAmount.toStringAsFixed(2)}'),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Grand Total',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    trailing: Text(
                      '₹${cart.finalTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),


                  // ─── Checkout Button ───────────────────────────
                  // Removed Showcase wrapper
                  FilledButton.icon(
                    icon: const Icon(Icons.payment_rounded),
                    label: Text(
                        'Checkout (${cart.paymentMethod.name.toUpperCase()})'),
                    onPressed: cart.finalTotal >= 0 && cart.subtotal > 0
                        ? () async {
                      Navigator.pop(context);

                      final result = await cartNotifier.placeOrder();
                      final newOrder = result.$1;
                      final errorMessage = result.$2;


                      if (newOrder != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderSuccessScreen(order: newOrder),
                          ),
                        );
                      } else if (context.mounted) {
                        _showSnackbar(
                            errorMessage ?? 'Error placing order. Please try again.');
                      }
                    }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryTile(String title, String trailing, {Widget? leading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leading != null) leading,
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Text(trailing, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }


  Future<void> _showDiscountDialog(
      BuildContext context, CartProvider cartNotifier) {
    final discountController = TextEditingController(
      text: cartNotifier.discountAmount > 0
          ? cartNotifier.discountAmount.toString()
          : '',
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Discount'),
          content: TextField(
            controller: discountController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newDiscount =
                    double.tryParse(discountController.text) ?? 0.0;
                cartNotifier.updateDiscount(newDiscount);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

// --- Supporting Widgets ---

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool outOfStock = product.quantity <= 0;

    // --- Existing Image Logic (Preserved) ---
    String? imagePathToShow = product.thumbnailPath;
    File? imageFile;

    if (imagePathToShow != null && imagePathToShow.isNotEmpty) {
      final file = File(imagePathToShow);
      if (file.existsSync()) {
        imageFile = file;
      } else {
        imagePathToShow = null;
      }
    }

    if (imageFile == null && product.imagePath.isNotEmpty) {
      final file = File(product.imagePath);
      if (file.existsSync()) {
        imageFile = file;
        imagePathToShow = product.imagePath;
      } else {
        imagePathToShow = null;
      }
    }
    // ----------------------------------------

    return InkWell(
      onTap: outOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          // Subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. IMAGE SECTION (Takes up more space)
            Expanded(
              flex: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: imageFile != null
                        ? Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image,
                            size: 40, color: colorScheme.outline);
                      },
                    )
                        : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.bakery_dining_rounded,
                          size: 40, color: colorScheme.primary),
                    ),
                  ),
                  // Out of stock overlay
                  if (outOfStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "SOLD OUT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. DETAILS SECTION
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    // Price and Stock Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outOfStock ? 'No Stock' : '${product.quantity} left',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: outOfStock ? colorScheme.error : colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        // Add Button Visual
                        if (!outOfStock)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final List<OrderItem> cart;
  final double total;
  final VoidCallback onCheckout;
  final VoidCallback onViewCart;
  // Removed keys
  // final GlobalKey checkoutKey;
  // final VoidCallback onShowcaseComplete;

  const _CartFooter({
    required this.cart,
    required this.total,
    required this.onCheckout,
    required this.onViewCart,
    // Removed keys
  });

  int get totalItems => cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: cart.isEmpty ? null : onViewCart,
              icon: Badge(
                label: Text(totalItems.toString()),
                isLabelVisible: totalItems > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: Text(cart.isEmpty ? 'Cart Empty' : 'View Cart'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            // Removed Showcase wrapper
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : onCheckout,
              icon: const Text('Checkout', style: TextStyle(fontSize: 18)),
              label: Text(
                '₹${total.toStringAsFixed(2)}',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}