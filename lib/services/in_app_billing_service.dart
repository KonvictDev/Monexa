import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// 1. ADDED: Provider to track if verification is currently running
final isProcessingPurchaseProvider = StateProvider<bool>((ref) => false);

final inAppBillingServiceProvider = Provider((ref) => InAppBillingService(ref));

class InAppBillingService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  // Define your product IDs here
  static const Set<String> _productIds = {
    'monexa_pro_monthly',
    'monexa_pro_annual',
  };

  InAppBillingService(this._ref) {
    _initIAPListener();
  }

  Future<bool> isStoreAvailable() async {
    return await _iap.isAvailable();
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('IAP Error: ${response.error!.message}');
      return [];
    }
    return response.productDetails;
  }

  void _initIAPListener() {
    final purchaseStream = _iap.purchaseStream;
    _subscription = purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('IAP Stream Error: $error');
      },
    );
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show progress indicator in UI
      } else {
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase Error: ${purchase.error!.message}');
          // Ensure processing is released on error
          _ref.read(isProcessingPurchaseProvider.notifier).state = false;
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _verifyPurchaseOnServer(purchase);
        }

        // Always complete the purchase on the client side
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  // ⚠️ CRITICAL STEP: Server-Side Validation
  void _verifyPurchaseOnServer(PurchaseDetails purchase) async {
    // 2. SET STATE: Block the UI while verification is active
    _ref.read(isProcessingPurchaseProvider.notifier).state = true;

    try {
      final String token = purchase.verificationData.serverVerificationData;
      final String source = Platform.isIOS ? 'app_store' : 'google_play';

      // ➡️ Call the deployed Firebase Cloud Function
      await FirebaseFunctions.instance.httpsCallable('verifySubscription').call({
        'purchaseToken': token,
        'productId': purchase.productID,
        'source': source,
      });

      // Show success, UI will update via Firestore listener
    } catch (e) {
      // Log error to Crashlytics
      debugPrint('SERVER VALIDATION FAILED: $e');
    } finally {
      // 3. RELEASE STATE: Allow UI to either show 'Pro' or allow re-purchase on failure
      _ref.read(isProcessingPurchaseProvider.notifier).state = false;
    }
  }

  // ➡️ Method to initiate the purchase
  Future<void> buySubscription(ProductDetails product) async {
    // Ensure we aren't already processing another purchase
    if (_ref.read(isProcessingPurchaseProvider)) {
      debugPrint('Purchase already processing. Blocking buy.');
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription?.cancel();
  }
}