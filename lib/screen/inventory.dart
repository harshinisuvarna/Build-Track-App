import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'SiteTrack',
              rightWidget: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade800,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Inventory',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time material tracking and logistical oversight.',
                      style: GoogleFonts.inter(
                        color: textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _inventoryCard(
                      context: context,
                      icon: Icons.architecture,
                      name: 'Steel Rebar 12mm',
                      lastUpdated: 'Last updated 2h ago',
                      qty: '1,240',
                      unit: 'units',
                      level: 'HIGH',
                      levelColor: primaryBlue,
                      bottomColor: primaryBlue,
                      actionIcon: Icons.add,
                      // FIX: each card passes its material name as argument
                      materialName: 'Steel Rebar 12mm',
                    ),
                    const SizedBox(height: 12),
                    _inventoryCard(
                      context: context,
                      icon: Icons.format_paint_outlined,
                      name: 'Primer White X-2',
                      lastUpdated: 'Last updated 45m ago',
                      qty: '42',
                      unit: 'cans',
                      level: 'LOW',
                      levelColor: Colors.redAccent,
                      bottomColor: Colors.redAccent,
                      actionIcon: Icons.shopping_cart_outlined,
                      materialName: 'Primer White X-2',
                    ),
                    const SizedBox(height: 12),
                    _inventoryCard(
                      context: context,
                      icon: Icons.layers_outlined,
                      name: 'Portland Cement',
                      lastUpdated: 'Last updated 5h ago',
                      qty: '450',
                      unit: 'bags',
                      level: 'MED',
                      levelColor: Colors.orange,
                      bottomColor: Colors.orange,
                      actionIcon: Icons.add,
                      materialName: 'Portland Cement',
                    ),
                    const SizedBox(height: 12),
                    _urgentCard(context),
                    const SizedBox(height: 12),
                    _inventoryCard(
                      context: context,
                      icon: Icons.construction_outlined,
                      name: 'HVAC Copper Pipes',
                      lastUpdated: 'Last updated 1d ago',
                      qty: '3,200',
                      unit: 'meters',
                      level: 'HIGH',
                      levelColor: primaryBlue,
                      bottomColor: primaryBlue,
                      actionIcon: Icons.add,
                      materialName: 'HVAC Copper Pipes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: textGray, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search materials, SKU, or site log...',
              style: TextStyle(color: textGray, fontSize: 13.5),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 19),
          ),
        ],
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
    required IconData actionIcon,
    required String materialName,
  }) {
    return GestureDetector(
      // FIX: passes material name as argument so cement-history screen knows what to show
      onTap: () => Navigator.pushNamed(
        context,
        '/cement-history',
        arguments: {'materialName': materialName},
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: bottomColor, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: purple, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastUpdated,
                        style: const TextStyle(color: textGray, fontSize: 11.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            qty,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            unit,
                            style: const TextStyle(
                              color: textGray,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(actionIcon, color: primaryBlue, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _urgentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2233DD), Color(0xFF7B3FEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2233DD).withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notification_important_outlined,
                color: Colors.white70,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'URGENT REQUIREMENT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Glazing Panels\nSection B-12',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stock level critically low for the upcoming facade installation phase.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                // FIX: Restock Now navigates to add-material with the item pre-filled
                onTap: () => Navigator.pushNamed(
                  context,
                  '/add-material',
                  arguments: {
                    'type': 'material',
                    'prefill': 'Glazing Panels Section B-12',
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Restock Now',
                    style: TextStyle(
                      color: Color(0xFF2233DD),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 78,
                      height: 78,
                      child: CircularProgressIndicator(
                        value: 0.12,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '12%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'REMAINING',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
