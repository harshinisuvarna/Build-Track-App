import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  int _selectedNavIndex = 3;
  int _tabIndex = 0; // CHANGE: 0=Materials, 1=Labour, 2=Equipment

  // ── Reusable bottom sheet ─────────────────────────────────────────────────
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE0F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text('How do you want to add?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
            const SizedBox(height: 20),
            _sheetOption(
              icon: Icons.mic, iconColor: primaryBlue, iconBg: const Color(0xFFEEF0FF),
              title: 'Use Voice', subtitle: 'Speak and let AI capture the details',
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, voiceRoutes[type]!, arguments: {'type': type}); },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.edit_outlined, iconColor: purple, iconBg: const Color(0xFFF0EEFF),
              title: 'Enter Manually', subtitle: 'Fill the form manually',
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, manualRoutes[type]!, arguments: {'type': type}); },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: textGray, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({required IconData icon, required Color iconColor, required Color iconBg,
      required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E5FF)),
        ),
        child: Row(
          children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
              Text(subtitle, style: const TextStyle(fontSize: 12.5, color: textGray)),
            ])),
            const Icon(Icons.chevron_right, color: textGray, size: 20),
          ],
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
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text('Inventory',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Real-time material tracking and logistical oversight.',
                        style: TextStyle(color: textGray, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildTabs(),           // CHANGE: tabs added
                    const SizedBox(height: 14),
                    _buildTabContent(context), // CHANGE: switched content
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SiteTrack',
              style: TextStyle(color: primaryBlue, fontSize: 20, fontWeight: FontWeight.w900)),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cement-history'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDDE0F0)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.history, size: 14, color: purple),
                    SizedBox(width: 5),
                    Text('History', style: TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 19, backgroundColor: Colors.grey.shade800,
                child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: textGray, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Search materials, SKU, or site log...', style: TextStyle(color: textGray, fontSize: 13.5))),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune, color: Colors.white, size: 19),
          ),
        ],
      ),
    );
  }

  // CHANGE: Tabs widget
  Widget _buildTabs() {
    const tabs = ['Materials', 'Labour', 'Equipment'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(tabs[i], textAlign: TextAlign.center,
                    style: TextStyle(color: active ? Colors.white : textGray, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_tabIndex) {
      case 1: return _buildLabourTab(context);
      case 2: return _buildEquipmentTab(context);
      default: return _buildMaterialsTab(context);
    }
  }

  Widget _buildMaterialsTab(BuildContext context) {
    return Column(children: [
      _inventoryCard(context: context, icon: Icons.architecture, name: 'Steel Rebar 12mm',
          lastUpdated: 'Last updated 2h ago', qty: '1,240', unit: 'units', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'material'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.format_paint_outlined, name: 'Primer White X-2',
          lastUpdated: 'Last updated 45m ago', qty: '42', unit: 'cans', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'material'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.layers_outlined, name: 'Portland Cement',
          lastUpdated: 'Last updated 5h ago', qty: '450', unit: 'bags', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'material'),
      const SizedBox(height: 12),
      _urgentCard(context),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.construction_outlined, name: 'HVAC Copper Pipes',
          lastUpdated: 'Last updated 1d ago', qty: '3,200', unit: 'meters', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'material'),
    ]);
  }

  Widget _buildLabourTab(BuildContext context) {
    return Column(children: [
      _inventoryCard(context: context, icon: Icons.engineering_outlined, name: 'Concrete Form Workers',
          lastUpdated: 'Last updated 1h ago', qty: '14', unit: 'workers', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'labour'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.people_outline, name: 'Masonry Team',
          lastUpdated: 'Last updated 3h ago', qty: '8', unit: 'workers', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'labour'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.electric_bolt_outlined, name: 'Electrical Crew',
          lastUpdated: 'Last updated 6h ago', qty: '5', unit: 'workers', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'labour'),
    ]);
  }

  Widget _buildEquipmentTab(BuildContext context) {
    return Column(children: [
      _inventoryCard(context: context, icon: Icons.precision_manufacturing_outlined, name: 'Tower Crane TC-7',
          lastUpdated: 'Last updated 30m ago', qty: '6', unit: 'hrs today', level: 'HIGH', levelColor: primaryBlue, bottomColor: primaryBlue, type: 'equipment'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.construction_outlined, name: 'Concrete Mixer CM-3',
          lastUpdated: 'Last updated 2h ago', qty: '4', unit: 'hrs today', level: 'MED', levelColor: Colors.orange, bottomColor: Colors.orange, type: 'equipment'),
      const SizedBox(height: 12),
      _inventoryCard(context: context, icon: Icons.local_shipping_outlined, name: 'Excavator EX-200',
          lastUpdated: 'Last updated 1d ago', qty: '0', unit: 'hrs today', level: 'LOW', levelColor: Colors.redAccent, bottomColor: Colors.redAccent, type: 'equipment'),
    ]);
  }

  Widget _inventoryCard({required BuildContext context, required IconData icon, required String name,
      required String lastUpdated, required String qty, required String unit, required String level,
      required Color levelColor, required Color bottomColor, required String type}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/logs', arguments: {'type': type, 'name': name}),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: bottomColor, width: 3.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: purple, size: 20)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: levelColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(level, style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
              const SizedBox(height: 2),
              Text(lastUpdated, style: const TextStyle(color: textGray, fontSize: 11.5)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(qty, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.5)),
                const SizedBox(width: 6),
                Text(unit, style: const TextStyle(color: textGray, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ])),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _showEntryOptions(context, type), // CHANGE: + opens bottom sheet
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add, color: primaryBlue, size: 20),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
        ]),
      ),
    );
  }

  Widget _urgentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2233DD), Color(0xFF7B3FEF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2233DD).withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notification_important_outlined, color: Colors.white70, size: 14),
          SizedBox(width: 6),
          Text('URGENT REQUIREMENT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
        ]),
        const SizedBox(height: 10),
        const Text('Glazing Panels\nSection B-12', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        const Text('Stock level critically low for the upcoming facade installation phase.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => _showEntryOptions(context, 'material'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: const Text('Restock Now', style: TextStyle(color: Color(0xFF2233DD), fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          SizedBox(width: 78, height: 78,
            child: Stack(alignment: Alignment.center, children: [
              const SizedBox(width: 78, height: 78,
                child: CircularProgressIndicator(value: 0.12, strokeWidth: 7, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('12%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                Text('REMAINING', style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 0.5)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))]),
      child: SafeArea(top: false,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _navItem(context, 0, Icons.home_rounded, 'HOME', route: '/home'),
            _navItem(context, 1, Icons.architecture_outlined, 'PROJECTS', route: '/projects'),
            _navEntryButton(context),
            _navItem(context, 3, Icons.inventory_2_outlined, 'INVENTORY', route: '/inventory'),
            _navItem(context, 4, Icons.bar_chart_outlined, 'REPORTS', route: '/reports'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label, {String? route}) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () { setState(() => _selectedNavIndex = index); if (route != null && route != '/inventory') Navigator.pushNamed(context, route); },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 64, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: isActive ? primaryBlue : textGray),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: isActive ? primaryBlue : textGray, letterSpacing: 0.3)),
      ])),
    );
  }

  Widget _navEntryButton(BuildContext context) {
    return GestureDetector(
      onTap: () { setState(() => _selectedNavIndex = 2); Navigator.pushNamed(context, '/add-entry'); },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.add, color: Colors.white, size: 24)),
        const SizedBox(height: 3),
        Text('ENTRY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _selectedNavIndex == 2 ? primaryBlue : textGray, letterSpacing: 0.3)),
      ]),
    );
  }
}