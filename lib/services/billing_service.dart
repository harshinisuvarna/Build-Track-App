import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

const kProMonthlyId = 'com.buildtrack.pro.monthly';
const kEnterpriseMonthlyId = 'com.buildtrack.enterprise.monthly';
const Set<String> kProductIds = {kProMonthlyId, kEnterpriseMonthlyId};

class BillingService {
  BillingService._();
  static final instance = BillingService._();

  // Changed to a getter to prevent LateInitializationError on Web startup
  InAppPurchase get _iap => InAppPurchase.instance;

  List<ProductDetails> products = [];
  bool isAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> init(
    void Function(List<PurchaseDetails>) onPurchaseUpdate,
  ) async {
    // --- SAFELY BYPASS ON WEB ---
    if (kIsWeb) {
      dev.log(
        'BillingService: Skipping In-App Purchases (Not supported on Web)',
      );
      return;
    }
    // ----------------------------

    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      dev.log('BillingService: Play Store/App Store not available');
      return;
    }
    _subscription = _iap.purchaseStream.listen(
      onPurchaseUpdate,
      onError: (Object e) => dev.log('BillingService stream error: $e'),
    );
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(kProductIds);
      if (response.error != null) {
        dev.log('BillingService product query error: ${response.error}');
      }
      products = response.productDetails;
      dev.log('BillingService: loaded ${products.length} products');
    } catch (e) {
      dev.log('BillingService._loadProducts error: $e');
    }
  }

  ProductDetails? productFor(String productId) {
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> purchase(String productId) async {
    if (kIsWeb) return false; // Safety check

    final product = productFor(productId);
    if (product == null) {
      dev.log('BillingService.purchase: product $productId not found');
      return false;
    }
    final param = PurchaseParam(productDetails: product);
    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      dev.log('BillingService.purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return; // Safety check
    await _iap.restorePurchases();
  }

  Future<void> completePurchase(PurchaseDetails details) async {
    if (kIsWeb) return; // Safety check
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
