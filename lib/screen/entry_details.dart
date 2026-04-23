import 'package:flutter/material.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key});

  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  // ── Type-based helpers ────────────────────────────────────────────────────

  static Color _typeColor(String type) {
    switch (type) {
      case 'labour':
        return const Color(0xFF2E7D32);
      case 'equipment':
        return const Color(0xFFE65100);
      default:
        return primaryBlue;
    }
  }

  static Color _typeBg(String type) {
    switch (type) {
      case 'labour':
        return const Color(0xFFE8F5E9);
      case 'equipment':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEEF0FF);
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'labour':
        return Icons.people_outline;
      case 'equipment':
        return Icons.construction_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'labour':
        return 'LABOUR';
      case 'equipment':
        return 'EQUIPMENT';
      default:
        return 'MATERIAL';
    }
  }

  // FIX: type-based route for Edit button
  static String _editRoute(String type) {
    switch (type) {
      case 'labour':
        return '/add-labour';
      case 'equipment':
        return '/add-equipment';
      default:
        return '/add-material';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // FIX: all data read from route args — no static values
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String title = args['title'] as String? ?? 'Stock Entry';
    final String ref = args['ref'] as String? ?? '#INV-0000';
    final String amount = args['amount'] as String? ?? '+0';
    final String date = args['date'] as String? ?? 'Unknown date';
    final String type = args['type'] as String? ?? 'material';
    final String name = args['name'] as String? ?? 'Item';
    final bool isPositive = args['isPositive'] as bool? ?? true;
    // FIX: null-safe receipt
    final String? receipt = args['receipt'] as String?;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, type, args),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F8)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    _buildTypeBadge(type),
                    const SizedBox(height: 14),
                    _buildDetailCard(
                      name,
                      title,
                      ref,
                      amount,
                      date,
                      type,
                      isPositive,
                    ),
                    const SizedBox(height: 14),
                    _buildReceiptSection(context, receipt),
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

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, String type, Map args) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Consistent back button style
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: textDark, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Entry detail',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // FIX: Edit routes to correct screen based on type
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              _editRoute(type),
              arguments: {...args, 'isEditing': true},
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: const Color(0xFFEEF0FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Type Badge ────────────────────────────────────────────────────────────

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _typeBg(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), color: _typeColor(type), size: 13),
          const SizedBox(width: 6),
          Text(
            _typeLabel(type),
            style: TextStyle(
              color: _typeColor(type),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Detail Card ───────────────────────────────────────────────────────────

  Widget _buildDetailCard(
    String name,
    String title,
    String ref,
    String amount,
    String date,
    String type,
    bool isPositive,
  ) {
    final color = _typeColor(type);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          _fieldLabel('ITEM'),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              color: textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),

          // Quantity + Reference
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('QUANTITY'),
                    const SizedBox(height: 6),
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        color: isPositive ? color : const Color(0xFFE040FB),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('REFERENCE'),
                    const SizedBox(height: 6),
                    Text(
                      ref,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),

          // Date
          _fieldLabel('DATE'),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Affects info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: purple, size: 16),
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

  // ── Receipt Section ───────────────────────────────────────────────────────

  Widget _buildReceiptSection(BuildContext context, String? receipt) {
    // FIX: null-safe check before showing receipt
    final hasReceipt = receipt != null && receipt.isNotEmpty;
    final isPdf = hasReceipt ? receipt.toLowerCase().endsWith('.pdf') : false;
    final iconColor = isPdf ? const Color(0xFFEF5350) : primaryBlue;
    final iconBg = isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFEEF0FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ATTACHED RECEIPT',
          style: TextStyle(
            fontSize: 11,
            color: textGray,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          // FIX: only navigates when receipt actually exists
          onTap: hasReceipt
              ? () => Navigator.pushNamed(
                  context,
                  '/receipt-viewer',
                  // FIX: consistent argument format
                  arguments: {'receipt': receipt},
                )
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasReceipt ? const Color(0xFFEEF8EE) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasReceipt
                    ? Colors.green.shade300
                    : const Color(0xFFEEF0F5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: hasReceipt
                ? Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receipt,
                              style: const TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Tap to view receipt',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  )
                // FIX: empty state for no receipt
                : Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.upload_file_outlined,
                          color: textGray,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No receipt attached',
                            style: TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'No file was attached to this entry',
                            style: TextStyle(color: textGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Delete Button ─────────────────────────────────────────────────────────

  Widget _buildDeleteButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: InkWell(
        onTap: () => _showDeleteDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Delete Entry',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This action cannot be undone. The entry will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field label helper ────────────────────────────────────────────────────

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        color: textGray,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
