import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/services/billing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── SubscriptionPlan enum ─────────────────────────────────────────────────────
// Must match every plan used in subscription_screen.dart and subscription_card.dart
enum SubscriptionPlan { free, starter, growth, pro, business, enterprise }

extension SubscriptionPlanX on SubscriptionPlan {
  String get label {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.starter:
        return 'Starter';
      case SubscriptionPlan.growth:
        return 'Growth';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.business:
        return 'Business';
      case SubscriptionPlan.enterprise:
        return 'Enterprise';
    }
  }

  // Short badge text shown on SubscriptionCard (top-right pill)
  String get badge {
    switch (this) {
      case SubscriptionPlan.free:
        return 'FREE';
      case SubscriptionPlan.starter:
        return 'STARTER';
      case SubscriptionPlan.growth:
        return 'GROWTH';
      case SubscriptionPlan.pro:
        return 'PRO';
      case SubscriptionPlan.business:
        return 'BUSINESS';
      case SubscriptionPlan.enterprise:
        return 'ENTERPRISE';
    }
  }

  // User limit per plan — used by SubscriptionCard's limit chips
  int get maxUsers {
    switch (this) {
      case SubscriptionPlan.free:
        return 2;
      case SubscriptionPlan.starter:
        return 5;
      case SubscriptionPlan.growth:
        return 8;
      case SubscriptionPlan.pro:
        return 15;
      case SubscriptionPlan.business:
        return 25;
      case SubscriptionPlan.enterprise:
        return 999999; // treated as "Unlimited" in UI
    }
  }

  // Project limit per plan. -1 means unlimited (enterprise).
  // free is handled as a special case in the UI ("1 project / 30 days")
  int get maxProjects {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.starter:
        return 2;
      case SubscriptionPlan.growth:
        return 4;
      case SubscriptionPlan.pro:
        return 6;
      case SubscriptionPlan.business:
        return 12;
      case SubscriptionPlan.enterprise:
        return -1; // unlimited
    }
  }

  // Maps backend plan string → enum value
  static SubscriptionPlan fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'starter':
        return SubscriptionPlan.starter;
      case 'growth':
        return SubscriptionPlan.growth;
      case 'pro':
        return SubscriptionPlan.pro;
      case 'business':
        return SubscriptionPlan.business;
      case 'enterprise':
        return SubscriptionPlan.enterprise;
      default:
        return SubscriptionPlan.free;
    }
  }
}

// ── SubscriptionStatus enum ───────────────────────────────────────────────────
// Used by SubscriptionCard's status dot/badge
enum SubscriptionStatus { active, expired, unknown }

