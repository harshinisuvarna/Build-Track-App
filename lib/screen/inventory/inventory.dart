import 'dart:async'; // --- ADDED: Required for Debounce Timer ---
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
// --- ADDED YOUR NEW PROVIDER IMPORTS ---
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/models/inventory_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;

  final PageController _pageController = PageController();
  int _tabIndex = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'Recently Added';

  String? _selectedProjectId;

  Timer? _debounce; // --- ADDED: Debounce Timer variable ---

  // --- ADDED: Fetch initial live data when screen opens ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory(_selectedProjectId ?? '');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // --- ADDED: Clean up timer ---
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProjectSelector(BuildContext context) {
    final projects = context.read<ProjectProvider>().projects;
    final allItems = ['All Active Projects', ...projects.map((p) => p.name)];
    final idMap = {for (final p in projects) p.name: p.id};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Select Project',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...allItems.map((label) {
                final id = label == 'All Active Projects' ? null : idMap[label];
                final isSelected = _selectedProjectId == id;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedProjectId = id);
                    // --- ADDED: Reload inventory when project changes ---
                    context.read<InventoryProvider>().loadInventory(id ?? '');
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryBlue.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryBlue : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? primaryBlue : textGray,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? primaryBlue : textDark,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
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
              title: 'Inventory',
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProjectSelector(),
                        const SizedBox(height: 12),
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildTabs(),
                        const SizedBox(height: 12),
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

  Widget _buildProjectSelector() {
    // ... (Your exact existing code)
    final projects = context.watch<ProjectProvider>().projects;
    final ProjectModel? selected = _selectedProjectId == null
        ? null
        : projects.cast<ProjectModel?>().firstWhere(
            (p) => p?.id == _selectedProjectId,
            orElse: () => null,
          );
    final label = selected?.name ?? 'All Active Projects';

    return GestureDetector(
      onTap: () => _showProjectSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E5FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: primaryBlue,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROJECT CONTEXT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: textGray,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // ... (Your exact existing code)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: textGray, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              // --- ADDED: Task 2 Debounce Timer Logic ---
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  String category = 'All';
                  if (_tabIndex == 0) category = 'Materials';
                  if (_tabIndex == 1) category = 'Labour';
                  if (_tabIndex == 2) category = 'Equipment';
                  context.read<InventoryProvider>().performSearch(
                    val,
                    category,
                    projectId: _selectedProjectId ?? '',
                  );
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search materials, SKU, or site log...',
                hintStyle: TextStyle(color: textGray, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              style: const TextStyle(color: textDark, fontSize: 14),
            ),
          ),
          Material(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _showFilterOptions,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.tune, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    // ... (Your exact existing code)
    const tabs = ['Materials', 'Labour', 'Equipment'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _tabIndex = i);
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
              borderRadius: BorderRadius.circular(26),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.primaryButton : null,
                  color: active ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : textGray,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- UPDATED: Uses Live Inventory Provider ---
  Widget _buildMaterialsTab(BuildContext context) {
    final stock = context.watch<ProjectProvider>().materialStock;
    final stockList = stock.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final provider = context.watch<InventoryProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    var items = provider.materialInventory.map((item) {
      final isLow = item.closingStock < item.threshold;
      final levelStr = isLow
          ? 'LOW'
          : (item.closingStock > item.threshold * 2 ? 'HIGH' : 'MED');

      int timestamp = 0;
      if (item.id.length == 24) {
        try {
          timestamp = int.parse(item.id.substring(0, 8), radix: 16);
        } catch (_) {}
      }

      return {
        'name': item.name,
        'projectId': _selectedProjectId ?? 'p1',
        'widget': _ItemGroupWidget(
          item: item,
          icon: Icons.architecture,
          type: 'material',
          selectedProjectId: _selectedProjectId,
        ),
        'level': isLow ? 0 : (levelStr == 'HIGH' ? 2 : 1),
        'time': timestamp,
      };
    }).toList();

    return _buildTab(items, stockSummary: _buildStockSummary(stockList));
  }

  Widget _buildStockSummary(List<MapEntry<String, double>> stockList) {
    // ... (Your exact existing code)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE STOCK SUMMARY',
                style: TextStyle(
                  color: textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (stockList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F5), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: textGray, size: 18),
                const SizedBox(width: 10),
                Text(
                  'No material entries yet — add one above',
                  style: AppTheme.caption.copyWith(color: textGray),
                ),
              ],
            ),
          )
        else
          ...stockList.map((entry) {
            final brand = entry.key;
            final qty = entry.value;
            final maxQty = stockList.first.value;
            final ratio = maxQty > 0 ? (qty / maxQty).clamp(0.0, 1.0) : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '${qty.toStringAsFixed(1)} units',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEEF0F5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ratio > 0.6
                            ? primaryBlue
                            : ratio > 0.3
                            ? Colors.orange
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildLabourTab(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }
    final items = provider.labourInventory.map((item) {
      final isLow = item.closingStock < item.threshold;
      final levelStr = isLow
          ? 'LOW'
          : (item.closingStock > item.threshold * 2 ? 'HIGH' : 'MED');

      int timestamp = 0;
      if (item.id.length == 24) {
        try {
          timestamp = int.parse(item.id.substring(0, 8), radix: 16);
        } catch (_) {}
      }

      return {
        'name': item.name,
        'widget': _ItemGroupWidget(
          item: item,
          icon: Icons.people_outline,
          type: 'labour',
          selectedProjectId: _selectedProjectId,
        ),
        'level': isLow ? 0 : (levelStr == 'HIGH' ? 2 : 1),
        'time': timestamp,
      };
    }).toList();
    return _buildTab(items);
  }

  Widget _buildEquipmentTab(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }
    final items = provider.equipmentInventory.map((item) {
      final isLow = item.closingStock < item.threshold;
      final levelStr = isLow
          ? 'LOW'
          : (item.closingStock > item.threshold * 2 ? 'HIGH' : 'MED');

      int timestamp = 0;
      if (item.id.length == 24) {
        try {
          timestamp = int.parse(item.id.substring(0, 8), radix: 16);
        } catch (_) {}
      }

      return {
        'name': item.name,
        'widget': _ItemGroupWidget(
          item: item,
          icon: Icons.construction_outlined,
          type: 'equipment',
          selectedProjectId: _selectedProjectId,
        ),
        'level': isLow ? 0 : (levelStr == 'HIGH' ? 2 : 1),
        'time': timestamp,
      };
    }).toList();
    return _buildTab(items);
  }

  Widget _buildTab(List<Map<String, dynamic>> items, {Widget? stockSummary}) {
    // We no longer filter search queries locally because the backend search API handles it.
    var filtered = List<Map<String, dynamic>>.from(items);

    // Using Roselin's updated UI dropdown string names for sorting
    if (_activeFilter == 'A → Z' || _activeFilter == 'Sort by Name (A-Z)') {
      filtered.sort(
        (a, b) => (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        ),
      );
    } else if (_activeFilter == 'Low Stock' ||
        _activeFilter == 'Show Low Stock First') {
      filtered.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
    } else if (_activeFilter == 'Recently Added' ||
        _activeFilter == 'Recently Updated') {
      filtered.sort((a, b) => (b['time'] as num).compareTo(a['time'] as num));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          if (stockSummary != null) ...[stockSummary],
          if (filtered.isEmpty && items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No entries found.',
                  style: TextStyle(color: textGray),
                ),
              ),
            ),
          ...filtered.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: i['widget'] as Widget,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 20),
            _filterTile(ctx, 'A → Z', Icons.sort_by_alpha),
            _filterTile(ctx, 'Recently Added', Icons.access_time),
            _filterTile(ctx, 'Low Stock', Icons.warning_amber_rounded),
          ],
        ),
      ),
    );
  }

  Widget _filterTile(BuildContext ctx, String label, IconData icon) {
    final isActive = _activeFilter == label;
    return ListTile(
      leading: Icon(icon, color: isActive ? primaryBlue : textGray),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? primaryBlue : textDark,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isActive ? const Icon(Icons.check, color: primaryBlue) : null,
      onTap: () {
        setState(() => _activeFilter = label);
        Navigator.pop(ctx);
      },
    );
  }
}

