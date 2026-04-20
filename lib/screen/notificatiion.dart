import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  int _selectedNavIndex = 4; // REPORTS is active (notifications is sub-screen)

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
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // TODAY header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Today',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('3 NEW',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _criticalAlertCard(),
                    const SizedBox(height: 12),
                    _inventoryWarningCard(),
                    const SizedBox(height: 12),
                    _weeklyReportCard(),
                    const SizedBox(height: 26),
                    const Text('Yesterday',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textGray)),
                    const SizedBox(height: 12),
                    _yesterdayCard(
                      icon: Icons.check_circle_outline,
                      iconBg: const Color(0xFFF0F2FF),
                      iconColor: primaryBlue,
                      title: 'Safety Audit Completed',
                      body:
                          "The site audit for 'South Wing' was successfully logged by inspector Miller.",
                      time: '1d ago',
                    ),
                    const SizedBox(height: 10),
                    _yesterdayCard(
                      icon: Icons.schedule_outlined,
                      iconBg: const Color(0xFFF5F5F5),
                      iconColor: textGray,
                      title: 'Schedule Update',
                      body:
                          'Arrival of electrical components moved from Tuesday to Wednesday 08:00 AM.',
                      time: '1d ago',
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

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          const Text('Notifications',
              style: TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read',
                style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Critical Alert ────────────────────────────────────────────────────────

  Widget _criticalAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border(left: BorderSide(color: Colors.red.shade400, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withValues(alpha: 0.07),
              blurRadius: 14)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade400, size: 20),
              ),
              const Text('12m ago',
                  style: TextStyle(color: textGray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('CRITICAL ALERT',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9)),
            ],
          ),
          const SizedBox(height: 7),
          const Text('Structural Beam Deflection Detected',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  height: 1.3)),
          const SizedBox(height: 6),
          const Text(
            'Sensor 4B in Sector 7 reports stress levels exceeding 15% threshold. Immediate inspection required at the Western support pillar.',
            style: TextStyle(color: textGray, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text('Resolve',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: Color(0xFFDDE0F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text('View Map',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inventory Warning ─────────────────────────────────────────────────────

  Widget _inventoryWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
            left: BorderSide(color: Colors.orange, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.06),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Colors.orange, size: 20),
              ),
              const Text('2h ago',
                  style: TextStyle(color: textGray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('INVENTORY WARNING',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9)),
            ],
          ),
          const SizedBox(height: 7),
          const Text('Low Cement Stock (Phase 2)',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark)),
          const SizedBox(height: 6),
          const Text(
            "Current supply will be depleted by tomorrow's afternoon shift. Re-order scheduled but requires manual approval.",
            style:
                TextStyle(color: textGray, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Weekly Report ─────────────────────────────────────────────────────────

  Widget _weeklyReportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.bar_chart,
                    color: primaryBlue, size: 20),
              ),
              const Text('5h ago',
                  style: TextStyle(color: textGray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('WEEKLY REPORT',
              style: TextStyle(
                  color: primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9)),
          const SizedBox(height: 7),
          const Text('Project Velocity Insight',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark)),
          const SizedBox(height: 6),
          const Text(
            'Efficiency on Sector 4 has increased by 12% following the new logistics deployment. View the full technical breakdown.',
            style:
                TextStyle(color: textGray, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Yesterday Card ────────────────────────────────────────────────────────

  Widget _yesterdayCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: textDark)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(
                        color: textGray,
                        fontSize: 12.5,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style:
                  const TextStyle(color: textGray, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

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
              _navItem(context, 0, Icons.home_rounded, 'HOME',
                  route: '/home'),
              _navItem(context, 1, Icons.architecture_outlined,
                  'PROJECTS', route: '/projects'),
              _navEntryButton(context),
              _navItem(context, 3, Icons.inventory_2_outlined,
                  'INVENTORY', route: '/inventory'),
              _navItem(context, 4, Icons.bar_chart_outlined, 'REPORTS',
                  route: '/reports'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon,
      String label,
      {String? route}) {
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
            Icon(icon,
                size: 22,
                color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? primaryBlue : textGray,
                    letterSpacing: 0.3)),
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
            child:
                const Icon(Icons.add, color: Colors.white, size: 24),
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