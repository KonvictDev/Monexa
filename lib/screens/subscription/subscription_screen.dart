import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../providers/subscription_provider.dart';
import '../../services/in_app_billing_service.dart';
import '../../repositories/auth_repository.dart';
import '../auth/phone_sign_in_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;

  final PageController _pageController = PageController(viewportFraction: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Add Listener for Page Indicator
    _pageController.addListener(() {
      int next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
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

      if (products.isEmpty && await billingService.isStoreAvailable()) {
        setState(() {
          _errorMessage = 'Products not loaded. Check SKUs.';
        });
      }

      setState(() {
        _products = products;
        _isLoading = false;
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
    final billingService = ref.read(inAppBillingServiceProvider);
    billingService.buySubscription(product).catchError((e) {
      setState(() {
        _errorMessage = 'Purchase failed to start: $e';
      });
    });
  }

  void _navigateToSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneSignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);
    final isProcessing = ref.watch(isProcessingPurchaseProvider);
    final authState = ref.watch(authStateProvider);
    final bool isLoggedIn = authState.value != null;
    final bool authLoading = authState.isLoading;

    Widget content;

    if (isProcessing || authLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (!isLoggedIn) {
      content = _buildAuthRequiredCard(context, theme, _navigateToSignIn);
    } else if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(
        child: Text('Error: $_errorMessage',
            style: TextStyle(color: theme.colorScheme.error)),
      );
    } else if (isPro) {
      content = const _ProDetailsWidget();
    } else {
      // Content for non-pro, logged-in user
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTinderScrollPlans(context),
          const SizedBox(height: 10),
          _buildPageIndicator(), // Add page indicator
          const SizedBox(height: 30),
          _buildFeatureComparison(context),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Monexa Pro')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPro ? 'You are a Pro User!' : 'Unlock Your Business Potential',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPro
                    ? Colors.green.shade700
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPro
                  ? 'You’ve unlocked Monexa Pro — enjoy the full experience!'
                  : 'Upgrade to Monexa Pro to get unlimited transactions, cloud backup, and advanced analytics for just ₹99/month.',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Page Indicator Widget
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_products.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  // Modern Diagonal Swipe Cards
// Add this helper function inside the _SubscriptionScreenState class

  /// Calculates the percentage saved by choosing the annual plan over the monthly plan.
  /// Assumes _products contains 'monthly' and 'annual' plans.
  int _calculateAnnualSavingsPercentage() {
    // Find the monthly and annual products
    final monthlyProduct = _products.firstWhere(
          (p) => p.id.contains('monthly'),
      orElse: () => throw Exception("Monthly product not found"),
    );
    final annualProduct = _products.firstWhere(
          (p) => p.id.contains('annual'),
      orElse: () => throw Exception("Annual product not found"),
    );

    // Use NumberFormat to parse the localized price strings to double.
    // This is a robust way to handle currency symbols and separators.
    // NOTE: This assumes the price locale is correctly set up for in-app-purchase prices.
    final formatter = NumberFormat.simpleCurrency(
      locale: monthlyProduct.currencySymbol.contains('₹') ? 'en_IN' : monthlyProduct.currencyCode,
    );

    try {
      // 1. Convert price strings to numeric values.
      final double monthlyPrice = formatter.parse(monthlyProduct.price).toDouble();
      final double annualPrice = formatter.parse(annualProduct.price).toDouble();

      // 2. Calculate the total cost of the monthly plan over a year.
      final double totalMonthlyCost = monthlyPrice * 12;

      // 3. Calculate the savings amount and percentage.
      final double savingsAmount = totalMonthlyCost - annualPrice;

      // Formula for percentage decrease/saving: (Original - New) / Original * 100
      if (totalMonthlyCost <= 0) return 0; // Avoid division by zero
      final double savingsPercentage = (savingsAmount / totalMonthlyCost) * 100;

      // Return the rounded integer percentage
      return savingsPercentage.round();

    } catch (e) {
      // Handle parsing errors (e.g., if price string format is unexpected)
      debugPrint('Error parsing subscription prices: $e');
      return 0; // Return 0% saving on error
    }
  }

// ==========================================================
// 🔹 Modern Diagonal Swipe Cards (Revised with Dynamic Savings)
// ==========================================================
  Widget _buildTinderScrollPlans(BuildContext context) {
    final theme = Theme.of(context);
    final int savingsPercentage = _products.length >= 2 ? _calculateAnnualSavingsPercentage() : 0;

    // Use 0.52 factor for better content fit and premium look
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.48,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final isMonthly = product.id.contains('monthly');

          // --- COLOR & STYLE DEFINITION ---
          final Color annualAccentColor = Colors.purple.shade700;

          final Color cardPrimaryColor = isMonthly
              ? theme.colorScheme.primary
              : annualAccentColor;

          const bool isProcessing = false; // Using hardcoded value for ref.watch placeholder

          final List<String> planFeatures = isMonthly
              ? [
            'Unlimited Transactions',
            'Cloud Backup',
            'Basic Analytics',
          ]
              : [
            'Everything in Monthly',
            'Advanced Analytics',
            'Priority Support',
          ];

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. BEST VALUE TAG (Only on Annual Plan)
              if (!isMonthly)
                Container(
                  decoration: BoxDecoration(
                    color: cardPrimaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const Text(
                    '✨ BEST VALUE & MAX SAVINGS ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              Expanded(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0;
                    if (_pageController.position.haveDimensions) {
                      value = index - (_pageController.page ?? 0);
                    } else {
                      value = index == 0 ? 0 : 1;
                    }

                    const double minScale = 0.85;
                    const double rotateAngle = 0.3;
                    const double maxDiagonalOffset = 40.0;

                    final double scale = minScale + (1.0 - minScale) * (1.0 - value.abs());
                    final double translateX = value * maxDiagonalOffset;
                    final double translateY = value * maxDiagonalOffset * -0.5;
                    final double rotation = value * rotateAngle;
                    final double opacity = 1.0 - value.abs().clamp(0.0, 0.4);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..translate(translateX, translateY)
                        ..rotateZ(rotation)
                        ..scale(scale),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: isMonthly ? const Radius.circular(20) : Radius.zero,
                        topRight: isMonthly ? const Radius.circular(20) : Radius.zero,
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      side: BorderSide(
                        color: cardPrimaryColor,
                        width: isMonthly ? 1.5 : 2.5,
                      ),
                    ),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan Title
                          Text(
                            product.title.split('(').first.trim(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cardPrimaryColor,
                            ),
                          ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.price,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textTheme.titleLarge?.color
                                ),
                              ),
                              Padding( // Added suffix for both plans
                                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                                child: Text(
                                  isMonthly ? '/ month' : '/ year',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // DYNAMIC SAVE tag remains exclusive to Annual
                              if (!isMonthly && savingsPercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'SAVE $savingsPercentage%', // Use calculated value
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 16),
                          // Feature List
                          ...planFeatures.map(
                                (f) => Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: cardPrimaryColor,
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(f,
                                        style: theme.textTheme.bodyLarge),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Subscribe Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _subscribe(product),
                              style: FilledButton.styleFrom(
                                backgroundColor: cardPrimaryColor,
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                isMonthly
                                    ? 'ACTIVATE MONTHLY ACCESS'
                                    : 'GET ANNUAL PRO ACCESS',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Supporting Widgets
  Widget _buildAuthRequiredCard(
      BuildContext context, ThemeData theme, VoidCallback onSignIn) {
    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.lock_person_rounded,
                color: theme.colorScheme.error, size: 36),
            const SizedBox(height: 12),
            Text('Sign In Required',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'You must sign in with your phone number to link the Pro status to your cloud profile.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: const Text('Sign In Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);
    const features = [
      ('Cloud Backup & Sync', true, true),
      ('Transactions/Orders', false, true),
      ('Products/Inventory', false, true),
      ('Advanced Analytics', false, true),
      ('Customer Hub (LTV)', false, true),
      ('Data Export (CSV)', false, true),
      ('Security PIN', true, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feature Comparison',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child:
                Text('Feature', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Free',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Pro',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ),
            ]),
            ...features.map(
                  (f) => TableRow(
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: theme.dividerColor.withOpacity(0.5))),
                ),
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10.0),
                    child:
                    Text(f.$1, style: theme.textTheme.bodyMedium),
                  ),
                  _buildFeatureCell(context, f.$2, f.$1),
                  _buildFeatureCell(context, f.$3, f.$1),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCell(
      BuildContext context, bool enabled, String featureName) {
    final theme = Theme.of(context);
    if (enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Icon(Icons.check_circle_outline,
            color: Colors.green.shade600, size: 20),
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
          child: Icon(Icons.remove_circle_outline,
              color: theme.hintColor, size: 20),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(text,
            style: TextStyle(
                color: theme.hintColor,
                fontWeight: FontWeight.w600)),
      );
    }
  }
}

// Pro Details Widget
class _ProDetailsWidget extends ConsumerWidget {
  const _ProDetailsWidget({super.key});

  List<Widget> _buildProFeatures(BuildContext context, ThemeData theme) {
    const featureGroups = {
      'Cloud & Data Safety': [
        'Unlimited Orders & Products (No Volume Limits)',
        'Full Data History (View orders older than 30 days)',
        'Cloud Sync & Backup (Upload data to Firebase)',
        'Data Restore (Download backup from cloud)',
        'Data Export (CSV/PDF export for all reports)',
      ],
      'Advanced Analytics & Management': [
        'LTV Analytics (Customer Health Metrics)',
        'Advanced Filtering (Date Range, Search)',
        'Customer Hub Management (Add/Edit/Delete)',
        'Product Category Customization',
        'Receipt Customization (Footer/Tax ID toggle)',
      ]
    };

    final List<Widget> widgets = [];
    final TextStyle checkmarkStyle =
    theme.textTheme.titleMedium!.copyWith(color: Colors.green.shade700);

    featureGroups.forEach((title, features) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            )),
      ));
      for (var f in features) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 20, color: Colors.green.shade600),
              const SizedBox(width: 10),
              Expanded(child: Text(f, style: checkmarkStyle)),
            ],
          ),
        ));
      }
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () =>
      const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text('Error loading profile: $e',
            style: TextStyle(color: theme.colorScheme.error)),
      ),
      data: (profile) {
        if (profile == null || !profile.isPro) {
          return const Text('Subscription details not found.');
        }
        final planId = profile.lastSubscriptionId ?? 'Unknown Plan';
        final expiry = profile.proExpiry;
        final planName = planId.contains('monthly')
            ? 'Monexa Pro (Monthly)'
            : planId.contains('annual')
            ? 'Monexa Pro (Annual)'
            : 'Monexa Pro';

        return Card(
          color: Colors.green.shade100,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Colors.green.shade700, size: 36),
                  const SizedBox(width: 16),
                  Text('Subscription Active!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      )),
                ]),
                const Divider(height: 30),
                _buildDetailRow(context, Icons.card_membership,
                    'Current Plan', planName, isPrimary: true),
                const SizedBox(height: 12),
                if (expiry != null)
                  _buildDetailRow(
                    context,
                    Icons.event_available_rounded,
                    'Renews On',
                    DateFormat.yMMMMd().format(expiry),
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(height: 24),
                Text('Your New Monexa Pro Features:',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                ..._buildProFeatures(context, theme),
                const SizedBox(height: 20),
                Text(
                  'Your benefits are now unlocked across all your devices linked to this account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildDetailRow(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      {Color? color, bool isPrimary = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              value,
              style: isPrimary
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ],
    );
  }
}