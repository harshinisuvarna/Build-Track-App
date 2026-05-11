import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_permissions.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});
  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}
class _TransactionLogsScreenState extends State<TransactionLogsScreen> {

  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;
  int _filterIndex = 0;
  String _itemName = 'Item';
  String _itemType = 'material';
  bool _argsLoaded = false;
  final List<Map<String, dynamic>> _allLogs = [
    {
      'title': 'Stock Replenishment',
      'ref': '#INV-9921',
      'amount': '+450',
      'date': 'Oct 24, 2023',
      'isPositive': true,
      'icon': Icons.local_shipping_outlined,
      'receipt': 'receipt_9921.pdf',
      'paymentStatus': PaymentStatus.paid,
      'billAmount': 45000.0,
      'paidAmount': 45000.0,
    },
    {
      'title': 'Slab Pouring - Block B',
      'ref': '#INV-9884',
      'amount': '-120',
      'date': 'Oct 22, 2023',
      'isPositive': false,
      'icon': Icons.home_work_outlined,
      'receipt': null,
      'paymentStatus': PaymentStatus.pending,
      'billAmount': 28000.0,
      'paidAmount': 0.0,
    },
    {
      'title': 'Column Reinforcement',
      'ref': '#INV-9851',
      'amount': '-45',
      'date': 'Oct 20, 2023',
      'isPositive': false,
      'icon': Icons.architecture,
      'receipt': null,
      'paymentStatus': PaymentStatus.partial,
      'billAmount': 18500.0,
      'paidAmount': 9000.0,
    },
    {
      'title': 'Stock Replenishment',
      'ref': '#INV-9820',
      'amount': '+200',
      'date': 'Oct 18, 2023',
      'isPositive': true,
      'icon': Icons.local_shipping_outlined,
      'receipt': 'receipt_9820.pdf',
      'paymentStatus': PaymentStatus.paid,
      'billAmount': 32000.0,
      'paidAmount': 32000.0,
    },
    {
      'title': 'Foundation Work',
      'ref': '#INV-9799',
      'amount': '-85',
      'date': 'Oct 15, 2023',
      'isPositive': false,
      'icon': Icons.construction_outlined,
      'receipt': null,
      'paymentStatus': PaymentStatus.overdue,
      'billAmount': 62000.0,
      'paidAmount': 0.0,
    },
    {
      'title': 'Emergency Restock',
      'ref': '#INV-9780',
      'amount': '+300',
      'date': 'Oct 12, 2023',
      'isPositive': true,
      'icon': Icons.local_shipping_outlined,
      'receipt': 'receipt_9780.pdf',
      'paymentStatus': PaymentStatus.paid,
      'billAmount': 55000.0,
      'paidAmount': 55000.0,
    },
  ];

  List<Map<String, dynamic>> get _filteredLogs {
    // Role-based visibility filter
    final visible = EntryPermissions.filterMaps(_allLogs);
    switch (_filterIndex) {
      case 1:
        return visible.where((l) => l['isPositive'] == true).toList();
      case 2:
        return visible.where((l) => l['isPositive'] == false).toList();
      default:
        return List.from(visible);
    }
  }

  int get _totalAdded {
    return _allLogs.where((l) => l['isPositive'] == true).fold(0, (sum, l) {
      final v =
          int.tryParse(l['amount'].toString().replaceAll('+', '').trim()) ?? 0;
      return sum + v;
    });
  }

  int get _totalUsed {
    return _allLogs.where((l) => l['isPositive'] == false).fold(0, (sum, l) {
      final v =
          int.tryParse(l['amount'].toString().replaceAll('-', '').trim()) ?? 0;
      return sum + v;
    });
  }

  Color _typeColor() {
    switch (_itemType) {
      case 'labour':
        return const Color(0xFF2E7D32);
      case 'equipment':
        return const Color(0xFFE65100);
      default:
        return primaryBlue;
    }
  }

