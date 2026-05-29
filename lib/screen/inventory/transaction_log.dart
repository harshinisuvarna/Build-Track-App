import 'dart:convert';
import 'dart:developer' as dev;
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_permissions.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});
  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}

class _TransactionLogsScreenState extends State<TransactionLogsScreen> {
  static const primaryBlue = AppColors.primary;
  static const purple = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;
  int _filterIndex = 0;
  String _itemName = 'Item';
  String _itemType = 'material';
  bool _argsLoaded = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allLogs = [];
  bool _isGeneral = false;
  String? _filterProjectId;
  bool _hasPassedProject = false;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'labour':
        return const Color(0xFF2E7D32);
      case 'equipment':
        return const Color(0xFFE65100);
      default:
        return primaryBlue;
    }
  }

  Color _getCategoryBg(String category) {
    switch (category) {
      case 'labour':
        return const Color(0xFFE8F5E9);
      case 'equipment':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFEEF0FF);
    }
  }

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
          int.tryParse(
            l['amount']
                .toString()
                .replaceAll('+', '')
                .replaceAll('-', '')
                .trim(),
          ) ??
          0;
      return sum + v;
    });
  }

  int get _totalUsed {
    return _allLogs.where((l) => l['isPositive'] == false).fold(0, (sum, l) {
      final v =
          int.tryParse(
            l['amount']
                .toString()
                .replaceAll('+', '')
                .replaceAll('-', '')
                .trim(),
          ) ??
          0;
      return sum + v;
    });
  }

  Color _typeColor() => _getCategoryColor(_itemType);

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

  PaymentStatus _mapPaymentStatus(String? statusStr) {
    if (statusStr == null) return PaymentStatus.pending;
    final lower = statusStr.trim().toLowerCase();
    if (lower == 'paid') return PaymentStatus.paid;
    if (lower == 'partial') return PaymentStatus.partial;
    if (lower == 'overdue') return PaymentStatus.overdue;
    return PaymentStatus.pending;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Future<void> _fetchRealLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.get('/transactions');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw =
              (decoded['transactions'] ??
                      decoded['data'] ??
                      decoded['items'] ??
                      [])
                  as List<dynamic>;
        }

        final projectProvider = context.read<ProjectProvider>();
        final String? selectedProjId = _hasPassedProject
            ? _filterProjectId
            : projectProvider.selectedProject?.id;

        final List<Map<String, dynamic>> mappedList = [];
        for (final t in raw) {
          final String title = (t['title'] ?? t['materialName'] ?? 'Unknown')
              .toString();

          final String rawCat = (t['category'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final String rawType = (t['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          String category = 'material';
          if (rawCat == 'labour' ||
              rawCat == 'wages' ||
              rawCat == 'labor' ||
              rawCat.contains('labour') ||
              rawType == 'wages' ||
              rawType == 'labour') {
            category = 'labour';
          } else if (rawCat == 'equipment' ||
              rawCat == 'machinery' ||
              rawCat == 'expense' ||
              rawType == 'expense' ||
              rawType == 'equipment') {
            category = 'equipment';
          }

          String pId = '';
          if (t['project'] is Map) {
            pId = t['project']['_id']?.toString() ?? '';
          } else if (t['project'] != null) {
            pId = t['project'].toString();
          }
          if (pId.isEmpty && t['projectId'] != null) {
            if (t['projectId'] is Map) {
              pId = t['projectId']['_id']?.toString() ?? '';
            } else {
              pId = t['projectId'].toString();
            }
          }
          pId = pId.trim();
          if (pId.isEmpty) {
            pId = 'p1';
          }

          if (selectedProjId != null && selectedProjId.isNotEmpty) {
            if (pId != selectedProjId) continue;
          }

          if (!_isGeneral) {
            if (category != _itemType) continue;
            final String transactionItemName = (t['title'] ?? t['materialName'] ?? t['name'] ?? 'Unknown')
                .toString()
                .trim()
                .toLowerCase();
            if (transactionItemName != _itemName.trim().toLowerCase()) {
              continue;
            }
          }

          bool isPositive = true;
          if (t['subType']?.toString().toLowerCase() == 'consumption') {
            isPositive = false;
          }

          IconData icon = Icons.inventory_2_outlined;
          if (category == 'labour') {
            icon = Icons.people_outline;
          } else if (category == 'equipment') {
            icon = Icons.precision_manufacturing_outlined;
          }

          final String tId = t['_id']?.toString() ?? '';
          final String ref = tId.length > 4
              ? '#${tId.substring(tId.length - 4)}'
              : '#${tId.isNotEmpty ? tId : DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

          mappedList.add({
            'title': title,
            'ref': ref,
            'amount': '${isPositive ? "+" : "-"}${t['quantity'] ?? 0}',
            'date': _formatDate(t['date']),
            'isPositive': isPositive,
            'icon': icon,
            'receipt': (t['attachments'] is List && t['attachments'].isNotEmpty)
                ? t['attachments'].first?.toString()
                : null,
            'attachment':
                (t['attachments'] is List && t['attachments'].isNotEmpty)
                ? t['attachments'].first
                : null,
            'paymentStatus': _mapPaymentStatus(t['paymentStatus']),
            'billAmount': (t['amount'] ?? 0).toDouble(),
            'paidAmount': (t['paidAmount'] ?? 0).toDouble(),
            'supplier': t['supplier'] ?? '',
            'method': t['paymentMode'] ?? '',
            'lastUpdated': t['updatedAt'] != null
                ? _formatDate(t['updatedAt'])
                : _formatDate(t['date']),
            'projectId': pId,
            'createdBy': t['createdBy'] ?? '',
            'id': tId,
            'category': category,
            'unit': t['unit']?.toString(),
            'paymentHistory': t['paymentHistory'],
            'rate': (t['rate'] ?? 0).toDouble(),
            'brand': t['brand'] ?? '',
            'notes': t['notes'] ?? '',
            'remarks': t['remarks'] ?? '',
            'categoryName': t['category'] ?? '',
            'quantity': (t['quantity'] ?? 0).toDouble(),
            'subType': t['subType'] ?? '',
            'materialType': t['materialType'] ?? '',
          });
        }

        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map) {
          final newEntry = args['newEntry'] as Map<String, dynamic>?;
          if (newEntry != null) {
            final alreadyExists = mappedList.any(
              (l) => l['ref'] == newEntry['ref'] || l['id'] == newEntry['id'],
            );
            if (!alreadyExists) {
              mappedList.insert(0, newEntry);
            }
          }
        }

        setState(() {
          _allLogs = mappedList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      dev.log('Error fetching logs', error: e, stackTrace: stack);
      setState(() {
        _isLoading = false;
      });
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
      if (name != null && name.isNotEmpty) {
        _itemName = name;
        _isGeneral = false;
      } else {
        _itemName = 'Project Logs';
        _isGeneral = true;
      }
      if (type != null && type.isNotEmpty) {
        _itemType = type;
      }
      if (args.containsKey('projectId')) {
        _filterProjectId = args['projectId'] as String?;
        _hasPassedProject = true;
      }
    } else {
      _itemName = 'Project Logs';
      _isGeneral = true;
    }

    _fetchRealLogs();
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
                    if (!_isGeneral) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 14),
                      _buildPaymentStatusStrip(),
                      const SizedBox(height: 20),
                    ],
                    _buildLogsHeader(),
                    const SizedBox(height: 14),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryBlue,
                                ),
                              ),
                            ),
                          )
                        : _filteredLogs.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: _filteredLogs
                                .map(
                                  (log) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _logItem(context, log),
                                  ),
                                )
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
          Text(
            'TOTAL ${_itemType.toUpperCase()} STOCK',
            style: AppTheme.label.copyWith(
              color: textGray,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
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
                    height: 1,
                  ),
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
                  Icons.add_circle_outline,
                  '+$_totalAdded Added',
                  color,
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFCDD0FF)),
              Expanded(
                child: _summaryBadge(
                  Icons.remove_circle_outline,
                  '-$_totalUsed Used',
                  const Color(0xFFE040FB),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFCDD0FF)),
              Expanded(
                child: _summaryBadge(
                  Icons.balance_outlined,
                  'Net $net',
                  purple,
                ),
              ),
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
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  } // ─── Payment Status Strip ──────────────────────────────────────────────────

  Widget _buildPaymentStatusStrip() {
    int fullyPaid = 0, partial = 0, notPaid = 0;
    double fullyPaidTotal = 0, partialTotal = 0, notPaidTotal = 0;

    for (final l in _allLogs) {
      final ps = l['paymentStatus'] as PaymentStatus?;
      final bill = l['billAmount'] as double? ?? 0;
      if (ps == PaymentStatus.paid) {
        fullyPaid++;
        fullyPaidTotal += bill;
      } else if (ps == PaymentStatus.partial) {
        partial++;
        partialTotal += bill;
      } else {
        notPaid++;
        notPaidTotal += bill;
      }
    }

    Widget card(
      String label,
      int count,
      double total,
      Color dot,
      Color bg,
      Color border,
    ) {
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
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: dot,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count item${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    formatCurrency(total),
                    style: TextStyle(
                      color: dot,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          'Fully Paid',
          fullyPaid,
          fullyPaidTotal,
          const Color(0xFF15803D),
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
        ),
        const SizedBox(width: 8),
        card(
          'Partial',
          partial,
          partialTotal,
          const Color(0xFFB45309),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
        ),
        const SizedBox(width: 8),
        card(
          'Not Paid',
          notPaid,
          notPaidTotal,
          const Color(0xFFDC2626),
          const Color(0xFFFFF5F5),
          const Color(0xFFFECACA),
        ),
      ],
    );
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
              Text(
                'Movement Logs',
                style: AppTheme.heading3.copyWith(color: textDark),
              ),
              const SizedBox(height: 2),
              Text(
                'Tracking historical distribution',
                style: AppTheme.caption.copyWith(color: textGray),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? primaryBlue : const Color(0xFFDDE0F0),
                    ),
                  ),
                  child: Text(
                    filters[i],
                    style: TextStyle(
                      color: sel ? Colors.white : textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: textGray,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No entries yet',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Entries you add will appear here',
              style: AppTheme.caption.copyWith(color: textGray),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLogAmount(Map<String, dynamic> log) {
    final String amountStr = log['amount'] as String? ?? '';
    if (amountStr.isEmpty) return '';

    final String sign = amountStr.startsWith('+')
        ? '+'
        : (amountStr.startsWith('-') ? '-' : '');
    final String numStr = amountStr
        .replaceAll('+', '')
        .replaceAll('-', '')
        .trim();
    final double qty = double.tryParse(numStr) ?? 0;
    final String qtyFormatted = qty % 1 == 0
        ? qty.toInt().toString()
        : qty.toString();

    final String rawUnit = (log['unit'] ?? '').toString().trim().toLowerCase();
    final String logCategory = log['category'] as String? ?? _itemType;

    // Safety check: Filter out legacy invalid weight/material units for Labour/Equipment
    final bool isInvalidUnit = const [
      'kg',
      'bag',
      'ton',
      'mt',
      'truck',
    ].contains(rawUnit);
    final String parsedUnit =
        (isInvalidUnit &&
            (logCategory == 'labour' || logCategory == 'equipment'))
        ? ''
        : rawUnit;

    if (logCategory == 'labour') {
      String unitLabel = 'workers';
      if (parsedUnit == 'hour' || parsedUnit == 'hours') {
        unitLabel = qty == 1 ? 'hour' : 'hours';
      } else if (parsedUnit == 'day' || parsedUnit == 'days') {
        unitLabel = qty == 1 ? 'day' : 'days';
      } else if (parsedUnit == 'worker' ||
          parsedUnit == 'workers' ||
          parsedUnit.isEmpty) {
        unitLabel = qty == 1 ? 'worker' : 'workers';
      } else {
        unitLabel = parsedUnit;
      }
      return '$sign$qtyFormatted $unitLabel';
    } else if (logCategory == 'equipment') {
      String unitLabel = 'units';
      if (parsedUnit == 'hour' || parsedUnit == 'hours') {
        unitLabel = qty == 1 ? 'hour' : 'hours';
      } else if (parsedUnit == 'day' || parsedUnit == 'days') {
        unitLabel = qty == 1 ? 'day' : 'days';
      } else if (parsedUnit.isNotEmpty) {
        unitLabel = parsedUnit;
      }
      return '$sign$qtyFormatted $unitLabel';
    } else {
      // Material
      if (parsedUnit.isEmpty || parsedUnit == 'unit' || parsedUnit == 'units') {
        return '$sign$qtyFormatted units';
      }
      String unitLabel = parsedUnit;
      if (qty > 1) {
        if (parsedUnit == 'bag') {
          unitLabel = 'bags';
        } else if (parsedUnit == 'ton') {
          unitLabel = 'tons';
        } else if (parsedUnit == 'truck') {
          unitLabel = 'trucks';
        } else if (parsedUnit == 'block') {
          unitLabel = 'blocks';
        }
      }
      return '$sign$qtyFormatted $unitLabel';
    }
  }

  Widget _logItem(BuildContext context, Map<String, dynamic> log) {
    final isPositive = log['isPositive'] as bool? ?? true;
    final receipt = log['receipt'] as String?;
    final payStatus =
        log['paymentStatus'] as PaymentStatus? ?? PaymentStatus.pending;
    final billAmt = log['billAmount'] as double? ?? 0;
    final paidAmt = log['paidAmount'] as double? ?? 0;
    final canSettle =
        payStatus == PaymentStatus.pending ||
        payStatus == PaymentStatus.partial ||
        payStatus == PaymentStatus.overdue;

    final logCategory = log['category'] as String? ?? _itemType;
    final iconColor = _getCategoryColor(logCategory);
    final iconBg = _getCategoryBg(logCategory);
    final accent = isPositive ? primaryBlue : const Color(0xFFE040FB);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            Navigator.pushNamed(
              context,
              '/entry-detail',
              arguments: {
                'id': log['id'],
                'title': log['title'],
                'ref': log['ref'],
                'amount': log['amount'],
                'date': log['date'],
                'isPositive': isPositive,
                'type': logCategory,
                'name': log['title'] ?? _itemName,
                'receipt': receipt,
                'attachment': log['attachment'],
                'createdBy': log['createdBy'] ?? '',
                'projectId': log['projectId'] ?? '',
                'status': log['status'] ?? 'pending',
                // payment lifecycle fields
                'paymentStatus': payStatus,
                'billAmount': billAmt,
                'paidAmount': paidAmt,
                'supplier': log['supplier'] ?? '',
                'paymentMethod': log['method'] ?? '',
                'lastUpdated': log['lastUpdated'] ?? log['date'] ?? '',
                'paymentHistory': log['paymentHistory'],
              },
            ).then((_) {
              _fetchRealLogs();
            }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accent, width: 3.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
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
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
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
                        _formatLogAmount(log),
                        style: TextStyle(
                          color: isPositive
                              ? primaryBlue
                              : const Color(0xFF9C6AAB), // Muted purple
                          fontWeight: FontWeight.w600, // Semi-bold
                          fontSize: 15,
                        ), // Smaller size
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log['date'] as String? ?? '',
                        style: AppTheme.caption.copyWith(color: textGray),
                      ),
                      if (receipt != null && receipt.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.attach_file,
                            color: textGray,
                            size: 12,
                          ),
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
                          color: textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: canSettle
                        ? () {
                            showPaymentSheet(
                              context,
                              entryTitle: log['title'] as String? ?? '',
                              entryRef: log['ref'] as String? ?? '',
                              totalAmount: billAmt,
                              alreadyPaid: paidAmt,
                              vendorName: log['supplier'] as String? ?? '',
                              category: logCategory,
                            ).then((result) async {
                              if (result != null && mounted) {
                                final paid = result['amount'] as double;
                                final newStatus =
                                    result['status'] as PaymentStatus?;
                                final totalPaid = (paidAmt + paid).clamp(
                                  0.0,
                                  double.infinity,
                                );
                                final customPaymentDate = result['paymentDate'] as DateTime? ?? DateTime.now();

                                // Convert enum to Mongoose capitalized string
                                final newStatusStr =
                                    newStatus == PaymentStatus.paid
                                    ? 'Paid'
                                    : newStatus == PaymentStatus.partial
                                    ? 'Partial'
                                    : 'Pending';

                                String apiPaymentMode = result['method'] ?? '';
                                if (apiPaymentMode == 'Bank Transfer' ||
                                    apiPaymentMode == 'Card') {
                                  apiPaymentMode = 'Bank';
                                }

                                final success =
                                    await ApiService.updateTransactionPayment(
                                      log['id'] as String? ?? '',
                                      {
                                        'paymentStatus': newStatusStr,
                                        'paidAmount': totalPaid,
                                        'paymentMode': apiPaymentMode,
                                        'notes': result['note'] ?? '',
                                        'paymentDate': customPaymentDate.toIso8601String(),
                                      },
                                    );

                                if (success && mounted) {
                                  setState(() {
                                    log['paidAmount'] = totalPaid;
                                    log['paymentStatus'] =
                                        newStatus ??
                                        (totalPaid >= billAmt
                                            ? PaymentStatus.paid
                                            : PaymentStatus.partial);
                                  });

                                  context.read<ProjectProvider>().load();

                                  if (paid > 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${formatCurrency(paid)} recorded via ${result['method']}',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF173EEA,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Failed to update payment on server',
                                      ),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: canSettle
                            ? Colors.white
                            : const Color(0xFFF5F5F5),
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
                            color: canSettle
                                ? primaryBlue
                                : const Color(0xFF9CA3AF),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            canSettle ? 'Record Payment' : 'Settled',
                            style: TextStyle(
                              color: canSettle
                                  ? primaryBlue
                                  : const Color(0xFF9CA3AF),
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