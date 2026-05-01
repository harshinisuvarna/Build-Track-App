// lib/controller/subscription_provider.dart
//
// Central subscription state manager.
//
// Exposes:
//   - currentPlan     → which tier the user is on (free/pro/enterprise)
//   - planStatus      → active / expired / unknown
//   - feature gates   → canAddProject, canViewReports, etc.
//   - purchase()      → initiate a Play Store purchase
//   - restore()       → restore previous purchases
//
// Persists the plan locally with SharedPreferences so the user doesn't
// need to be online to use features they've already paid for.

import 'dart:developer' as dev;

import 'package:buildtrack_mobile/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Plan & Status enums ───────────────────────────────────────────────────────

enum SubscriptionPlan { free, pro, enterprise }

enum SubscriptionStatus { active, expired, unknown }

extension SubscriptionPlanX on SubscriptionPlan {
  String get label {
    switch (this) {
      case SubscriptionPlan.free:       return 'Free';
      case SubscriptionPlan.pro:        return 'Pro';
      case SubscriptionPlan.enterprise: return 'Enterprise';
    }
  }

  String get badge {
    switch (this) {
      case SubscriptionPlan.free:       return 'FREE';
      case SubscriptionPlan.pro:        return 'PRO';
      case SubscriptionPlan.enterprise: return 'ENTERPRISE';
    }
  }
}

// ── Persistence keys ──────────────────────────────────────────────────────────

const _kPlanKey           = 'buildtrack_sub_plan_v1';
const _kPurchaseTokenKey  = 'buildtrack_sub_token_v1';
const _kRenewalDateKey    = 'buildtrack_sub_renewal_v1';

// ── Provider ──────────────────────────────────────────────────────────────────

class SubscriptionProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  SubscriptionPlan   _plan       = SubscriptionPlan.free;
  SubscriptionStatus _status     = SubscriptionStatus.active;
  DateTime?          _renewalDate;
  String             _error      = '';
  bool               _isLoading  = false;
  bool               _isPurchasing = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  SubscriptionPlan   get currentPlan    => _plan;
  SubscriptionStatus get status         => _status;
  DateTime?          get renewalDate    => _renewalDate;
  String             get error          => _error;
  bool               get isLoading      => _isLoading;
  bool               get isPurchasing   => _isPurchasing;

  bool get isPro        => _plan == SubscriptionPlan.pro        && _status == SubscriptionStatus.active;
  bool get isEnterprise => _plan == SubscriptionPlan.enterprise && _status == SubscriptionStatus.active;
  bool get isPaid       => isPro || isEnterprise;

  // ── Feature gates ──────────────────────────────────────────────────────────
  // These are the single source of truth for feature availability.
  // Check these from any widget/screen before rendering gated features.

  /// Free: max 2 projects. Pro/Enterprise: unlimited.
  bool canAddProject(int currentProjectCount) {
    if (isPaid) return true;
    return currentProjectCount < 2;
  }

  /// Reports & analytics are Pro+ only.
  bool get canViewReports => isPaid;

  /// Inventory tracking is Pro+ only.
  bool get canViewInventory => isPaid;

  /// Receipt/file storage is Pro+ only.
  bool get canStoreReceipts => isPaid;

  /// Multi-user role management is Enterprise only.
  bool get canManageRoles => isEnterprise;

  // ── Billing service reference ─────────────────────────────────────────────

  final BillingService _billing = BillingService.instance;

  // ── Constructor ────────────────────────────────────────────────────────────

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    _setLoading(true);
    await _loadPersistedPlan();
    await _billing.init(_onPurchaseUpdate);
    _setLoading(false);
  }

  // ── Persist / restore plan locally ────────────────────────────────────────

  Future<void> _loadPersistedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planStr = prefs.getString(_kPlanKey) ?? 'free';
      _plan = _planFromString(planStr);
      final renewalStr = prefs.getString(_kRenewalDateKey);
      if (renewalStr != null) {
        _renewalDate = DateTime.tryParse(renewalStr);
        // Check if the stored subscription has expired locally.
        if (_renewalDate != null && _renewalDate!.isBefore(DateTime.now())) {
          _plan   = SubscriptionPlan.free;
          _status = SubscriptionStatus.expired;
          await _persistPlan();
        } else {
          _status = SubscriptionStatus.active;
        }
      }
    } catch (e) {
      dev.log('SubscriptionProvider._loadPersistedPlan error: $e');
    }
  }

  Future<void> _persistPlan({String? purchaseToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPlanKey, _plan.name);
      if (purchaseToken != null) {
        await prefs.setString(_kPurchaseTokenKey, purchaseToken);
      }
      if (_renewalDate != null) {
        await prefs.setString(_kRenewalDateKey, _renewalDate!.toIso8601String());
      }
    } catch (e) {
      dev.log('SubscriptionProvider._persistPlan error: $e');
    }
  }

  // ── Purchase stream handler ───────────────────────────────────────────────

  /// Called by BillingService whenever the purchase stream emits.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
    notifyListeners();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Show loading, nothing to do yet.
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // ── Verification ─────────────────────────────────────────────────────
        // In production: send purchase.verificationData to your backend and
        // validate the receipt with the Google Play Developer API.
        // Here we mock-verify and grant access immediately.
        final verified = await _mockVerify(purchase);
        if (verified) {
          _grantAccess(purchase);
        }
        // IMPORTANT: always call completePurchase regardless of verification
        // result to avoid Google Play holding the purchase open.
        await _billing.completePurchase(purchase);
        break;

      case PurchaseStatus.error:
        _error = purchase.error?.message ?? 'Purchase failed';
        _isPurchasing = false;
        dev.log('Purchase error: ${purchase.error}');
        break;

      case PurchaseStatus.canceled:
        _isPurchasing = false;
        dev.log('Purchase cancelled by user');
        break;
    }
  }

  /// Mock verification — replace with real backend call before release.
  Future<bool> _mockVerify(PurchaseDetails purchase) async {
    // Simulate a network round-trip.
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Always approve in dev/mock mode.
  }

  /// Grant plan access after a verified purchase or restore.
  void _grantAccess(PurchaseDetails purchase) {
    switch (purchase.productID) {
      case kProMonthlyId:
        _plan   = SubscriptionPlan.pro;
        _status = SubscriptionStatus.active;
        // Subscription is monthly — set renewal date 30 days from now.
        _renewalDate = DateTime.now().add(const Duration(days: 30));
        break;
      case kEnterpriseMonthlyId:
        _plan        = SubscriptionPlan.enterprise;
        _status      = SubscriptionStatus.active;
        _renewalDate = DateTime.now().add(const Duration(days: 30));
        break;
    }
    _isPurchasing = false;
    _error        = '';
    _persistPlan(purchaseToken: purchase.verificationData.serverVerificationData);
  }

  // ── Public actions ────────────────────────────────────────────────────────

  /// Starts the Google Play purchase sheet for the given product ID.
  Future<void> purchase(String productId) async {
    if (_isPurchasing) return;
    _error = '';
    _isPurchasing = true;
    notifyListeners();

    final started = await _billing.purchase(productId);
    if (!started) {
      _error = 'Could not start purchase. Please try again.';
      _isPurchasing = false;
      notifyListeners();
    }
    // The result arrives via _onPurchaseUpdate — isPurchasing is reset there.
  }

  /// Restores previous purchases from the Play Store.
  Future<void> restore() async {
    _isLoading = true;
    _error     = '';
    notifyListeners();
    try {
      await _billing.restorePurchases();
      // Restored purchases arrive via _onPurchaseUpdate automatically.
    } catch (e) {
      _error = 'Restore failed. Please try again.';
      dev.log('SubscriptionProvider.restore error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  SubscriptionPlan _planFromString(String s) {
    switch (s) {
      case 'pro':        return SubscriptionPlan.pro;
      case 'enterprise': return SubscriptionPlan.enterprise;
      default:           return SubscriptionPlan.free;
    }
  }

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }
}
