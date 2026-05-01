import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart';
import 'package:buildtrack_mobile/controller/entry_permissions.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  // â”€â”€ Mutable approval state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  EntryStatus _status     = EntryStatus.pending;
  String?     _approvedBy;
  DateTime?   _approvedAt;
  bool        _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final statusStr = args['status'] as String? ?? 'pending';
    _status     = EntryStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => EntryStatus.pending,
    );
    _approvedBy = args['approvedBy'] as String?;
    final approvedAtStr = args['approvedAt'] as String?;
    _approvedAt = approvedAtStr != null ? DateTime.tryParse(approvedAtStr) : null;
  }

  // â”€â”€ Approve / Reject â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _approve() {
    if (_status != EntryStatus.pending) return;
    setState(() {
      _status     = EntryStatus.approved;
      _approvedBy = UserSession.userId;
      _approvedAt = DateTime.now();
    });
    _showFeedback('Entry approved successfully', Colors.green);
  }

  void _reject() {
    if (_status != EntryStatus.pending) return;
    setState(() {
      _status     = EntryStatus.rejected;
      _approvedBy = UserSession.userId;
      _approvedAt = DateTime.now();
    });
    _showFeedback('Entry rejected', Colors.red);
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // â”€â”€ Static helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Color _typeColor(String type) {
    switch (type) {
      case 'labour':    return const Color(0xFF2E7D32);
      case 'equipment': return const Color(0xFFE65100);
      default:          return primaryBlue;
    }
  }

  static Color _typeBg(String type) {
    switch (type) {
      case 'labour':    return const Color(0xFFE8F5E9);
      case 'equipment': return const Color(0xFFFFF3E0);
      default:          return const Color(0xFFEEF0FF);
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'labour':    return Icons.people_outline;
      case 'equipment': return Icons.construction_outlined;
      default:          return Icons.inventory_2_outlined;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'labour':    return 'LABOUR';
      case 'equipment': return 'EQUIPMENT';
      default:          return 'MATERIAL';
    }
  }

  static String _editRoute(String type) {
    switch (type) {
      case 'labour':    return '/add-labour';
      case 'equipment': return '/add-equipment';
      default:          return '/add-material';
    }
  }



  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String title     = args['title']      as String? ?? 'Stock Entry';
    final String ref       = args['ref']        as String? ?? '#INV-0000';
    final String amount    = args['amount']     as String? ?? '+0';
    final String date      = args['date']       as String? ?? 'Unknown date';
    final String type      = args['type']       as String? ?? 'material';
    final String name      = args['name']       as String? ?? 'Item';
    final bool   isPositive = args['isPositive'] as bool?  ?? true;
    final String? receipt  = args['receipt']    as String?;

    // Permissions from centralised helper
    final String createdBy = args['createdBy'] as String? ?? '';
    final String projectId = args['projectId'] as String? ?? '';

    final bool canEdit = EntryPermissions.canEdit(
      status: _status.name,
      createdBy: createdBy,
      projectId: projectId,
    );
    final bool canApprove = EntryPermissions.canApprove();
    final bool canDelete = EntryPermissions.canDelete(
      status: _status.name,
      createdBy: createdBy,
      projectId: projectId,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, type, args, canEdit),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F8)),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        _buildTypeBadge(type),
                        const SizedBox(width: 8),
                        StatusBadge(status: _status.name),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Show approvedBy / approvedAt when resolved
                          if (_approvedBy != null) ...[
                            const AppDivider(verticalPadding: 12),
                            _fieldLabel('REVIEWED BY'),
                            const SizedBox(height: 6),
                            Text(
                              _approvedBy!,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            if (_approvedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_approvedAt!.day}/${_approvedAt!.month}/${_approvedAt!.year} '
                                '${_approvedAt!.hour.toString().padLeft(2, '0')}:'
                                '${_approvedAt!.minute.toString().padLeft(2, '0')}',
                                style: AppTheme.caption.copyWith(color: textGray),
                              ),
                            ],
                          ],

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: purple, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          color: textDark, fontSize: 13),
                                      children: [
                                        TextSpan(text: 'This entry affects: '),
                                        TextSpan(
                                          text: 'Inventory, Reports',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
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

                    // â”€â”€ Approve / Reject â€” only for Admin & Supervisor â”€â”€â”€â”€â”€â”€â”€
                    if (canApprove)
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Approve',
                              icon: Icons.check_circle_outline,
                              onPressed: _approve,
                              enabled: _status == EntryStatus.pending,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Reject',
                              icon: Icons.cancel_outlined,
                              variant: AppButtonVariant.danger,
                              onPressed: _reject,
                              enabled: _status == EntryStatus.pending,
                            ),
                          ),
                        ],
                      ),
                    if (canApprove) const SizedBox(height: 14),

                    if (canDelete) _buildDeleteButton(context),
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

  // â”€â”€ Unchanged widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTopBar(BuildContext context, String type, Map args, bool canEdit) {
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
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.arrow_back, color: textDark, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Entry Detail',
              style: AppTheme.heading3.copyWith(color: textDark),
            ),
          ),
          // Edit button â€” shown only if user has permission
          if (canEdit)
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                _editRoute(type),
                arguments: {...args, 'isEditing': true, 'status': _status.name},
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: const Color(0xFFEEF0FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                  const Icon(Icons.chevron_right,
                      color: Colors.green, size: 20),
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
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style:
                  TextStyle(color: textGray, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: AppTheme.label.copyWith(color: textGray),
      );
}
