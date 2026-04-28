import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_permissions.dart';
import 'package:flutter/material.dart';

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
    },
    {
      'title': 'Slab Pouring - Block B',
      'ref': '#INV-9884',
      'amount': '-120',
      'date': 'Oct 22, 2023',
      'isPositive': false,
      'icon': Icons.home_work_outlined,
      'receipt': null,
    },
    {
      'title': 'Column Reinforcement',
      'ref': '#INV-9851',
      'amount': '-45',
      'date': 'Oct 20, 2023',
      'isPositive': false,
      'icon': Icons.architecture,
      'receipt': null,
    },
    {
      'title': 'Stock Replenishment',
      'ref': '#INV-9820',
      'amount': '+200',
      'date': 'Oct 18, 2023',
      'isPositive': true,
      'icon': Icons.local_shipping_outlined,
      'receipt': 'receipt_9820.pdf',
    },
    {
      'title': 'Foundation Work',
      'ref': '#INV-9799',
      'amount': '-85',
      'date': 'Oct 15, 2023',
      'isPositive': false,
      'icon': Icons.construction_outlined,
      'receipt': null,
    },
    {
      'title': 'Emergency Restock',
      'ref': '#INV-9780',
      'amount': '+300',
      'date': 'Oct 12, 2023',
      'isPositive': true,
      'icon': Icons.local_shipping_outlined,
      'receipt': 'receipt_9780.pdf',
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
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, color: textDark, size: 22),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade800,
                    child: const Text('N',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ],
              ),
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
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$net',
                  style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5B3FE0),
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
        const SizedBox(width: 5),
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
            'title': log['title'],
            'ref': log['ref'],
            'amount': log['amount'],
            'date': log['date'],
            'isPositive': isPositive,
            'type': _itemType,
            'name': _itemName,
            'receipt': receipt,
            'createdBy': log['createdBy'] ?? '',
            'projectId': log['projectId'] ?? '',
            'status': log['status'] ?? 'pending',
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
          child: Row(
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
                            : const Color(0xFFE040FB),
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log['date'] as String? ?? '',
                    style: AppTheme.caption.copyWith(color: textGray),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: log['status'] as String? ?? 'pending'),
                  if (receipt != null && receipt.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.attach_file, color: textGray, size: 12),
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