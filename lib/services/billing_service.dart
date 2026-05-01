import 'dart:async';
import 'dart:developer' as dev;

import 'package:in_app_purchase/in_app_purchase.dart';

// ── Product IDs ────────────────────────────────────────────────────────────────
// Replace these with the exact SKUs configured in your Google Play Console
// (Subscriptions → Create subscription → Product ID).
const kProMonthlyId     = 'com.buildtrack.pro.monthly';
const kEnterpriseMonthlyId = 'com.buildtrack.enterprise.monthly';

const Set<String> kProductIds = {kProMonthlyId, kEnterpriseMonthlyId};

class BillingService {
  BillingService._();
  static final instance = BillingService._();

  final _iap = InAppPurchase.instance;

  // ── Public state ──────────────────────────────────────────────────────────

  /// Resolved product catalogue from the Play Store.
  List<ProductDetails> products = [];

  /// Whether the billing client is connected and available.
  bool isAvailable = false;

  // Internal stream subscription – kept alive for the app lifecycle.
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Call once from [SubscriptionProvider] constructor.
  /// [onPurchaseUpdate] is invoked every time the purchase stream emits.
  Future<void> init(
      void Function(List<PurchaseDetails>) onPurchaseUpdate) async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      dev.log('BillingService: Play Store not available');
      return;
    }

    // Listen to purchase updates for the entire app session.
    _subscription = _iap.purchaseStream.listen(
      onPurchaseUpdate,
      onError: (Object e) => dev.log('BillingService stream error: $e'),
    );

    await _loadProducts();
  }

  // ── Product loading ───────────────────────────────────────────────────────

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

  /// Returns [ProductDetails] for a given product ID, or null if unavailable.
  ProductDetails? productFor(String productId) {
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  // ── Purchase flow ─────────────────────────────────────────────────────────

  /// Starts the Google Play purchase dialog for [productId].
  /// Returns false if the product isn't loaded or billing isn't available.
  Future<bool> purchase(String productId) async {
    final product = productFor(productId);
    if (product == null) {
      dev.log('BillingService.purchase: product $productId not found');
      return false;
    }
    final param = PurchaseParam(productDetails: product);
    try {
      // buyNonConsumable is correct for subscriptions on Android
      // (subscriptions are non-consumable recurring purchases).
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      dev.log('BillingService.purchase error: $e');
      return false;
    }
  }

  // ── Restore purchases ─────────────────────────────────────────────────────

  /// Triggers a restore flow — the purchase stream will emit any active
  /// subscriptions that the signed-in Google account already owns.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Complete a purchase ───────────────────────────────────────────────────

  /// Must be called after verifying and delivering a purchase.
  /// Without this call Google Play will auto-refund the subscription after 3 days.
  Future<void> completePurchase(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
  }
}
