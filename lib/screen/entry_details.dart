import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key});

  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

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

  @override
  Widget build(BuildContext context) {
    // All data read from route args — logic unchanged
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String title = args['title'] as String? ?? 'Stock Entry';
    final String ref = args['ref'] as String? ?? '#INV-0000';
    final String amount = args['amount'] as String? ?? '+0';
    final String date = args['date'] as String? ?? 'Unknown date';
    final String type = args['type'] as String? ?? 'material';
    final String name = args['name'] as String? ?? 'Item';
    final bool isPositive = args['isPositive'] as bool? ?? true;
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildTypeBadge(type),
                    const SizedBox(height: 16),

                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name — most prominent
                          _fieldLabel('ITEM'),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: AppTheme.heading2.copyWith(
                              fontSize: 20,
                              color: textDark,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTheme.body.copyWith(color: textGray),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity + Reference row
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
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 26,
                                        color: isPositive
                                            ? _typeColor(type)
                                            : const Color(0xFFE040FB),
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
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const AppDivider(verticalPadding: 12),

                          // Date
                          _fieldLabel('DATE'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: _typeColor(type), size: 15),
                              const SizedBox(width: 6),
                              Text(
                                date,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Affects info banner — logic unchanged
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
                    ),
                    const SizedBox(height: 14),

                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('ATTACHED RECEIPT'),
                          const SizedBox(height: 12),
                          _buildReceiptSection(context, receipt),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Approve',
                            icon: Icons.check_circle_outline,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Reject',
                            icon: Icons.cancel_outlined,
                            variant: AppButtonVariant.danger,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildDeleteButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String type, Map args) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
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
          Expanded(
            child: Text(
              'Entry Detail',
              style: AppTheme.heading3.copyWith(color: textDark),
            ),
          ),
          // Edit button — logic unchanged
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

  Widget _buildReceiptSection(BuildContext context, String? receipt) {
    final hasReceipt = receipt != null && receipt.isNotEmpty;
    final isPdf = hasReceipt ? receipt.toLowerCase().endsWith('.pdf') : false;
    final iconColor = isPdf ? const Color(0xFFEF5350) : primaryBlue;
    final iconBg = isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFEEF0FF);

    return GestureDetector(
      onTap: hasReceipt
          ? () => Navigator.pushNamed(
                context,
                '/receipt-viewer',
                arguments: {'receipt': receipt},
              )
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasReceipt ? const Color(0xFFEEF8EE) : AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasReceipt ? Colors.green.shade300 : AppTheme.divider,
          ),
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
                          style: AppTheme.bodyLarge.copyWith(
                            color: textDark,
                            fontWeight: FontWeight.w700,
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
                  const Icon(Icons.chevron_right, color: Colors.green, size: 20),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.upload_file_outlined,
                        color: textGray, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No receipt attached',
                        style: AppTheme.bodyLarge.copyWith(
                            color: textDark, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'No file was attached to this entry',
                        style: AppTheme.caption.copyWith(color: textGray),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showDeleteDialog(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE0E0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Delete Entry',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: AppTheme.label.copyWith(color: textGray),
    );
  }
}