class _ItemGroupWidget extends StatelessWidget {
  const _ItemGroupWidget({
    required this.item,
    required this.icon,
    required this.type,
    required this.selectedProjectId,
  });

  final InventoryItem item;
  final IconData icon;
  final String type; // 'material', 'labour', 'equipment'
  final String? selectedProjectId;

  String _formatItemDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = item.transactions;
    final totalTxs = txs.length;

    // Determine level/color
    final isLow = item.closingStock < item.threshold;
    final levelStr = isLow
        ? 'LOW'
        : (item.closingStock > item.threshold * 2 ? 'HIGH' : 'MED');
    final statusColor = isLow
        ? Colors.redAccent
        : (levelStr == 'HIGH' ? AppColors.primary : Colors.orange);

    String lastUpdatedLabel = '—';
    if (txs.isNotEmpty) {
      lastUpdatedLabel = _formatItemDate(txs[0]['date'] ?? txs[0]['updatedAt']);
    }

    String stockLabel = 'Current Stock';
    if (type == 'labour') {
      stockLabel = 'Current Quantity';
    } else if (type == 'equipment') {
      stockLabel = 'Current Usage';
    }

    final unitSuffix = (item.unit.isNotEmpty && item.unit.toLowerCase() != 'units') ? ' ${item.unit}' : '';
    final stockText = '$stockLabel: ${item.closingStock.toStringAsFixed(0)}$unitSuffix';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Navigate directly to the item details page for that material
          Navigator.pushNamed(
            context,
            '/logs',
            arguments: {
              'type': type,
              'name': item.name,
              'projectId': selectedProjectId,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(bottom: BorderSide(color: statusColor, width: 3.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Item Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),

              // Title details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stockText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Transactions: $totalTxs',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last Updated: $lastUpdatedLabel',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add (+) button (Smart Prefill from latest transaction)
              Material(
                color: const Color(0xFFF0F2FF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    // Open prefilled entry screen using the latest record (txs[0])
                    final manualRoutes = {
                      'material': '/add-material',
                      'labour': '/add-labour',
                      'equipment': '/add-equipment',
                    };
                    Navigator.pushNamed(
                      context,
                      manualRoutes[type]!,
                      arguments: {
                        'type': type,
                        'prefill': item.name,
                        'latestRecord': txs.isNotEmpty ? txs[0] : null,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.add, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
