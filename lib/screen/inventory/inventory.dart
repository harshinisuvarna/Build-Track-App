import 'dart:async';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/models/inventory_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// INVENTORY SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _blue   = AppColors.primary;
  static const _bg     = AppColors.gradientStart;
  static const _dark   = AppColors.textDark;
  static const _gray   = AppColors.textLight;

  // ── Page state ────────────────────────────────────────────────────────────
  final _pageController = PageController();
  int    _tabIndex = 0;
  final  _searchCtrl = TextEditingController();
  String _activeFilter = 'Recently Added';
  String? _selectedProjectId;
  Timer? _debounce;

  // ── Per-tab category filters ───────────────────────────────────────────────
  String _matCategory = 'All';
  String _labCategory = 'All';
  String _eqpCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory(_selectedProjectId ?? '');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DATA HELPERS — all computed locally, no new API calls
  // ════════════════════════════════════════════════════════════════════════════

  Map<String, dynamic>? _firstTx(InventoryItem item) {
    if (item.transactions.isEmpty) return null;
    final t = item.transactions.first;
    if (t is Map<String, dynamic>) return t;
    if (t is Map) return Map<String, dynamic>.from(t);
    return null;
  }

  String _vendor(InventoryItem item) {
    for (final raw in item.transactions) {
      final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (tx == null) continue;
      final s = (tx['supplier'] ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  double _rate(InventoryItem item) {
    final tx = _firstTx(item);
    if (tx == null) return 0;
    final r = tx['rate'];
    return r is num ? r.toDouble() : 0;
  }

  double _totalValue(InventoryItem item) {
    double total = 0;
    for (final raw in item.transactions) {
      final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (tx == null) continue;
      final qty  = tx['quantity'];
      final rate = tx['rate'];
      if (qty is num && rate is num) total += (qty * rate).toDouble();
    }
    // Fallback: closing stock × rate
    if (total == 0 && _rate(item) > 0) {
      total = item.closingStock * _rate(item);
    }
    return total;
  }

  PaymentStatus _payStatus(InventoryItem item) {
    if (item.transactions.isEmpty) return PaymentStatus.pending;
    int pending = 0, partial = 0;
    for (final raw in item.transactions) {
      final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final s   = tx != null ? (tx['paymentStatus'] ?? '').toString().toLowerCase().trim() : '';
      if (s == 'partial') {
        partial++;
      } else if (s != 'paid') {
        pending++;
      }
    }
    if (pending > 0) return PaymentStatus.pending;
    if (partial > 0) return PaymentStatus.partial;
    return PaymentStatus.paid;
  }

  double _pendingAmt(List<InventoryItem> items) {
    double total = 0;
    for (final item in items) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        final s = (tx['paymentStatus'] ?? '').toString().toLowerCase().trim();
        if (s != 'paid') {
          final b = (tx['amount'] is num) ? (tx['amount'] as num).toDouble() : 0.0;
          final p = (tx['paidAmount'] is num) ? (tx['paidAmount'] as num).toDouble() : 0.0;
          total += (b - p).clamp(0.0, double.infinity);
        }
      }
    }
    return total;
  }

  double _inventoryValue(List<InventoryItem> items) =>
      items.fold(0.0, (s, i) => s + _totalValue(i));

  int _distinctVendors(List<InventoryItem> items) {
    final set = <String>{};
    for (final item in items) {
      final v = _vendor(item);
      if (v.isNotEmpty) set.add(v.toLowerCase());
    }
    return set.length;
  }

  int _rentalsCount(List<InventoryItem> items) {
    int count = 0;
    for (final item in items) {
      bool isRental = item.name.toLowerCase().contains('rent') ||
          item.unit.toLowerCase().contains('rent');
      if (!isRental) {
        for (final raw in item.transactions) {
          final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
          if (tx == null) continue;
          final notes = (tx['notes'] ?? '').toString().toLowerCase();
          final remarks = (tx['remarks'] ?? '').toString().toLowerCase();
          final brand = (tx['brand'] ?? '').toString().toLowerCase();
          if (notes.contains('rent') || remarks.contains('rent') || brand.contains('rent')) {
            isRental = true;
            break;
          }
        }
      }
      if (isRental) count++;
    }
    return count;
  }

  double _rentalCost(List<InventoryItem> items) {
    double total = 0;
    for (final item in items) {
      bool isRental = item.name.toLowerCase().contains('rent') ||
          item.unit.toLowerCase().contains('rent');
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        final notes = (tx['notes'] ?? '').toString().toLowerCase();
        final remarks = (tx['remarks'] ?? '').toString().toLowerCase();
        final brand = (tx['brand'] ?? '').toString().toLowerCase();
        if (notes.contains('rent') || remarks.contains('rent') || brand.contains('rent')) {
          isRental = true;
        }
        if (isRental) {
          final qty = tx['quantity'];
          final rate = tx['rate'];
          if (qty is num && rate is num) {
            total += (qty * rate).toDouble();
          }
        }
      }
    }
    return total;
  }

  double _paidAmt(List<InventoryItem> items) {
    double total = 0;
    for (final item in items) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        final p = (tx['paidAmount'] is num) ? (tx['paidAmount'] as num).toDouble() : 0.0;
        total += p;
      }
    }
    return total;
  }

  double _maintenanceCost(List<InventoryItem> items) {
    double total = 0;
    for (final item in items) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        final notes = (tx['notes'] ?? '').toString().toLowerCase();
        final remarks = (tx['remarks'] ?? '').toString().toLowerCase();
        final name = (tx['title'] ?? '').toString().toLowerCase();
        if (notes.contains('maint') || notes.contains('repair') || 
            remarks.contains('maint') || remarks.contains('repair') ||
            name.contains('maint') || name.contains('repair')) {
          final qty = tx['quantity'];
          final rate = tx['rate'];
          if (qty is num && rate is num) {
            total += (qty * rate).toDouble();
          }
        }
      }
    }
    return total;
  }

  List<String> _buildCategories(List<InventoryItem> items) {
    final cats = <String>{};
    for (final item in items) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        for (final key in ['categoryName', 'materialType']) {
          final v = (tx[key] ?? '').toString().trim();
          if (v.isNotEmpty &&
              !['unknown', 'material', 'labour', 'equipment', 'materials']
                  .contains(v.toLowerCase())) {
            cats.add(v);
            break;
          }
        }
      }
    }
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  List<InventoryItem> _applyCategory(List<InventoryItem> items, String cat) {
    if (cat == 'All') return items;
    return items.where((item) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx == null) continue;
        for (final key in ['categoryName', 'materialType']) {
          if ((tx[key] ?? '').toString().trim() == cat) return true;
        }
      }
      return false;
    }).toList();
  }

  List<InventoryItem> _applySort(List<InventoryItem> items) {
    final copy = List<InventoryItem>.from(items);
    if (_activeFilter == 'A → Z') {
      copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_activeFilter == 'Low Stock') {
      copy.sort((a, b) {
        final la = a.closingStock < a.threshold ? 0 : 1;
        final lb = b.closingStock < b.threshold ? 0 : 1;
        return la.compareTo(lb);
      });
    } else {
      copy.sort((a, b) {
        int ta = 0, tb = 0;
        if (a.id.length == 24) {
          try { ta = int.parse(a.id.substring(0, 8), radix: 16); } catch (_) {}
        }
        if (b.id.length == 24) {
          try { tb = int.parse(b.id.substring(0, 8), radix: 16); } catch (_) {}
        }
        return tb.compareTo(ta);
      });
    }
    return copy;
  }

  String _selectedProjectName() {
    if (_selectedProjectId == null) return '';
    final projects = context.read<ProjectProvider>().projects;
    return projects
        .cast<ProjectModel?>()
        .firstWhere((p) => p?.id == _selectedProjectId, orElse: () => null)
        ?.name ?? '';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PROJECT SELECTOR
  // ════════════════════════════════════════════════════════════════════════════

  void _showProjectSelector(BuildContext context) {
    final projects = context.read<ProjectProvider>().projects;
    final allItems = ['All Active Projects', ...projects.map((p) => p.name)];
    final idMap = <String, String?>{
      for (final p in projects) p.name: p.id,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProjectSelectorSheet(
        allItems: allItems,
        idMap: idMap,
        selectedId: _selectedProjectId,
        onSelect: (id) {
          setState(() => _selectedProjectId = id);
          context.read<InventoryProvider>().loadInventory(id ?? '');
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Inventory',
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      children: [
                        _buildProjectSelector(),
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 10),
                        _buildTabs(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _tabIndex = i),
                      children: [
                        _buildMaterialsTab(context),
                        _buildLabourTab(context),
                        _buildEquipmentTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  // ── Project selector ──────────────────────────────────────────────────────

  Widget _buildProjectSelector() {
    final projects = context.watch<ProjectProvider>().projects;
    final sel = _selectedProjectId == null
        ? null
        : projects.cast<ProjectModel?>().firstWhere(
            (p) => p?.id == _selectedProjectId, orElse: () => null);
    final label = sel?.name ?? 'All Active Projects';

    return GestureDetector(
      onTap: () => _showProjectSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E5FF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.folder_outlined, color: _blue, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROJECT CONTEXT',
                    style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w800,
                      color: _gray, letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _dark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _gray, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  String get _searchHint {
    switch (_tabIndex) {
      case 1:  return 'Search by worker or contractor…';
      case 2:  return 'Search by equipment or vendor…';
      default: return 'Search by name, vendor, brand…';
    }
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E5F6)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: _gray, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          String cat = 'All';
                          if (_tabIndex == 0) cat = 'Materials';
                          if (_tabIndex == 1) cat = 'Labour';
                          if (_tabIndex == 2) cat = 'Equipment';
                          context.read<InventoryProvider>().performSearch(
                            val, cat, projectId: _selectedProjectId ?? '');
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _searchHint,
                        hintStyle: const TextStyle(color: _gray, fontSize: 13.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(color: _dark, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _blue,
            borderRadius: BorderRadius.circular(12),
            shadowColor: _blue.withValues(alpha: 0.3),
            elevation: 1,
            child: InkWell(
              onTap: _showFilterOptions,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                child: Icon(Icons.tune, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────

  Widget _buildTabs() {
    final p = context.watch<InventoryProvider>();
    final badges = [
      p.materialInventory.where((i) => i.closingStock < i.threshold).length,
      p.labourInventory.where((i) => i.closingStock < i.threshold).length,
      p.equipmentInventory.where((i) => i.closingStock < i.threshold).length,
    ];
    const icons  = [Icons.architecture, Icons.people_outline, Icons.construction_outlined];
    const labels = ['Materials', 'Labour', 'Equipment'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E5F6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _tabIndex;
          final textColor = active ? Colors.white : const Color(0xFF4B4966);
          final iconColor = active ? Colors.white : const Color(0xFF757299);
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _tabIndex = i);
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.primaryButton : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[i], color: iconColor, size: 16),
                        const SizedBox(width: 6),
                        Text(labels[i],
                          style: TextStyle(
                            color: textColor,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12.5,
                          )),
                      ],
                    ),
                    if (badges[i] > 0)
                      Positioned(
                        right: 6, top: 0,
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB BUILDERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMaterialsTab(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    final all      = provider.materialInventory;
    final cats     = _buildCategories(all);
    final filtered = _applySort(_applyCategory(all, _matCategory));
    final projName = _selectedProjectName();

    return _TabContent(
      items: filtered,
      type: 'material',
      icon: Icons.architecture,
      categoryFilter: _matCategory,
      cats: cats,
      onCategoryChange: (c) => setState(() => _matCategory = c),
      kpis: [
        _KpiData('Total Stock',
            '${_fmtQty(all.fold(0.0, (s, i) => s + i.closingStock))} units',
            Icons.inventory_2_outlined, _blue),
        _KpiData('Inventory Value',
            formatCurrency(_inventoryValue(all)),
            Icons.account_balance_wallet_outlined, AppColors.primaryPurple),
        _KpiData('Pending Payments',
            formatCurrency(_pendingAmt(all)),
            Icons.pending_actions_outlined, const Color(0xFFEF4444),
            isAlert: _pendingAmt(all) > 0),
        _KpiData('Total Vendors',
            '${_distinctVendors(all)}',
            Icons.store_outlined, const Color(0xFF10B981)),
      ],
      financials: [
        ('Purchase Value', formatCurrency(_inventoryValue(all))),
        ('Paid Amount', formatCurrency(_paidAmt(all))),
        ('Pending Amount', formatCurrency(_pendingAmt(all))),
        ('Vendors', '${_distinctVendors(all)}'),
      ],
      emptyTitle: 'No Material Entries Yet',
      emptySubtitle: 'Add your first material entry to start tracking stock.',
      emptyRoute: '/add-material',
      projectName: projName,
      selectedProjectId: _selectedProjectId,
      vendor: _vendor,
      rate: _rate,
      totalValue: _totalValue,
      payStatus: _payStatus,
      activeFilter: _activeFilter,
      onAdd: (route, args) => Navigator.pushNamed(context, route, arguments: args),
    );
  }

  Widget _buildLabourTab(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    final all      = provider.labourInventory;
    final cats     = _buildCategories(all);
    final filtered = _applySort(_applyCategory(all, _labCategory));
    final projName = _selectedProjectName();

    return _TabContent(
      items: filtered,
      type: 'labour',
      icon: Icons.people_outline,
      categoryFilter: _labCategory,
      cats: cats,
      onCategoryChange: (c) => setState(() => _labCategory = c),
      kpis: [
        _KpiData('Total Workers', '${all.length}',
            Icons.groups_outlined, _blue),
        _KpiData('Labour Cost', formatCurrency(_inventoryValue(all)),
            Icons.payments_outlined, AppColors.primaryPurple),
        _KpiData('Pending Wages', formatCurrency(_pendingAmt(all)),
            Icons.pending_actions_outlined, const Color(0xFFEF4444),
            isAlert: _pendingAmt(all) > 0),
        _KpiData('Contractors', '${_distinctVendors(all)}',
            Icons.business_center_outlined, const Color(0xFF10B981)),
      ],
      financials: [
        ('Labour Cost', formatCurrency(_inventoryValue(all))),
        ('Paid Wages', formatCurrency(_paidAmt(all))),
        ('Pending Wages', formatCurrency(_pendingAmt(all))),
        ('Contractors', '${_distinctVendors(all)}'),
      ],
      emptyTitle: 'No Labour Records Yet',
      emptySubtitle: 'Add your first labour entry to track workforce costs.',
      emptyRoute: '/add-labour',
      projectName: projName,
      selectedProjectId: _selectedProjectId,
      vendor: _vendor,
      rate: _rate,
      totalValue: _totalValue,
      payStatus: _payStatus,
      activeFilter: _activeFilter,
      onAdd: (route, args) => Navigator.pushNamed(context, route, arguments: args),
    );
  }

  Widget _buildEquipmentTab(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    final all      = provider.equipmentInventory;
    final cats     = _buildCategories(all);
    final filtered = _applySort(_applyCategory(all, _eqpCategory));
    final projName = _selectedProjectName();
    final maintDue = all.where((i) => i.closingStock < i.threshold).length;

    return _TabContent(
      items: filtered,
      type: 'equipment',
      icon: Icons.construction_outlined,
      categoryFilter: _eqpCategory,
      cats: cats,
      onCategoryChange: (c) => setState(() => _eqpCategory = c),
      kpis: [
        _KpiData('Equipment Count', '${all.length}',
            Icons.precision_manufacturing_outlined, _blue),
        _KpiData('Asset Value', formatCurrency(_inventoryValue(all)),
            Icons.account_balance_wallet_outlined, AppColors.primaryPurple),
        _KpiData('Maintenance Due', '$maintDue item${maintDue != 1 ? "s" : ""}',
            Icons.build_outlined, const Color(0xFFEF4444),
            isAlert: maintDue > 0),
        _KpiData('Rentals', '${_rentalsCount(all)}',
            Icons.store_outlined, const Color(0xFF10B981)),
      ],
      financials: [
        ('Asset Value', formatCurrency(_inventoryValue(all))),
        ('Maintenance Cost', formatCurrency(_maintenanceCost(all))),
        ('Rental Cost', formatCurrency(_rentalCost(all))),
        ('Pending Payments', formatCurrency(_pendingAmt(all))),
      ],
      emptyTitle: 'No Equipment Entries Yet',
      emptySubtitle: 'Add your first equipment entry to track asset usage.',
      emptyRoute: '/add-equipment',
      projectName: projName,
      selectedProjectId: _selectedProjectId,
      vendor: _vendor,
      rate: _rate,
      totalValue: _totalValue,
      payStatus: _payStatus,
      activeFilter: _activeFilter,
      onAdd: (route, args) => Navigator.pushNamed(context, route, arguments: args),
    );
  }

  static String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);

  // ── Filter bottom sheet ───────────────────────────────────────────────────

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(
        activeFilter: _activeFilter,
        onSelect: (f) {
          setState(() => _activeFilter = f);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB CONTENT (generic scrollable column)
// ═══════════════════════════════════════════════════════════════════════════

class _TabContent extends StatelessWidget {
  final List<InventoryItem> items;
  final String type;
  final IconData icon;
  final String categoryFilter;
  final List<String> cats;
  final ValueChanged<String> onCategoryChange;
  final List<_KpiData> kpis;
  final List<(String, String)> financials;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyRoute;
  final String projectName;
  final String? selectedProjectId;
  final String Function(InventoryItem) vendor;
  final double Function(InventoryItem) rate;
  final double Function(InventoryItem) totalValue;
  final PaymentStatus Function(InventoryItem) payStatus;
  final String activeFilter;
  final void Function(String route, Map<String, dynamic> args) onAdd;

  const _TabContent({
    required this.items,
    required this.type,
    required this.icon,
    required this.categoryFilter,
    required this.cats,
    required this.onCategoryChange,
    required this.kpis,
    required this.financials,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyRoute,
    required this.projectName,
    required this.selectedProjectId,
    required this.vendor,
    required this.rate,
    required this.totalValue,
    required this.payStatus,
    required this.activeFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── KPI Strip ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _KpiStrip(kpis: kpis),
          ),
        ),

        // ── Financial Overview Strip ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _FinancialStrip(items: financials),
          ),
        ),

        // ── Category Chips ────────────────────────────────────────────────────
        if (cats.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
              child: _CategoryChipBar(
                categories: cats,
                selected: categoryFilter,
                onSelect: onCategoryChange,
              ),
            ),
          ),

        // ── Empty State ───────────────────────────────────────────────────────
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: icon,
              onAdd: () => onAdd(emptyRoute, {}),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ErpItemCard(
                    item: items[i],
                    icon: icon,
                    type: type,
                    selectedProjectId: selectedProjectId,
                    projectName: projectName,
                    vendorName: vendor(items[i]),
                    rate: rate(items[i]),
                    totalValue: totalValue(items[i]),
                    payStatus: payStatus(items[i]),
                    onAdd: onAdd,
                  ),
                ),
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: _ErpAlertsSection(items: items),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KPI STRIP
// ═══════════════════════════════════════════════════════════════════════════

class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isAlert;
  const _KpiData(this.label, this.value, this.icon, this.color,
      {this.isAlert = false});
}

class _KpiStrip extends StatelessWidget {
  final List<_KpiData> kpis;
  const _KpiStrip({required this.kpis});

  @override
  Widget build(BuildContext context) {
    if (kpis.length < 4) return const SizedBox.shrink();
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _KpiCard(data: kpis[0])),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(data: kpis[1])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _KpiCard(data: kpis[2])),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(data: kpis[3])),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isAlert
              ? data.color.withValues(alpha: 0.35)
              : const Color(0xFFEEEBF8),
          width: data.isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: data.color, size: 15),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w900,
              color: data.isAlert ? data.color : const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 9.5, color: AppColors.textLight, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CATEGORY CHIP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryChipBar(
      {required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((cat) {
              final isActive = cat == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive ? AppGradients.primaryButton : null,
                      color: isActive ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? Colors.transparent : const Color(0xFFDDE0F0),
                        width: 1.2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textLight,
                        fontWeight: FontWeight.w700, fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onAdd;
  const _EmptyState(
      {required this.title, required this.subtitle, required this.icon, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 34),
            ),
            const SizedBox(height: 20),
            Text(title,
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 17),
                    SizedBox(width: 8),
                    Text('Add First Entry',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERP ITEM CARD — Full information hierarchy
// ═══════════════════════════════════════════════════════════════════════════

class _ErpItemCard extends StatelessWidget {
  final InventoryItem item;
  final IconData icon;
  final String type;
  final String? selectedProjectId;
  final String projectName;
  final String vendorName;
  final double rate;
  final double totalValue;
  final PaymentStatus payStatus;
  final void Function(String route, Map<String, dynamic> args) onAdd;

  const _ErpItemCard({
    required this.item,
    required this.icon,
    required this.type,
    required this.selectedProjectId,
    required this.projectName,
    required this.vendorName,
    required this.rate,
    required this.totalValue,
    required this.payStatus,
    required this.onAdd,
  });

  // ── Stock level ───────────────────────────────────────────────────────────
  bool   get _isLow  => item.closingStock < item.threshold;
  bool   get _isHigh => item.closingStock > item.threshold * 2;
  String get _level  => _isLow ? 'LOW' : (_isHigh ? 'HIGH' : 'MED');
  Color  get _accent =>
      _isLow ? const Color(0xFFEF4444) : (_isHigh ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

  // ── Type-specific labels ──────────────────────────────────────────────────
  String get _qtyLabel {
    switch (type) {
      case 'labour':    return 'Days Worked';
      case 'equipment': return 'Usage Hours';
      default:          return 'In Stock';
    }
  }
  String get _rateLabel {
    switch (type) {
      case 'labour':    return 'Daily Wage';
      case 'equipment': return 'Hourly Cost';
      default:          return 'Rate/Unit';
    }
  }
  String get _valueLabel {
    switch (type) {
      case 'labour':    return 'Total Wage';
      case 'equipment': return 'Total Cost';
      default:          return 'Total Value';
    }
  }
  String get _vendorLabel {
    switch (type) {
      case 'labour': return 'Contractor';
      default:       return 'Vendor';
    }
  }
  String get _addRoute {
    switch (type) {
      case 'labour':    return '/add-labour';
      case 'equipment': return '/add-equipment';
      default:          return '/add-material';
    }
  }
  String get _primaryActionLabel {
    switch (type) {
      case 'labour':    return 'Add Attendance';
      case 'equipment': return 'Add Usage';
      default:          return 'Add More';
    }
  }
  String get _secondaryActionLabel {
    return type == 'labour' ? 'Record Wage' : 'Record Payment';
  }

  String _fmtQty() {
    final q = item.closingStock;
    final s = q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
    final u = (item.unit.isNotEmpty &&
            item.unit.toLowerCase() != 'units' &&
            item.unit.toLowerCase() != 'unit')
        ? ' ${item.unit}' : '';
    return '$s$u';
  }

  @override
  Widget build(BuildContext context) {
    final txCount = item.transactions.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/logs', arguments: {
          'type': type,
          'name': item.name,
          'projectId': selectedProjectId,
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent bar ─────────────────────────────────────
                  Container(width: 4, color: _accent),

                  // ── Main content ────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Row 1: Icon + Name + Stock Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: AppColors.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                      style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800,
                                        color: AppColors.textDark, letterSpacing: -0.2,
                                      ),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (vendorName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Icon(
                                          type == 'labour'
                                              ? Icons.business_center_outlined
                                              : Icons.store_outlined,
                                          size: 11, color: AppColors.textLight),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '$_vendorLabel: $vendorName',
                                            style: const TextStyle(
                                              fontSize: 11, color: AppColors.textLight,
                                              fontWeight: FontWeight.w600),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Stock badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _accent.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Text(_level,
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    color: _accent, letterSpacing: 0.5)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Row 2: Project Context Tag
                          if (projectName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_city_outlined,
                                    size: 11, color: AppColors.primaryBlue),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(projectName,
                                      style: const TextStyle(
                                        fontSize: 11, color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Row 3: Financial Cells
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _FinCell(_valueLabel,
                                    formatCurrency(totalValue), highlight: true)),
                                _vDiv(),
                                Expanded(child: _FinCell(_qtyLabel, _fmtQty())),
                                _vDiv(),
                                Expanded(child: _FinCell(_rateLabel,
                                    rate > 0 ? formatCurrency(rate) : '—')),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Row 4: Payment badge + transaction count (unified with a dot)
                          Row(
                            children: [
                              PaymentStatusChip(status: payStatus),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$txCount transaction${txCount != 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight,
                                  fontWeight: FontWeight.w600)),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF0EEF8)),

                          // Row 5: Action row
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: _primaryActionLabel,
                                    icon: Icons.add_circle_outline,
                                    type: ActionBtnType.primary,
                                    onTap: () => onAdd(_addRoute, {
                                      'type': type,
                                      'prefill': item.name,
                                      'latestRecord': item.transactions.isNotEmpty
                                          ? item.transactions.first : null,
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ActionBtn(
                                    label: _secondaryActionLabel,
                                    icon: Icons.receipt_long_outlined,
                                    type: ActionBtnType.secondary,
                                    onTap: () => Navigator.pushNamed(
                                      context, '/logs',
                                      arguments: {
                                        'type': type, 'name': item.name,
                                        'projectId': selectedProjectId,
                                      }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ActionBtn(
                                  label: 'History',
                                  icon: Icons.history,
                                  type: ActionBtnType.tertiary,
                                  onTap: () => Navigator.pushNamed(
                                    context, '/logs',
                                    arguments: {
                                      'type': type, 'name': item.name,
                                      'projectId': selectedProjectId,
                                    }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vDiv() => Container(
    width: 1, height: 30, color: const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 2));
}

// ─── Financial cell ────────────────────────────────────────────────────────

class _FinCell extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _FinCell(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(
            fontSize: highlight ? 14.5 : 12.5,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
            color: highlight ? AppColors.primaryBlue : const Color(0xFF1A1A2E),
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(label,
          style: const TextStyle(
            fontSize: 9.5, color: AppColors.textLight, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Action button ─────────────────────────────────────────────────────────

enum ActionBtnType { primary, secondary, tertiary }

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final ActionBtnType type;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    Color color;

    switch (type) {
      case ActionBtnType.primary:
        decoration = BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
        color = Colors.white;
        break;
      case ActionBtnType.secondary:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryBlue, width: 1.2),
        );
        color = AppColors.primaryBlue;
        break;
      case ActionBtnType.tertiary:
        decoration = const BoxDecoration(
          color: Colors.transparent,
        );
        color = AppColors.textLight;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROJECT SELECTOR SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _ProjectSelectorSheet extends StatelessWidget {
  final List<String> allItems;
  final Map<String, String?> idMap;
  final String? selectedId;
  final void Function(String?) onSelect;
  const _ProjectSelectorSheet({
    required this.allItems, required this.idMap,
    required this.selectedId, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Project',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...allItems.map((label) {
                final id = label == 'All Active Projects' ? null : idMap[label];
                final isSel = selectedId == id;
                return InkWell(
                  onTap: () => onSelect(id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primaryBlue.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primaryBlue : Colors.transparent,
                        width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(
                        isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSel ? AppColors.primaryBlue : AppColors.textLight),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(label,
                          style: TextStyle(fontSize: 15,
                            color: isSel ? AppColors.primaryBlue : AppColors.textDark,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _FilterSheet extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onSelect;
  const _FilterSheet({required this.activeFilter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = <(String, IconData)>[
      ('A → Z', Icons.sort_by_alpha),
      ('Recently Added', Icons.access_time),
      ('Low Stock', Icons.warning_amber_rounded),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0F0),
                  borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sort & Filter',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
            const SizedBox(height: 12),
            ...options.map(((String, IconData) opt) {
              final (label, icon) = opt;
              final isActive = activeFilter == label;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(icon,
                  color: isActive ? AppColors.primaryBlue : AppColors.textLight),
                title: Text(label,
                  style: TextStyle(
                    color: isActive ? AppColors.primaryBlue : AppColors.textDark,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
                trailing: isActive
                    ? const Icon(Icons.check_circle,
                        color: AppColors.primaryBlue, size: 20) : null,
                onTap: () => onSelect(label),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERP FINANCIAL STRIP
// ═══════════════════════════════════════════════════════════════════════════

class _FinancialStrip extends StatelessWidget {
  final List<(String, String)> items;
  const _FinancialStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5F6)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final (label, value) = items[index];
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < items.length - 1)
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFDDD9F2),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERP OPERATIONAL ALERTS SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _ErpAlertsSection extends StatelessWidget {
  final List<InventoryItem> items;
  const _ErpAlertsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final lowStock = items.where((i) => i.closingStock < i.threshold).toList();
    
    // For pending, find transactions that are not fully paid
    final pendingTx = <Map<String, dynamic>>[];
    for (final item in items) {
      for (final raw in item.transactions) {
        final tx = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (tx != null && (tx['paymentStatus'] ?? '').toString().toLowerCase().trim() != 'paid') {
          pendingTx.add({
            ...tx,
            'itemName': item.name,
          });
        }
      }
    }
    
    if (lowStock.isEmpty && pendingTx.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'ERP OPERATIONAL ALERTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (lowStock.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Low Stock Alerts (${lowStock.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...lowStock.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.closingStock % 1 == 0 ? item.closingStock.toInt() : item.closingStock} ${item.unit} (Min: ${item.threshold.toInt()})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (pendingTx.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending_actions, color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Outstanding Payments (${pendingTx.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...pendingTx.take(2).map((tx) {
                  final title = tx['itemName'] ?? tx['title'] ?? 'Unknown';
                  final bill = (tx['amount'] ?? 0).toDouble();
                  final paid = (tx['paidAmount'] ?? 0).toDouble();
                  final pending = (bill - paid).clamp(0.0, double.infinity);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Pending: ${formatCurrency(pending)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
