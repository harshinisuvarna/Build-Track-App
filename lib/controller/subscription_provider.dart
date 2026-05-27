import 'dart:convert';
import 'dart:developer' as dev;
import 'package:buildtrack_mobile/services/billing_service.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Enums ──────────────────────────────────────────────────────────────────
enum SubscriptionPlan { free, starter, growth, pro, business, enterprise }
enum SubscriptionStatus { active, expired, unknown }

extension SubscriptionPlanX on SubscriptionPlan {
  String get label {
    switch (this) {
      case SubscriptionPlan.free:       return 'Free';
      case SubscriptionPlan.starter:    return 'Starter';
      case SubscriptionPlan.growth:     return 'Growth';
      case SubscriptionPlan.pro:        return 'Pro';
      case SubscriptionPlan.business:   return 'Business';
      case SubscriptionPlan.enterprise: return 'Enterprise';
    }
  }

  String get badge {
    switch (this) {
      case SubscriptionPlan.free:       return 'FREE';
      case SubscriptionPlan.starter:    return 'STARTER';
      case SubscriptionPlan.growth:     return 'GROWTH';
      case SubscriptionPlan.pro:        return 'PRO';
      case SubscriptionPlan.business:   return 'BUSINESS';
      case SubscriptionPlan.enterprise: return 'ENTERPRISE';
    }
  }

  int get maxUsers {
    switch (this) {
      case SubscriptionPlan.free:       return 2;
      case SubscriptionPlan.starter:    return 5;
      case SubscriptionPlan.growth:     return 8;
      case SubscriptionPlan.pro:        return 15;
      case SubscriptionPlan.business:   return 25;
      case SubscriptionPlan.enterprise: return 999999;
    }
  }

  /// -1 = unlimited. Free = 1 project per 30 days (enforced separately).
  int get maxProjects {
    switch (this) {
      case SubscriptionPlan.free:       return 1;
      case SubscriptionPlan.starter:    return 2;
      case SubscriptionPlan.growth:     return 4;
      case SubscriptionPlan.pro:        return 6;
      case SubscriptionPlan.business:   return 12;
      case SubscriptionPlan.enterprise: return -1;
    }
  }
}

// ── Persistence keys ───────────────────────────────────────────────────────
const _kPlanKey        = 'buildtrack_sub_plan_v2';
const _kTokenKey       = 'buildtrack_sub_token_v2';
const _kRenewalDateKey = 'buildtrack_sub_renewal_v2';