// ── SubscriptionProvider ──────────────────────────────────────────────────────
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  SubscriptionStatus _status = SubscriptionStatus.unknown;
  bool _isPurchasing = false;
  bool _isLoading = false;
  String _error = '';
  DateTime? _expiryDate;

  // ── Getters — read by subscription_screen.dart and subscription_card.dart ──
  SubscriptionPlan get currentPlan => _currentPlan;
  SubscriptionStatus get status => _status;
  bool get isPurchasing => _isPurchasing;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime? get expiryDate => _expiryDate;

  // renewalDate is an alias of expiryDate — subscription_card.dart reads
  // this name specifically for the "Renews <date>" row
  DateTime? get renewalDate => _expiryDate;

  // isPaid = true if on any paid plan
  bool get isPaid => _currentPlan != SubscriptionPlan.free;

  // ── Holds payment params returned by backend after initiate call ─────────────
  // PaymentWebViewScreen reads this to build the AirPay HTML form
  Map<String, dynamic>? _pendingPaymentParams;
  Map<String, dynamic>? get pendingPaymentParams => _pendingPaymentParams;

  // =============================================================================
  // FETCH STATUS — call this on app start and after payment returns
  // =============================================================================
  Future<void> fetchStatus() async {
    await _loadPersistedSubscription();
    
    // If we loaded cached subscription state, notify and launch background fetch
    if (_currentPlan != SubscriptionPlan.free || _status != SubscriptionStatus.unknown) {
      _isLoading = false;
      notifyListeners();
      _fetchStatusFromNetwork();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();
    await _fetchStatusFromNetwork();
  }

  Future<void> _fetchStatusFromNetwork() async {
    try {
      final data = await BillingService.fetchStatus();
      if (data != null && data['hasSubscription'] == true) {
        _currentPlan = SubscriptionPlanX.fromString(data['plan']?.toString());

        if (data['endDate'] != null) {
          _expiryDate = DateTime.tryParse(data['endDate'].toString());
        } else {
          _expiryDate = null;
        }

        // Determine status from endDate vs now
        if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now())) {
          _status = SubscriptionStatus.active;
        } else if (_expiryDate != null) {
          _status = SubscriptionStatus.expired;
        } else {
          _status =
              SubscriptionStatus.active; // backend says active, no date given
        }
      } else {
        _currentPlan = SubscriptionPlan.free;
        _expiryDate = null;
        _status = SubscriptionStatus.unknown;
      }
      _error = '';
      await _persistSubscription();
    } catch (e) {
      _error = 'Could not fetch subscription status';
      _status = SubscriptionStatus.unknown;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================================================
  // PURCHASE — subscription_screen.dart calls this when user taps a plan
  // Returns the paymentParams map so the screen can open PaymentWebViewScreen
  // =============================================================================
  Future<Map<String, dynamic>?> purchase(String productId) async {
    if (_isPurchasing) return null;
    _isPurchasing = true;
    _error = '';
    notifyListeners();

    try {
      final params = await BillingService.initiatePayment(productId);
      if (params == null) {
        _error = 'Could not initiate payment. Please try again.';
        return null;
      }
      _pendingPaymentParams = params;
      return params;
    } catch (e) {
      _error = 'Payment initiation failed: ${e.toString()}';
      return null;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  // =============================================================================
  // RESTORE — called when user taps "Restore Purchases" / "Restore"
  // Checks backend for any active subscription linked to this account
  // =============================================================================
  Future<void> restore() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await fetchStatus();
      if (_currentPlan == SubscriptionPlan.free) {
        // No active subscription found — not treated as an error
        _error = '';
      }
    } catch (e) {
      _error = 'Restore failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================================================
  // Called by PaymentWebViewScreen after payment completes
  // success = true  → deep link was buildtrack://payment/success
  // success = false → deep link was buildtrack://payment/failure
  // =============================================================================
  Future<void> handlePaymentResult(bool success) async {
    _pendingPaymentParams = null;
    if (success) {
      // Re-fetch status from backend so currentPlan updates immediately
      await fetchStatus();
    } else {
      _error = 'Payment was not completed. Please try again.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Alias used by profile.dart — clears error state
  // (profile.dart calls `.clear()` on logout/reset)
  void clear() {
    _currentPlan = SubscriptionPlan.free;
    _status = SubscriptionStatus.unknown;
    _expiryDate = null;
    _error = '';
    _pendingPaymentParams = null;
    notifyListeners();
  }

  Future<void> _persistSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('buildtrack_subscription_plan', _currentPlan.name);
      await prefs.setString('buildtrack_subscription_status', _status.name);
      if (_expiryDate != null) {
        await prefs.setString('buildtrack_subscription_expiry', _expiryDate!.toIso8601String());
      } else {
        await prefs.remove('buildtrack_subscription_expiry');
      }
    } catch (e) {
      debugPrint('Persist subscription error: $e');
    }
  }

  Future<void> _loadPersistedSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planStr = prefs.getString('buildtrack_subscription_plan');
      final statusStr = prefs.getString('buildtrack_subscription_status');
      final expiryStr = prefs.getString('buildtrack_subscription_expiry');

      if (planStr != null) {
        _currentPlan = SubscriptionPlan.values.firstWhere(
          (e) => e.name == planStr,
          orElse: () => SubscriptionPlan.free,
        );
      }
      if (statusStr != null) {
        _status = SubscriptionStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => SubscriptionStatus.unknown,
        );
      }
      if (expiryStr != null) {
        _expiryDate = DateTime.tryParse(expiryStr);
      }
    } catch (e) {
      debugPrint('Load persisted subscription error: $e');
    }
  }
}
