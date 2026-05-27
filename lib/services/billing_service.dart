import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

// ── Product IDs ────────────────────────────────────────────────────────────
const kStarterMonthlyId    = 'com.buildtrack.starter.monthly';
const kGrowthMonthlyId     = 'com.buildtrack.growth.monthly';
const kProMonthlyId        = 'com.buildtrack.pro.monthly';
const kBusinessMonthlyId   = 'com.buildtrack.business.monthly';
const kEnterpriseMonthlyId = 'com.buildtrack.enterprise.monthly';

const Set<String> kProductIds = {
  kStarterMonthlyId,
  kGrowthMonthlyId,
  kProMonthlyId,
  kBusinessMonthlyId,
  kEnterpriseMonthlyId,
};

class BillingService {
  BillingService._();
  static final instance = BillingService._();

  InAppPurchase get _iap => InAppPurchase.instance;

  List<ProductDetails> products = [];
  bool isAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> init(
    void Function(List<PurchaseDetails>) onPurchaseUpdate,
  ) async {
    if (kIsWeb) {
      dev.log('BillingService: Skipping IAP (not supported on Web)');
      return;
    }

    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      dev.log('BillingService: Store not available');
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
    if (kIsWeb) return false;
    final product = productFor(productId);
    if (product == null) {
      dev.log('BillingService.purchase: product $productId not found');
      return false;
    }
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      dev.log('BillingService.purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    await _iap.restorePurchases();
  }

  Future<void> completePurchase(PurchaseDetails details) async {
    if (kIsWeb) return;
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}