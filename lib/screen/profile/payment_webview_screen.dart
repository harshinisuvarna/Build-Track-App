import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> paymentParams;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentParams,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // ── Catch AirPay deep link redirect ────────────────────
            // AirPay callback redirects to buildtrack://payment/...
            if (url.startsWith('buildtrack://payment/')) {
              final isSuccess = url.contains('/success');
              _handlePaymentReturn(isSuccess);
              return NavigationDecision.prevent;
            }

            // ── Also catch ngrok callback URL in case redirect
            // happens via the backend URL before deep link ───────────
            if (url.contains('/api/subscriptions/callback')) {
              // Let it load — backend will redirect to deep link
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      // ── Load the AirPay POST form as an HTML string ───────────────
      // AirPay requires a POST request — WebViews cannot do POST navigation
      // directly. The standard solution is to inject a hidden HTML form
      // and auto-submit it via JavaScript on page load.
      ..loadHtmlString(_buildPaymentHtml());
  }

  String _buildPaymentHtml() {
    final p = widget.paymentParams;
    final airpayUrl = p['airpayUrl']?.toString() ?? '';

    // Build one hidden <input> for every param except airpayUrl itself
    final StringBuffer inputFields = StringBuffer();
    p.forEach((key, value) {
      if (key != 'airpayUrl') {
        // Escape any special HTML characters in values
        final safeValue = value
            .toString()
            .replaceAll('&', '&amp;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        inputFields.write(
          '<input type="hidden" name="$key" value="$safeValue" />\n',
        );
      }
    });

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body {
        margin: 0;
        padding: 0;
        background: #ffffff;
        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        color: #344054;
      }
      .loader {
        width: 40px;
        height: 40px;
        border: 3px solid #E0E5FF;
        border-top: 3px solid #173EEA;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
        margin-bottom: 16px;
      }
      @keyframes spin {
        to { transform: rotate(360deg); }
      }
      p {
        font-size: 15px;
        font-weight: 600;
        color: #667085;
      }
    </style>
  </head>
  <body onload="document.getElementById('payForm').submit()">
    <div class="loader"></div>
    <p>Connecting to secure payment...</p>
    <form id="payForm" method="POST" action="$airpayUrl">
      $inputFields
    </form>
  </body>
</html>
''';
  }

  void _handlePaymentReturn(bool isSuccess) {
    // Tell provider to re-fetch subscription status from backend
    context.read<SubscriptionProvider>().handlePaymentResult(isSuccess);
    // Pop with result so subscription_screen knows to show dialog
    if (mounted) Navigator.of(context).pop(isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF12B76A), size: 16),
            SizedBox(width: 6),
            Text(
              'Secure Payment',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF344054)),
          onPressed: () {
            // User manually closed — treat as failure
            _handlePaymentReturn(false);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEAECF0)),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // ── Loading overlay ─────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading secure payment...',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}