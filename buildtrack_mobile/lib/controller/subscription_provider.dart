import 'dart:developer' as dev;
import 'package:buildtrack_mobile/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
const _kPlanKey           = 'buildtrack_sub_plan_v1';
const _kPurchaseTokenKey  = 'buildtrack_sub_token_v1';
const _kRenewalDateKey    = 'buildtrack_sub_renewal_v1';
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionPlan   _plan       = SubscriptionPlan.free;
  SubscriptionStatus _status     = SubscriptionStatus.active;
  DateTime?          _renewalDate;
  String             _error      = '';
  bool               _isLoading  = false;
  bool               _isPurchasing = false;
  SubscriptionPlan   get currentPlan    => _plan;
  SubscriptionStatus get status         => _status;
  DateTime?          get renewalDate    => _renewalDate;
  String             get error          => _error;
  bool               get isLoading      => _isLoading;
  bool               get isPurchasing   => _isPurchasing;
  bool get isPro        => _plan == SubscriptionPlan.pro        && _status == SubscriptionStatus.active;
  bool get isEnterprise => _plan == SubscriptionPlan.enterprise && _status == SubscriptionStatus.active;
  bool get isPaid       => isPro || isEnterprise;
  bool canAddProject(int currentProjectCount) {
    if (isPaid) return true;
    return currentProjectCount < 2;
  }
  bool get canViewReports => isPaid;
  bool get canViewInventory => isPaid;
  bool get canStoreReceipts => isPaid;
  bool get canManageRoles => isEnterprise;
  final BillingService _billing = BillingService.instance;
  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    _setLoading(true);
    await _loadPersistedPlan();
    await _billing.init(_onPurchaseUpdate);
    _setLoading(false);
  }
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
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
    notifyListeners();
  }
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final verified = await _mockVerify(purchase);
        if (verified) {
          _grantAccess(purchase);
        }
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
  Future<bool> _mockVerify(PurchaseDetails purchase) async {
    // Simulate a network round-trip.
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Always approve in dev/mock mode.
  }
  void _grantAccess(PurchaseDetails purchase) {
    switch (purchase.productID) {
      case kProMonthlyId:
        _plan   = SubscriptionPlan.pro;
        _status = SubscriptionStatus.active;
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
  }
  Future<void> restore() async {
    _isLoading = true;
    _error     = '';
    notifyListeners();
    try {
      await _billing.restorePurchases();
    } catch (e) {
      _error = 'Restore failed. Please try again.';
      dev.log('SubscriptionProvider.restore error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
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
