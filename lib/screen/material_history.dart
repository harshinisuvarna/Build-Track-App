import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class CementHistoryScreen extends StatefulWidget {
  const CementHistoryScreen({super.key});
  @override
  State<CementHistoryScreen> createState() => _CementHistoryScreenState();
}

class _CementHistoryScreenState extends State<CementHistoryScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  int _selectedNavIndex = 3;

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStockCard(),
                    const SizedBox(height: 22),
                    _buildMovementHeader(),
                    const SizedBox(height: 14),
                    _movementItem(
                      icon: Icons.local_shipping_outlined,
                      iconBg: const Color(0xFFEEF0FF),
                      iconColor: primaryBlue,
                      name: 'Portland Type II',
                      subtitle: 'Stock Replenishment • #INV-9921',
                      qty: '+450',
                      date: 'OCT 24,\n2023',
                      isPositive: true,
                      accent: primaryBlue,
                    ),
                    const SizedBox(height: 10),
                    _movementItem(
                      icon: Icons.home_work_outlined,
                      iconBg: const Color(0xFFF0EEFF),
                      iconColor: purple,
                      name: 'Portland Type II',
                      subtitle: 'Slab Pouring - Block B • #INV-9884',
                      qty: '-120',
                      date: 'OCT 22,\n2023',
                      isPositive: false,
                      accent: const Color(0xFFE040FB),
                    ),
                    const SizedBox(height: 10),
                    _movementItem(
                      icon: Icons.architecture,
                      iconBg: const Color(0xFFF0EEFF),
                      iconColor: purple,
                      name: 'Quick-Set Specialty',
                      subtitle: 'Column Reinforcement • #INV-9851',
                      qty: '-45',
                      date: 'OCT 20,\n2023',
                      isPositive: false,
                      accent: const Color(0xFFE040FB),
                    ),
                    const SizedBox(height: 10),
                    _movementItem(
                      icon: Icons.local_shipping_outlined,
                      iconBg: const Color(0xFFEEF0FF),
                      iconColor: primaryBlue,
                      name: 'Portland Type II',
                      subtitle: 'Stock Replenishment • #INV-9820',
                      qty: '+200',
                      date: 'OCT 18,\n2023',
                      isPositive: true,
                      accent: primaryBlue,
                    ),
                    const SizedBox(height: 10),
                    _movementItem(
                      icon: Icons.construction_outlined,
                      iconBg: const Color(0xFFF0EEFF),
                      iconColor: purple,
                      name: 'Portland Type II',
                      subtitle: 'Foundation Work • #INV-9799',
                      qty: '-85',
                      date: 'OCT 15,\n2023',
                      isPositive: false,
                      accent: const Color(0xFFE040FB),
                    ),
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

  Widget _buildStockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
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
          const Text(
            'TOTAL CURRENT STOCK',
            style: TextStyle(
              fontSize: 12,
              color: textGray,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: '1,248',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5B3FE0),
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: '  Units',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stockBadge(Icons.category_outlined, 'GRADE A-500'),
              const SizedBox(width: 30),
              _stockBadge(Icons.home_work_outlined, 'SECTOR 04'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: purple, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: purple,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMovementHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movement Logs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Tracking historical distribution',
              style: TextStyle(color: textGray, fontSize: 12.5),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE0F0)),
          ),
          child: const Row(
            children: [
              Text(
                'Filter',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.tune, color: primaryBlue, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _movementItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String name,
    required String subtitle,
    required String qty,
    required String date,
    required bool isPositive,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: textGray, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                qty,
                style: TextStyle(
                  color: isPositive ? primaryBlue : const Color(0xFFE040FB),
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: textGray,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(context, 0, Icons.home_rounded, 'HOME', route: '/home'),
              _navItem(
                context,
                1,
                Icons.architecture_outlined,
                'PROJECTS',
                route: '/projects',
              ),
              _navEntryButton(context),
              _navItem(
                context,
                3,
                Icons.inventory_2_outlined,
                'INVENTORY',
                route: '/inventory',
              ),
              _navItem(
                context,
                4,
                Icons.bar_chart_outlined,
                'REPORTS',
                route: '/reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    String label, {
    String? route,
  }) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (route != null) Navigator.pushNamed(context, route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryBlue : textGray,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navEntryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = 2);
        Navigator.pushNamed(context, '/add-entry');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            'ENTRY',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _selectedNavIndex == 2 ? primaryBlue : textGray,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
