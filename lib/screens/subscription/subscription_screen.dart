import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../providers/subscription_provider.dart';
import '../../services/in_app_billing_service.dart';

// ⚠️ IMPORTANT: These MUST match the SKUs defined in your Google Play/App Store Consoles.
const Set<String> _productIds = {
  'monexa_pro_monthly',
  'monexa_pro_annual',
};

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final billingService = ref.read(inAppBillingServiceProvider);
      final products = await billingService.fetchProducts();

      // Ensure the required products are fetched
      if (products.isEmpty) {
        setState(() {
          _errorMessage = 'In-App Billing is not available or products are misconfigured.';
        });
      }

      setState(() {
        _products = products;
        _isLoading = false;
        // Sort products for display (e.g., monthly first, then annual)
        _products.sort((a, b) => a.id.compareTo(b.id));
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribe(ProductDetails product) {
    setState(() => _isLoading = true);
    final billingService = ref.read(inAppBillingServiceProvider);
    billingService.buySubscription(product).then((_) {
      // The IAP stream listener handles success/error/completion/state update.
      // We only need to wait for the next screen build or pop.
      // Do NOT set isLoading=false here, as the purchase flow is external.
    }).catchError((e) {
      setState(() {
        _errorMessage = 'Purchase failed to start: $e';
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monexa Pro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              isPro ? 'You are a Pro User!' : 'Unlock Your Business Potential',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPro ? Colors.green.shade700 : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to Monexa Pro to get unlimited transactions, cloud backup, and advanced analytics for just ₹99/month.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),

            // --- Status and Error ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text('Error: $_errorMessage', style: TextStyle(color: theme.colorScheme.error)))
            else if (isPro)
                _buildProStatusCard(context),

            if (_errorMessage == null && !isPro) ...[
              // --- Price Cards ---
              ..._products.map((product) =>
                  _buildProductCard(context, product)
              ).toList(),

              const SizedBox(height: 30),

              // --- Feature Comparison ---
              _buildFeatureComparison(context),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- BUILDER METHODS ---

  Widget _buildProStatusCard(BuildContext context) {
    return Card(
      color: Colors.green.shade100,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Your Monexa Pro subscription is active. Thank you!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductDetails product) {
    final theme = Theme.of(context);
    final isMonthly = product.id.contains('monthly');

    return Card(
      elevation: isMonthly ? 2 : 4,
      color: isMonthly ? theme.cardColor : theme.colorScheme.primaryContainer.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          product.title.split('(').first.trim(), // Clean up title from store
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          product.description,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: FilledButton(
          onPressed: () => _subscribe(product),
          style: FilledButton.styleFrom(
            backgroundColor: isMonthly ? theme.colorScheme.primary : Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.price,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (!isMonthly)
                const Text(
                  'SAVE 16%', // Placeholder for visual promotion
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);

    // Feature List based on your plan
    const features = [
      ('Cloud Backup & Sync', true, true),
      ('Transactions/Orders', false, true), // False = Limited (50/month)
      ('Products/Inventory', false, true), // False = Limited (20)
      ('Advanced Analytics', false, true),
      ('Customer Hub (LTV)', false, true),
      ('Data Export (CSV)', false, true),
      ('Security PIN', true, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feature Comparison', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(),

        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            TableRow(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Pro', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ),
              ],
            ),

            // Feature Rows
            ...features.map((f) => TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(f.$1, style: theme.textTheme.bodyMedium),
                ),
                _buildFeatureCell(context, f.$2, f.$1),
                _buildFeatureCell(context, f.$3, f.$1),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCell(BuildContext context, bool enabled, String featureName) {
    final theme = Theme.of(context);

    if (enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
      );
    } else {
      String text;
      if (featureName.contains('Transactions')) {
        text = '50/mo';
      } else if (featureName.contains('Products')) {
        text = '20 Max';
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Icon(Icons.remove_circle_outline, color: theme.hintColor, size: 20),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(text, style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600)),
      );
    }
  }
}