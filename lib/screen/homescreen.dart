import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              AppTopBar(
                title: 'SiteTrack',
                rightWidget: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              _buildProjectSelector(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 14),
                    _buildCostRow(),
                    const SizedBox(height: 14),
                    _buildCategoryIcons(),
                    const SizedBox(height: 14),
                    _buildSpeakUpdate(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neurofin Admin',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Project Foreman',
                          style: GoogleFonts.inter(color: textGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              _drawerItem(Icons.inventory_2_outlined, 'Manage materials'),
              _drawerItem(Icons.people_outline, 'Manage labour'),
              _drawerItem(Icons.construction_outlined, 'Manage equipment'),
              _drawerItem(
                Icons.language_outlined,
                'Language',
                trailing: 'EN-US',
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Log out',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: textDark, size: 22),
      title: Text(
        label,
        style:  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style:  GoogleFonts.inter(
                color: textGray,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
      onTap: () {},
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.architecture, color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Skyline Residences Phase II',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, color: textGray),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERALL PROGRESS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textGray,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '68.4%',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '12 Days Ahead',
                    style: GoogleFonts.inter(
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Target: Oct 24',
                    style: GoogleFonts.inter(color: textGray, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.684,
              backgroundColor: Color(0xFFE8ECF8),
              color: primaryBlue,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow() {
    return Row(
      children: [
        Expanded(
          child: _costCard('TOTAL COST', '\$2.44M', '2.1% Over Est.', true),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _costCard(
            "TODAY'S SPEND",
            '\$14,280',
            '8 Invoices',
            false,
            isInvoice: true,
          ),
        ),
      ],
    );
  }

  Widget _costCard(
    String label,
    String value,
    String sub,
    bool isOver, {
    bool isInvoice = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isOver ? const Color(0xFFE040FB) : purple,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textGray,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isInvoice ? Icons.receipt_outlined : Icons.trending_up,
                size: 12,
                color: isOver ? Colors.redAccent : purple,
              ),
              const SizedBox(width: 4),
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isOver ? Colors.redAccent : purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _categoryIcon(Icons.category_outlined, 'Material', primaryBlue),
          _categoryIcon(Icons.people_outline, 'Labour', purple),
          _categoryIcon(
            Icons.construction_outlined,
            'Equipment',
            const Color(0xFF7B3FE7),
          ),
        ],
      ),
    );
  }

  Widget _categoryIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakUpdate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2233DD), Color(0xFF5B3FE0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2233DD).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Speak Update',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI FOREMAN IS LISTENING',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _activityItem(
          Icons.local_shipping_outlined,
          'Concrete Delivery Confirmed',
          'Section 4A • 10:45 AM',
          'On-Site',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 8),
        _activityItem(
          Icons.check_circle_outline,
          'Safety Audit Passed',
          'External Inspector • 09:12 AM',
          'Cleared',
          const Color(0xFFF3E8FF),
          purple,
        ),
        const SizedBox(height: 8),
        _activityItem(
          Icons.warning_amber_outlined,
          'Weather Alert: High Winds',
          'Crane operations suspended • 08:30 AM',
          'Alert',
          const Color(0xFFFFF3E0),
          Colors.orange,
        ),
      ],
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String subtitle,
    String badge,
    Color badgeBg,
    Color badgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
