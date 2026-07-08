import 'dart:convert';
import 'package:buildtrack_mobile/services/api_service.dart';

// ── AirPay Product ID constants ───────────────────────────────────────────────
// These are the plan identifiers sent to your backend
// Replace with real AirPay product IDs when your teammate provides them
const String kStarterMonthlyId = 'buildtrack_starter_monthly';
const String kGrowthMonthlyId = 'buildtrack_growth_monthly';
const String kProMonthlyId = 'buildtrack_pro_monthly';
const String kBusinessMonthlyId = 'buildtrack_business_monthly';
const String kEnterpriseMonthlyId = 'buildtrack_enterprise_monthly';

// ── Plan amount map (in INR) ──────────────────────────────────────────────────
const Map<String, double> kPlanAmounts = {
  kStarterMonthlyId: 498,
  kGrowthMonthlyId: 999,
  kProMonthlyId: 1499,
  kBusinessMonthlyId: 2499,
  kEnterpriseMonthlyId: 4999,
};

// ── Plan name map ─────────────────────────────────────────────────────────────
const Map<String, String> kPlanNames = {
  kStarterMonthlyId: 'starter',
  kGrowthMonthlyId: 'growth',
  kProMonthlyId: 'pro',
  kBusinessMonthlyId: 'business',
  kEnterpriseMonthlyId: 'enterprise',
};

// ── BillingService ────────────────────────────────────────────────────────────
// Handles all communication with your Node.js backend for payments
class BillingService {
  // Calls POST /api/subscriptions/initiate
  // Returns the paymentParams map needed to build the AirPay WebView form
  static Future<Map<String, dynamic>?> initiatePayment(String productId) async {
    try {
      final planName = kPlanNames[productId];
      if (planName == null) return null;

      final response = await ApiService.post('/subscriptions/initiate', {
        'plan': planName,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['paymentParams'] as Map<String, dynamic>;
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calls GET /api/subscriptions/status
  // Returns the subscription status map from your backend
  static Future<Map<String, dynamic>?> fetchStatus() async {
    try {
      final response = await ApiService.get('/subscriptions/status');
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
