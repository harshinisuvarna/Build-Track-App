import 'package:flutter/material.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key});

  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildMaterialBadge(),
                    const SizedBox(height: 14),
                    _buildDetailCard(),
                    const SizedBox(height: 14),
                    _buildReceiptSection(),
                    const SizedBox(height: 14),
                    _buildDeleteButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          const Text('Entry detail',
              style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: () {},
            child: const Text('Edit',
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: purple, size: 14),
            SizedBox(width: 6),
            Text('MATERIAL',
                style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ITEM',
              style: TextStyle(
                  fontSize: 11, color: textGray, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          const Text('High-Tensile Steel Rebar (12mm)',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: textDark, height: 1.3)),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('QUANTITY',
                        style: TextStyle(
                            fontSize: 10,
                            color: textGray,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    SizedBox(height: 4),
                    Text('250 Units',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16, color: textDark)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('RATE',
                        style: TextStyle(
                            fontSize: 10,
                            color: textGray,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    SizedBox(height: 4),
                    Text('\$14.50 / unit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16, color: textDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),
          const Text('TOTAL COST',
              style: TextStyle(
                  fontSize: 10, color: textGray, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          const Text('\$3,625.00',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: -0.5)),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),
          const Text('PROJECT',
              style: TextStyle(
                  fontSize: 10, color: textGray, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.architecture, color: primaryBlue, size: 16),
              SizedBox(width: 6),
              Text('Metro Plaza Phase II',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textDark)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),
          const Text('DATE',
              style: TextStyle(
                  fontSize: 10, color: textGray, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: primaryBlue, size: 15),
              SizedBox(width: 6),
              Text('Oct 24, 2023 • 09:45 AM',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textDark)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: purple, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: textDark, fontSize: 13),
                      children: [
                        TextSpan(text: 'This entry affects: '),
                        TextSpan(
                          text: 'Inventory, Reports',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ATTACHED RECEIPT',
            style: TextStyle(
                fontSize: 11, color: textGray, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Container(
          height: 160,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for receipt image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF176),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 8),
              const Text('Receipt.pdf',
                  style: TextStyle(color: textGray, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: InkWell(
        onTap: () => _showDeleteDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Delete Entry',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Entry?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This action cannot be undone. The entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7B8A9E), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}