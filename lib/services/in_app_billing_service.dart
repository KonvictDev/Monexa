import 'dart:async';
import 'dart:io';
import 'package:billing/services/remote_config_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/user_profile_providers.dart';

// Provider to track if verification is currently running
final isProcessingPurchaseProvider = StateProvider<bool>((ref) => false);

final inAppBillingServiceProvider = Provider((ref) => InAppBillingService(ref));

class InAppBillingService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  late final RemoteConfigService _remoteConfigService;

  InAppBillingService(this._ref) {
    _initIAPListener();
    _remoteConfigService = _ref.read(remoteConfigServiceProvider);
  }

  Future<bool> isStoreAvailable() async {
    return await _iap.isAvailable();
  }

  Future<Set<String>> _fetchProductIdsFromRemoteConfig() async {
    final String idsString = _remoteConfigService.subscriptionProductList;
    if (idsString.isEmpty) return {};
    return idsString.split(',').map((id) => id.trim()).toSet();
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return [];

    final Set<String> dynamicProductIds;
    try {
      dynamicProductIds = await _fetchProductIdsFromRemoteConfig();
    } catch (e) {
      debugPrint('Error fetching product IDs from Remote Config: $e');
      return [];
    }

    if (dynamicProductIds.isEmpty) {
      debugPrint('No product IDs found in Remote Config. Check configuration.');
      return [];
    }

    final response = await _iap.queryProductDetails(dynamicProductIds);
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

    Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _ref.read(isProcessingPurchaseProvider.notifier).state = true;
      } else {
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase Error: ${purchase.error!.message}');
          _ref.read(isProcessingPurchaseProvider.notifier).state = false;
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {

          // 🔥 CRITICAL FIX: Verify FIRST, then Complete.
          final bool isValid = await _verifyPurchaseOnServer(purchase);

          if (isValid) {
            _ref.invalidate(userProfileStreamProvider);
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
              debugPrint("Purchase completed and acknowledged.");
            }
          } else {
            debugPrint("Server verification failed. NOT completing purchase.");
            // Do NOT complete purchase. This allows the user to try "Restore" again
            // without being charged double, or triggers a refund eventually.
          }
        }
      }
    }
  }

  // 🔥 UPDATED: Returns Future<bool> to indicate success/failure
  Future<bool> _verifyPurchaseOnServer(PurchaseDetails purchase) async {
    _ref.read(isProcessingPurchaseProvider.notifier).state = true;

    try {
      final String token = purchase.verificationData.serverVerificationData;
      final String source = Platform.isIOS ? 'app_store' : 'google_play';

      debugPrint("Verifying purchase for: ${purchase.productID}");

      // Call the deployed Firebase Cloud Function
      await FirebaseFunctions.instance
          .httpsCallable('verifySubscription')
          .call({
        'purchaseToken': token,
        'productId': purchase.productID,
        'source': source,
      });

      debugPrint("Server verification SUCCESS.");
      return true;
    } catch (e) {
      debugPrint('SERVER VALIDATION FAILED: $e');
      // Optional: Show a snackbar to the user via a global key or provider state
      return false;
    } finally {
      _ref.read(isProcessingPurchaseProvider.notifier).state = false;
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    if (_ref.read(isProcessingPurchaseProvider)) {
      debugPrint('Purchase already processing. Blocking buy.');
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    // For Android, this usually opens the Google Pay sheet
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription?.cancel();
  }
}