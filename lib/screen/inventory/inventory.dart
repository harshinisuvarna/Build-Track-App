import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  final PageController _pageController = PageController();
  int _tabIndex = 0;
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  bool _matchSearch(String name) {
    return _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showEntryOptions(BuildContext context, String type) {
    final voiceRoutes = {
      'material': '/review-material',
      'labour': '/review-labour',
      'equipment': '/review-equipment',
    };
    final manualRoutes = {
      'material': '/add-material',
      'labour': '/add-labour',
      'equipment': '/add-equipment',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('How do you want to add?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textDark)),
            const SizedBox(height: 20),
            _sheetOption(
              icon: Icons.mic,
              iconColor: primaryBlue,
              iconBg: const Color(0xFFEEF0FF),
              title: 'Use Voice',
              subtitle: 'Speak and let AI capture the details',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, voiceRoutes[type]!,
                    arguments: {'type': type});
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.edit_outlined,
              iconColor: purple,
              iconBg: const Color(0xFFF0EEFF),
              title: 'Enter Manually',
              subtitle: 'Fill the form manually',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, manualRoutes[type]!,
                    arguments: {'type': type});
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.pop(ctx),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text('Cancel',
                    style: TextStyle(
                        color: textGray,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E5FF))),
          child: Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 13.5, color: textGray)),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: textGray, size: 20),
          ]),
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
        child: Column(children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventory',
                          style: AppTheme.heading1.copyWith(
                              color: textDark, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(
                          'Real-time material tracking and logistical oversight.',
                          style: AppTheme.body.copyWith(color: textGray)),
                      const SizedBox(height: 14),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildTabs(),
                      const SizedBox(height: 14),
                    ]),
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
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        const Icon(Icons.search, color: textGray, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
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
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _showFilterOptions,
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.tune, color: Colors.white, size: 19)),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Materials', 'Labour', 'Equipment'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _tabIndex = i);
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut);
              },
              borderRadius: BorderRadius.circular(26),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    gradient: active ? AppGradients.primaryButton : null,
                    color: active ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(26)),
                child: Text(tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: active ? Colors.white : textGray,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMaterialsTab(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(children: [
          if (_matchSearch('Steel Rebar 12mm')) ...[
            _inventoryCard(context: context, icon: Icons.architecture, name: 'Steel Rebar 12mm', lastUpdated: 'Last updated 2h ago', qty: '1,240', unit: 'units', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'material'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Primer White X-2')) ...[
            _inventoryCard(context: context, icon: Icons.format_paint_outlined, name: 'Primer White X-2', lastUpdated: 'Last updated 45m ago', qty: '42', unit: 'cans', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'material'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Portland Cement')) ...[
            _inventoryCard(context: context, icon: Icons.layers_outlined, name: 'Portland Cement', lastUpdated: 'Last updated 5h ago', qty: '450', unit: 'bags', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'material'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('urgent material')) ...[
            _urgentCard(context),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('HVAC Copper Pipes')) ...[
            _inventoryCard(context: context, icon: Icons.construction_outlined, name: 'HVAC Copper Pipes', lastUpdated: 'Last updated 1d ago', qty: '3,200', unit: 'meters', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'material'),
          ],
        ]),
      );

  Widget _buildLabourTab(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(children: [
          if (_matchSearch('Concrete Form Workers')) ...[
            _inventoryCard(context: context, icon: Icons.engineering_outlined, name: 'Concrete Form Workers', lastUpdated: 'Last updated 1h ago', qty: '14', unit: 'workers', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'labour'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Masonry Team')) ...[
            _inventoryCard(context: context, icon: Icons.people_outline, name: 'Masonry Team', lastUpdated: 'Last updated 3h ago', qty: '8', unit: 'workers', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'labour'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Electrical Crew')) ...[
            _inventoryCard(context: context, icon: Icons.electric_bolt_outlined, name: 'Electrical Crew', lastUpdated: 'Last updated 6h ago', qty: '5', unit: 'workers', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'labour'),
          ],
        ]),
      );

  Widget _buildEquipmentTab(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(children: [
          if (_matchSearch('Tower Crane TC-7')) ...[
            _inventoryCard(context: context, icon: Icons.precision_manufacturing_outlined, name: 'Tower Crane TC-7', lastUpdated: 'Last updated 30m ago', qty: '6', unit: 'hrs today', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'equipment'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Concrete Mixer CM-3')) ...[
            _inventoryCard(context: context, icon: Icons.construction_outlined, name: 'Concrete Mixer CM-3', lastUpdated: 'Last updated 2h ago', qty: '4', unit: 'hrs today', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'equipment'),
            const SizedBox(height: 12),
          ],
          if (_matchSearch('Excavator EX-200')) ...[
            _inventoryCard(context: context, icon: Icons.local_shipping_outlined, name: 'Excavator EX-200', lastUpdated: 'Last updated 1d ago', qty: '0', unit: 'hrs today', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'equipment'),
          ],
        ]),
      );

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha, color: textGray),
              title: const Text('Sort by Name (A-Z)'),
              onTap: () { Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: textGray),
              title: const Text('Show Low Stock First'),
              onTap: () { Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: textGray),
              title: const Text('Recently Updated'),
              onTap: () { Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryCard({
    required BuildContext context,
    required IconData icon,
    required String name,
    required String lastUpdated,
    required String qty,
    required String unit,
    required String level,
    required Color levelColor,
    required Color bottomColor,
    required String type,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/logs',
            arguments: {'type': type, 'name': name}),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(bottom: BorderSide(color: bottomColor, width: 3.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ],
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: purple, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(level,
                    style: TextStyle(
                        color: levelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTheme.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textDark)),
                      const SizedBox(height: 2),
                      Text(lastUpdated,
                          style:
                              AppTheme.caption.copyWith(color: textGray)),
                      const SizedBox(height: 8),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(qty,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textDark,
                                    letterSpacing: -0.5)),
                            const SizedBox(width: 6),
                            Text(unit,
                                style: AppTheme.body
                                    .copyWith(color: textGray)),
                          ]),
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _showEntryOptions(context, type),
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.add, color: primaryBlue, size: 22)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
          ]),
        ),
      ),
    );
  }

  Widget _urgentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notification_important_outlined,
              color: Colors.white70, size: 14),
          SizedBox(width: 6),
          Text('URGENT REQUIREMENT',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3)),
        ]),
        const SizedBox(height: 10),
        const Text('Glazing Panels\nSection B-12',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.3)),
        const SizedBox(height: 8),
        const Text(
            'Stock level critically low for the upcoming facade installation phase.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        const SizedBox(height: 18),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: () => _showEntryOptions(context, 'material'),
                  borderRadius: BorderRadius.circular(30),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: Text('Restock Now',
                        style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ),
              ),
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(alignment: Alignment.center, children: const [
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: CircularProgressIndicator(
                        value: 0.12,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('12%',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17)),
                    Text('REMAINING',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            letterSpacing: 0.5)),
                  ]),
                ]),
              ),
            ]),
      ]),
    );
  }
}
