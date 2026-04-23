import 'package:flutter/material.dart';

class ReceiptViewerScreen extends StatelessWidget {
  const ReceiptViewerScreen({super.key});

  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String receipt = args['receipt'] as String? ?? 'receipt.pdf';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, receipt),
            Expanded(child: _buildReceiptView(context, receipt)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String receipt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          const Text('Receipt',
              style: TextStyle(
                  color: textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download started')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_outlined,
                  color: primaryBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptView(BuildContext context, String receipt) {
    final isPdf = receipt.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // File info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E5FF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPdf
                        ? Colors.red.withValues(alpha: 0.1)
                        : primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: isPdf ? Colors.red : primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(receipt,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textDark)),
                      const SizedBox(height: 2),
                      Text(isPdf ? 'PDF Document' : 'Image File',
                          style: const TextStyle(
                              color: textGray, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Verified',
                      style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Receipt placeholder viewer
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.receipt_long,
                      color: primaryBlue,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(receipt,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textDark)),
                  const SizedBox(height: 8),
                  const Text(
                    'Receipt preview would appear here\nwhen connected to storage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textGray, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening file...')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2233DD), Color(0xFF5B3FE0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: primaryBlue.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Open Full View',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
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