  Color _typeBg() {
    switch (_itemType) {
      case 'labour':
        return const Color(0xFFE8F5E9);
      case 'equipment':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEEF0FF);
    }
  }

  IconData _typeIcon() {
    switch (_itemType) {
      case 'labour':
        return Icons.people_outline;
      case 'equipment':
        return Icons.construction_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String get _unitLabel {
    switch (_itemType) {
      case 'labour':
        return 'workers';
      case 'equipment':
        return 'hrs';
      default:
        return 'units';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final name = args['name'] as String?;
      final type = args['type'] as String?;
      if (name != null) _itemName = name;
      if (type != null) _itemType = type;

      final newEntry = args['newEntry'] as Map<String, dynamic>?;
      if (newEntry != null) {
        final entry = Map<String, dynamic>.from(newEntry);
        entry['icon'] ??= _typeIcon();
        final alreadyExists = _allLogs.any((l) => l['ref'] == entry['ref']);
        if (!alreadyExists) {
          setState(() => _allLogs.insert(0, entry));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: _itemName,
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F8)),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 14),
                    _buildPaymentStatusStrip(),
                    const SizedBox(height: 20),
                    _buildLogsHeader(),
                    const SizedBox(height: 14),
                    _filteredLogs.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: _filteredLogs
                                .map((log) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _logItem(context, log),
                                    ))
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final net = _totalAdded - _totalUsed;
    final color = _typeColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEEFFF), Color(0xFFF5F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCDD0FF), width: 2),
      ),
      child: Column(
        children: [
          Text('TOTAL ${_itemType.toUpperCase()} STOCK',
              style: AppTheme.label.copyWith(
                  color: textGray, fontSize: 11, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$net',
                  style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryPurple,
                      letterSpacing: -2,
                      height: 1),
                ),
                TextSpan(
                  text: '  $_unitLabel',
                  style: AppTheme.bodyLarge.copyWith(color: textGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _summaryBadge(
                      Icons.add_circle_outline, '+$_totalAdded Added', color)),
              Container(
                  width: 1, height: 28, color: const Color(0xFFCDD0FF)),
              Expanded(
                  child: _summaryBadge(Icons.remove_circle_outline,
                      '-$_totalUsed Used', const Color(0xFFE040FB))),
              Container(
                  width: 1, height: 28, color: const Color(0xFFCDD0FF)),
              Expanded(
                  child: _summaryBadge(
                      Icons.balance_outlined, 'Net $net', purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.2),
          ),
        ),
      ],
    );
  }  // ─── Payment Status Strip ──────────────────────────────────────────────────
  Widget _buildPaymentStatusStrip() {
    int fullyPaid = 0, partial = 0, notPaid = 0;
    double fullyPaidTotal = 0, partialTotal = 0, notPaidTotal = 0;

    for (final l in _allLogs) {
      final ps   = l['paymentStatus'] as PaymentStatus?;
      final bill = l['billAmount']    as double? ?? 0;
      if (ps == PaymentStatus.paid) {
        fullyPaid++;  fullyPaidTotal += bill;
      } else if (ps == PaymentStatus.partial) {
        partial++;    partialTotal   += bill;
      } else {
        notPaid++;    notPaidTotal   += bill;
      }
    }


    Widget card(String label, int count, double total,
        Color dot, Color bg, Color border) {
      return Expanded(
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: dot,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2)),
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count item${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  const SizedBox(height: 1),
                  Text(formatCurrency(total),
                      style: TextStyle(
                          color: dot,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Row(children: [
      card('Fully Paid', fullyPaid, fullyPaidTotal,
          const Color(0xFF15803D), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
      const SizedBox(width: 8),
      card('Partial', partial, partialTotal,
          const Color(0xFFB45309), const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
      const SizedBox(width: 8),
      card('Not Paid', notPaid, notPaidTotal,
          const Color(0xFFDC2626), const Color(0xFFFFF5F5), const Color(0xFFFECACA)),
    ]);
  }

  Widget _buildLogsHeader() {
    const filters = ['All', '+ Added', '- Used'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Movement Logs',
                  style: AppTheme.heading3.copyWith(color: textDark)),
              const SizedBox(height: 2),
              Text('Tracking historical distribution',
                  style: AppTheme.caption.copyWith(color: textGray)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(filters.length, (i) {
            final sel = i == _filterIndex;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _filterIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? primaryBlue
                            : const Color(0xFFDDE0F0)),
                  ),
                  child: Text(filters[i],
                      style: TextStyle(
                          color: sel ? Colors.white : textGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.receipt_long_outlined,
                  color: textGray, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No entries yet',
                style: AppTheme.bodyLarge
                    .copyWith(fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 6),
            Text('Entries you add will appear here',
                style: AppTheme.caption.copyWith(color: textGray)),
          ],
        ),
      ),
    );
  }

  Widget _logItem(BuildContext context, Map<String, dynamic> log) {
    final isPositive = log['isPositive'] as bool? ?? true;
    final receipt = log['receipt'] as String?;
    final payStatus = log['paymentStatus'] as PaymentStatus? ?? PaymentStatus.pending;
    final billAmt  = log['billAmount']  as double? ?? 0;
    final paidAmt  = log['paidAmount']  as double? ?? 0;
    final canSettle = payStatus == PaymentStatus.pending ||
        payStatus == PaymentStatus.partial ||
        payStatus == PaymentStatus.overdue;

    final iconColor = _typeColor();
    final iconBg = _typeBg();
    final accent = isPositive ? primaryBlue : const Color(0xFFE040FB);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(
          context,
          '/entry-detail',
          arguments: {
            'title':         log['title'],
            'ref':           log['ref'],
            'amount':        log['amount'],
            'date':          log['date'],
            'isPositive':    isPositive,
            'type':          _itemType,
            'name':          _itemName,
            'receipt':       receipt,
            'createdBy':     log['createdBy'] ?? '',
            'projectId':     log['projectId'] ?? '',
            'status':        log['status'] ?? 'pending',
            // payment lifecycle fields
            'paymentStatus': payStatus,
            'billAmount':    billAmt,
            'paidAmount':    paidAmt,
            'supplier':      log['supplier'] ?? '',
            'paymentMethod': log['method'] ?? '',
            'lastUpdated':   log['lastUpdated'] ?? log['date'] ?? '',
          },
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accent, width: 3.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      (log['icon'] as IconData?) ?? _typeIcon(),
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['title'] as String? ?? '',
                          style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700, color: textDark),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$_itemName • ${log['ref'] ?? ''}',
                          style: AppTheme.caption.copyWith(color: textGray),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log['amount'] as String? ?? '',
                        style: TextStyle(
                            color: isPositive
                                ? primaryBlue
                                : const Color(0xFF9C6AAB), // Muted purple
                            fontWeight: FontWeight.w600, // Semi-bold
                            fontSize: 15), // Smaller size
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log['date'] as String? ?? '',
                        style: AppTheme.caption.copyWith(color: textGray),
                      ),
                      if (receipt != null && receipt.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.attach_file, color: textGray, size: 12),
                        ),
                    ],
                  ),
                ],
              ),
              // ── Payment footer row ─────────────────────────────────────────
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0EEF8)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PaymentStatusChip(status: payStatus),
                  const SizedBox(width: 6),
                  if (billAmt > 0)
                    Flexible(
                      child: Text(
                        '${formatCurrency(paidAmt)} paid / ${formatCurrency(billAmt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption.copyWith(
                            color: textGray, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: canSettle ? () {
                      showPaymentSheet(
                        context,
                        entryTitle: log['title'] as String? ?? '',
                        entryRef: log['ref'] as String? ?? '',
                        totalAmount: billAmt,
                        alreadyPaid: paidAmt,
                        vendorName: log['supplier'] as String? ?? '',
                        category: _itemType,
                      ).then((result) {
                        if (result != null && mounted) {
                          final paid = result['amount'] as double;
                          final newStatus = result['status'] as PaymentStatus?;
                          setState(() {
                            log['paidAmount'] = (paidAmt + paid).clamp(0.0, double.infinity);
                            log['paymentStatus'] = newStatus ??
                                ((paidAmt + paid) >= billAmt
                                    ? PaymentStatus.paid
                                    : PaymentStatus.partial);
                          });
                          if (paid > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${formatCurrency(paid)} recorded via ${result['method']}'),
                              backgroundColor: const Color(0xFF173EEA),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        }
                      });
                    } : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: canSettle ? Colors.white : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canSettle
                              ? primaryBlue
                              : const Color(0xFFDDE0F0),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            canSettle
                                ? Icons.receipt_long_outlined
                                : Icons.check_circle_outline,
                            color: canSettle ? primaryBlue : const Color(0xFF9CA3AF),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            canSettle ? 'Record Payment' : 'Settled',
                            style: TextStyle(
                              color: canSettle ? primaryBlue : const Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