// ── Provider ───────────────────────────────────────────────────────────────
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionPlan   _plan         = SubscriptionPlan.free;
  SubscriptionStatus _status       = SubscriptionStatus.active;
  DateTime?          _renewalDate;
  String             _error        = '';
  bool               _isLoading    = false;
  bool               _isPurchasing = false;

  SubscriptionPlan   get currentPlan  => _plan;
  SubscriptionStatus get status       => _status;
  DateTime?          get renewalDate  => _renewalDate;
  String             get error        => _error;
  bool               get isLoading    => _isLoading;
  bool               get isPurchasing => _isPurchasing;

  bool get isFree       => _plan == SubscriptionPlan.free;
  bool get isStarter    => _plan == SubscriptionPlan.starter    && _status == SubscriptionStatus.active;
  bool get isGrowth     => _plan == SubscriptionPlan.growth     && _status == SubscriptionStatus.active;
  bool get isPro        => _plan == SubscriptionPlan.pro        && _status == SubscriptionStatus.active;
  bool get isBusiness   => _plan == SubscriptionPlan.business   && _status == SubscriptionStatus.active;
  bool get isEnterprise => _plan == SubscriptionPlan.enterprise && _status == SubscriptionStatus.active;
  bool get isPaid       => !isFree && _status == SubscriptionStatus.active;

  int get maxUsers    => _plan.maxUsers;
  int get maxProjects => _plan.maxProjects; // -1 = unlimited

  bool canAddProject(int currentCount) {
    if (_plan.maxProjects == -1) return true;
    return currentCount < _plan.maxProjects;
  }

  bool get canViewReports   => isPaid;
  bool get canViewInventory => isPaid;
  bool get canStoreReceipts => isPaid;
  bool get canManageRoles   => isBusiness || isEnterprise;

  final BillingService _billing = BillingService.instance;

  SubscriptionProvider() { _init(); }

  // ── Init ──────────────────────────────────────────────────────────────
  Future<void> _init() async {
    _setLoading(true);
    await _loadFromBackend();
    await _billing.init(_onPurchaseUpdate);
    _setLoading(false);
  }

  // ── Load from backend (falls back to SharedPrefs) ─────────────────────
  Future<void> _loadFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('jwt_token');
      if (token == null) {
        await _loadPersistedPlan();
        return;
      }

      // ApiService.get() returns http.Response — decode manually
      final response = await ApiService.get('/users/subscription');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final sub  = body['subscription'] as Map<String, dynamic>?;
        if (sub != null) {
          _plan   = _planFromString(sub['plan']   ?? 'free');
          _status = _statusFromString(sub['status'] ?? 'active');
          _renewalDate = sub['renewalDate'] != null
              ? DateTime.tryParse(sub['renewalDate'].toString())
              : null;
          await _persistPlan();
          return;
        }
      }
      // Non-200 or empty sub — fall back to local
      await _loadPersistedPlan();
    } catch (e) {
      dev.log('SubscriptionProvider._loadFromBackend error: $e');
      await _loadPersistedPlan();
    }
  }

  Future<void> _loadPersistedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _plan = _planFromString(prefs.getString(_kPlanKey) ?? 'free');
      final renewalStr = prefs.getString(_kRenewalDateKey);
      if (renewalStr != null) {
        _renewalDate = DateTime.tryParse(renewalStr);
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
      if (purchaseToken != null) await prefs.setString(_kTokenKey, purchaseToken);
      if (_renewalDate != null) {
        await prefs.setString(_kRenewalDateKey, _renewalDate!.toIso8601String());
      }
    } catch (e) {
      dev.log('SubscriptionProvider._persistPlan error: $e');
    }
  }

  // ApiService.put() also returns http.Response
  Future<void> _syncToBackend({String? purchaseToken}) async {
    try {
      await ApiService.put('/users/subscription', {
        'plan':          _plan.name,
        'status':        _status.name,
        'renewalDate':   _renewalDate?.toIso8601String(),
        'purchaseToken': purchaseToken,
      });
    } catch (e) {
      dev.log('SubscriptionProvider._syncToBackend error: $e');
    }
  }

  // ── Purchase flow ─────────────────────────────────────────────────────
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) { await _handlePurchase(p); }
    notifyListeners();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final verified = await _mockVerify(purchase);
        if (verified) _grantAccess(purchase);
        await _billing.completePurchase(purchase);
        break;
      case PurchaseStatus.error:
        _error        = purchase.error?.message ?? 'Purchase failed';
        _isPurchasing = false;
        dev.log('Purchase error: ${purchase.error}');
        break;
      case PurchaseStatus.canceled:
        _isPurchasing = false;
        dev.log('Purchase cancelled');
        break;
    }
  }

  Future<bool> _mockVerify(PurchaseDetails purchase) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  void _grantAccess(PurchaseDetails purchase) {
    _plan        = _planFromProductId(purchase.productID);
    _status      = SubscriptionStatus.active;
    _renewalDate = DateTime.now().add(const Duration(days: 30));
    _isPurchasing = false;
    _error        = '';
    final token = purchase.verificationData.serverVerificationData;
    _persistPlan(purchaseToken: token);
    _syncToBackend(purchaseToken: token);
  }

  Future<void> purchase(String productId) async {
    if (_isPurchasing) return;
    _error        = '';
    _isPurchasing = true;
    notifyListeners();
    final started = await _billing.purchase(productId);
    if (!started) {
      _error        = 'Could not start purchase. Please try again.';
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

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  // ── Helpers ──────────────────────────────────────────────────────────
  SubscriptionPlan _planFromString(String s) {
    switch (s) {
      case 'starter':    return SubscriptionPlan.starter;
      case 'growth':     return SubscriptionPlan.growth;
      case 'pro':        return SubscriptionPlan.pro;
      case 'business':   return SubscriptionPlan.business;
      case 'enterprise': return SubscriptionPlan.enterprise;
      default:           return SubscriptionPlan.free;
    }
  }

  SubscriptionStatus _statusFromString(String s) {
    switch (s) {
      case 'expired': return SubscriptionStatus.expired;
      case 'unknown': return SubscriptionStatus.unknown;
      default:        return SubscriptionStatus.active;
    }
  }

  SubscriptionPlan _planFromProductId(String id) {
    switch (id) {
      case kStarterMonthlyId:    return SubscriptionPlan.starter;
      case kGrowthMonthlyId:     return SubscriptionPlan.growth;
      case kProMonthlyId:        return SubscriptionPlan.pro;
      case kBusinessMonthlyId:   return SubscriptionPlan.business;
      case kEnterpriseMonthlyId: return SubscriptionPlan.enterprise;
      default:                   return SubscriptionPlan.free;
    }
  }

  @override
  void dispose() { _billing.dispose(); super.dispose(); }
}