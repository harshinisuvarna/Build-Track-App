import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart';
import 'package:buildtrack_mobile/controller/entry_permissions.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;

  // ── State loaded from route args ─────────────────────────────────────────
  bool _argsLoaded = false;
  EntryStatus _entryStatus = EntryStatus.pending;
  PaymentStatus _payStatus = PaymentStatus.pending;
  double _billAmount = 0;
  double _paidAmount = 0;
  List<dynamic> _paymentHistory = [];
  String? _paymentReceiptFile;
  bool _viewAllPayments = false;
  String? _customDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final statusStr = args['status'] as String? ?? 'pending';
    _entryStatus = EntryStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => EntryStatus.pending,
    );
    _payStatus =
        args['paymentStatus'] as PaymentStatus? ?? PaymentStatus.pending;
    _billAmount = (args['billAmount'] as num?)?.toDouble() ?? 0;
    _paidAmount = (args['paidAmount'] as num?)?.toDouble() ?? 0;

    final rawHistory = args['paymentHistory'];
    if (rawHistory is List) {
      _paymentHistory = List.from(rawHistory);
    } else {
      _paymentHistory = [];
    }
    _customDate = args['date'] as String?;
  }

  // ── Static type helpers ──────────────────────────────────────────────────

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

  // ── Formatters ────────────────────────────────────────────────────────────

  Widget _fieldLabel(String t) =>
      Text(t, style: AppTheme.label.copyWith(color: textGray));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String title = args['title'] as String? ?? 'Stock Entry';
    final String ref = args['ref'] as String? ?? '#INV-0000';
    final String amount = args['amount'] as String? ?? '+0';
    final String date = _customDate ?? args['date'] as String? ?? 'Unknown date';
    String displayDate = date;
    if (displayDate.contains('T')) {
      try {
        final dt = DateTime.parse(displayDate);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        displayDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }
    final String type = args['type'] as String? ?? 'material';
    final String name = args['name'] as String? ?? 'Item';
    final bool isPositive = args['isPositive'] as bool? ?? true;
    final String? receipt = args['receipt'] as String?;
    final PickedAttachment? attachment =
        args['attachment'] as PickedAttachment?;
    final String createdBy = args['createdBy'] as String? ?? '';
    final String projectId = args['projectId'] as String? ?? '';
    final String supplier = args['supplier'] as String? ?? '';
    final String initialMethod = args['paymentMethod'] as String? ?? '';
    final String initialLastUpdated = args['lastUpdated'] as String? ?? date;

    final String method = _paymentHistory.isNotEmpty
        ? (_paymentHistory.last['method'] ??
              _paymentHistory.last['paymentMode'] ??
              initialMethod)
        : initialMethod;

    final String lastUpdated = _paymentHistory.isNotEmpty
        ? (_paymentHistory.last['date'] != null
              ? (() {
                  try {
                    final dt = DateTime.parse(
                      _paymentHistory.last['date'].toString(),
                    );
                    final months = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
                  } catch (_) {
                    return _paymentHistory.last['date'].toString();
                  }
                })()
              : initialLastUpdated)
        : initialLastUpdated;

    final bool canEdit = EntryPermissions.canEdit(
      status: _entryStatus.name,
      createdBy: createdBy,
      projectId: projectId,
    );
    final bool canDelete = EntryPermissions.canDelete(
      status: _entryStatus.name,
      createdBy: createdBy,
      projectId: projectId,
    );

    final double due = (_billAmount - _paidAmount).clamp(0.0, double.infinity);
    final bool canSettle =
        _payStatus == PaymentStatus.pending ||
        _payStatus == PaymentStatus.partial ||
        _payStatus == PaymentStatus.overdue;
    final bool isSettled = _payStatus == PaymentStatus.paid;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, type, args, canEdit, canDelete),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F8)),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TYPE BADGE + PAYMENT STATUS ─────────────────────────
                    Row(
                      children: [
                        _buildTypeBadge(type),
                        const SizedBox(width: 8),
                        PaymentStatusChip(status: _payStatus),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── ITEM HEADER ─────────────────────────────────────────
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
                          if (supplier.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  color: textGray,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  supplier,
                                  style: AppTheme.caption.copyWith(
                                    color: textGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── OPERATIONAL SUMMARY ─────────────────────────────────
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
                                    _fieldLabel('QUANTITY / VALUE'),
                                    const SizedBox(height: 6),
                                    Text(
                                      amount,
                                      style: TextStyle(
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
                          _fieldLabel('PURCHASE DATE'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              DateTime parsedInitial = DateTime.now();
                              try {
                                parsedInitial = DateTime.parse(args['date'].toString());
                              } catch (_) {
                                try {
                                  parsedInitial = DateTime.parse(date);
                                } catch (_) {}
                              }
                              
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: parsedInitial,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: _typeColor(type),
                                      onPrimary: Colors.white,
                                      onSurface: textDark,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              
                              if (picked != null && context.mounted) {
                                final success = await ApiService.updateTransaction(
                                  args['id'] as String? ?? '',
                                  {
                                    'date': picked.toIso8601String(),
                                  },
                                );
                                
                                if (success && context.mounted) {
                                  setState(() {
                                    _customDate = picked.toIso8601String();
                                    args['date'] = picked.toIso8601String();
                                  });
                                  
                                  context.read<InventoryProvider>().loadInventory(projectId);
                                  context.read<ProjectProvider>().load();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Date updated successfully'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to update date'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: _typeColor(type),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayDate,
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _typeColor(type).withValues(alpha: 0.4),
                                    decorationStyle: TextDecorationStyle.dashed,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  color: _typeColor(type).withValues(alpha: 0.6),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── SETTLEMENT SUMMARY ──────────────────────────────────
                    if (_billAmount > 0) ...[
                      _buildSettlementCard(
                        due: due,
                        method: method,
                        lastUpdated: lastUpdated,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── PAYMENT HISTORY ─────────────────────────────────────
                    _buildPaymentHistoryCard(),
                    if (_paymentHistory.isNotEmpty) const SizedBox(height: 14),

                    // ── INVOICE / BILL (uploaded at entry creation) ───────────
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('INVOICE / BILL'),
                          const SizedBox(height: 12),
                          InvoiceAttachmentCard(
                            attachment: attachment,
                            fileName: receipt,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── PAYMENT RECEIPT (uploaded via Fulfillment & Payment) ──
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('PAYMENT RECEIPT'),
                          const SizedBox(height: 12),
                          PaymentReceiptCard(fileName: _paymentReceiptFile),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── RECORD PAYMENT CTA ──────────────────────────────────
                    if (canSettle)
                      _buildRecordPaymentCTA(
                        context,
                        id: args['id'] as String? ?? '',
                        title: title,
                        ref: ref,
                        supplier: supplier,
                        type: type,
                      ),

                    // ── SETTLED CONFIRMATION ────────────────────────────────
                    if (isSettled) _buildSettledBadge(),

                    // ── DELETE ENTRY — secondary destructive action ──────────
                    if (canDelete) ...[
                      const SizedBox(height: 16),
                      _buildDeleteAction(context, id: args['id'] as String? ?? '', projectId: projectId),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(
    BuildContext context,
    String type,
    Map args,
    bool canEdit,
    bool canDelete,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
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
          if (canEdit)
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                _editRoute(type),
                arguments: {
                  ...args,
                  'isEditing': true,
                  'status': _entryStatus.name,
                },
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

  // ── TYPE BADGE ────────────────────────────────────────────────────────────
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

  // ── SETTLEMENT SUMMARY CARD ───────────────────────────────────────────────
  Widget _buildSettlementCard({
    required double due,
    required String method,
    required String lastUpdated,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SETTLEMENT SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textGray,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          _settlementRow(
            'Bill Amount',
            formatCurrency(_billAmount),
            color: textDark,
          ),
          const SizedBox(height: 10),
          _settlementRow(
            'Paid Amount',
            formatCurrency(_paidAmount),
            color: const Color(0xFF15803D),
          ),
          const SizedBox(height: 10),
          _settlementRow(
            'Due Amount',
            formatCurrency(due),
            color: due > 0 ? const Color(0xFFD97706) : const Color(0xFF15803D),
            bold: true,
          ),
          if (method.isNotEmpty || lastUpdated.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0F0F8)),
            ),
            if (method.isNotEmpty)
              _settlementRow('Payment Method', method, color: textDark),
            if (lastUpdated.isNotEmpty) ...[
              const SizedBox(height: 10),
              _settlementRow('Last Updated', lastUpdated, color: textGray),
            ],
          ],
        ],
      ),
    );
  }

  Widget _settlementRow(
    String label,
    String value, {
    Color color = textDark,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── RECORD PAYMENT CTA ────────────────────────────────────────────────────
  Widget _buildRecordPaymentCTA(
    BuildContext context, {
    required String id,
    required String title,
    required String ref,
    required String supplier,
    required String type,
  }) {
    final label = _payStatus == PaymentStatus.partial
        ? 'Settle Remaining Payment'
        : 'Record Payment';

    return GestureDetector(
      onTap: () {
        showPaymentSheet(
          context,
          entryTitle: title,
          entryRef: ref,
          totalAmount: _billAmount,
          alreadyPaid: _paidAmount,
          vendorName: supplier,
          category: type,
        ).then((result) async {
          if (result != null && mounted) {
            final paid = result['amount'] as double? ?? 0;
            final newStatus = result['status'] as PaymentStatus?;
            final receiptFile = result['receipt'] as String?;
            final customPaymentDate = result['paymentDate'] as DateTime? ?? DateTime.now();

            final totalPaid = _paidAmount + paid;
            final newStatusVal =
                newStatus ??
                (totalPaid >= _billAmount
                    ? PaymentStatus.paid
                    : PaymentStatus.partial);

            // Map paymentStatus enum back to standard Mongoose backend strings
            String newStatusStr = 'Pending';
            if (newStatusVal == PaymentStatus.paid) {
              newStatusStr = 'Paid';
            } else if (newStatusVal == PaymentStatus.partial) {
              newStatusStr = 'Partial';
            }

            // Sync payment update with the MongoDB database
            if (id.isNotEmpty) {
              String apiPaymentMode = result['method'] ?? '';
              if (apiPaymentMode == 'Bank Transfer' ||
                  apiPaymentMode == 'Card') {
                apiPaymentMode = 'Bank';
              }

              await ApiService.updateTransactionPayment(id, {
                'paymentStatus': newStatusStr,
                'paidAmount': totalPaid,
                'paymentMode': apiPaymentMode,
                'notes': result['note'] ?? '',
                'paymentDate': customPaymentDate.toIso8601String(),
              });
            }

            setState(() {
              _paidAmount = totalPaid;
              _payStatus = newStatusVal;
              _paymentHistory.add({
                'date': customPaymentDate.toIso8601String(),
                'method': result['method'] ?? 'Cash',
                'amount': paid,
                'note': result['note'] ?? '',
              });
              // Store payment receipt separately — never overwrites invoice
              if (receiptFile != null && receiptFile.isNotEmpty) {
                _paymentReceiptFile = receiptFile;
              }
            });
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B5CF6), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SETTLED BADGE ─────────────────────────────────────────────────────────
  Widget _buildSettledBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
          SizedBox(width: 8),
          Text(
            'Payment Settled',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    if (_paymentHistory.isEmpty) return const SizedBox.shrink();

    final reversedHistory = List.from(_paymentHistory.reversed);
    final displayedHistory = _viewAllPayments ? reversedHistory : [reversedHistory.first];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: textGray, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PAYMENT HISTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textGray,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (_paymentHistory.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewAllPayments = !_viewAllPayments;
                    });
                  },
                  child: Text(
                    _viewAllPayments ? 'View Less' : 'View All (${_paymentHistory.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedHistory.length,
            separatorBuilder: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF0F0F8)),
            ),
            itemBuilder: (context, index) {
              final item = displayedHistory[index] ?? {};

              // Parse date
              String formattedDate = 'Unknown Date';
              final rawDate = item['date'] ?? item['paymentDate'];
              if (rawDate != null) {
                try {
                  final dt = DateTime.parse(rawDate.toString());
                  // Simple human readable format: e.g. "19 May 2026"
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  formattedDate =
                      '${dt.day} ${months[dt.month - 1]} ${dt.year}';
                } catch (_) {
                  formattedDate = rawDate.toString();
                }
              }

              final double amt = (item['amount'] as num?)?.toDouble() ?? 0;
              final String method = item['method'] as String? ?? 'Cash';
              final String note = item['note'] as String? ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              method.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatCurrency(amt),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Note: $note',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: textGray,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── DELETE ACTION — low-emphasis secondary ────────────────────────────────
  Widget _buildDeleteAction(BuildContext context, {required String id, required String projectId}) {
    return GestureDetector(
      onTap: () => _showDeleteDialog(context, id: id, projectId: projectId),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.withValues(alpha: 0.65),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Delete Entry',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DELETE DIALOG ─────────────────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context, {required String id, required String projectId}) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (id.isNotEmpty) {
                final success = await ApiService.deleteTransaction(id);
                if (success && context.mounted) {
                  if (projectId.isNotEmpty) {
                    context.read<InventoryProvider>().loadInventory(projectId);
                  }
                  context.read<ProjectProvider>().load();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entry deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete entry'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
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
}
