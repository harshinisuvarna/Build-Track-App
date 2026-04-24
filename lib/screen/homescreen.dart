import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/voice_confirmation_sheet.dart';
import 'package:flutter/material.dart';

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
  // FIX 5: Darkened from 0xFF7B8A9E → 0xFF5A6B82 for outdoor readability
  static const textGray = Color(0xFF5A6B82);

  // ── Reusable bottom sheet: Voice or Manual ────────────────────────────────
  void _showEntryOptions(BuildContext context, String type) {
    final Map<String, String> voiceRoutes = {
      'material': '/review-material',
      'labour': '/review-labour',
      'equipment': '/review-equipment',
    };
    final Map<String, String> manualRoutes = {
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
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE0F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How do you want to add?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Adding ${type[0].toUpperCase()}${type.substring(1)} entry',
              // FIX 5: bumped from 13 → 14
              style: const TextStyle(color: textGray, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _bottomSheetOption(
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
            _bottomSheetOption(
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
            // FIX 1: GestureDetector → InkWell for Cancel
            InkWell(
              onTap: () => Navigator.pop(ctx),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: textGray,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // FIX 1: GestureDetector → Material + InkWell
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
            border: Border.all(color: const Color(0xFFE0E5FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
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
                    const SizedBox(height: 2),
                    Text(subtitle,
                        // FIX 5: bumped from 12.5 → 13.5
                        style: const TextStyle(
                            fontSize: 13.5, color: textGray)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: textGray, size: 20),
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
            // ── Pinned top bar — never scrolls ─────────────────────────
            AppTopBar(
              title: 'SiteTrack',
              rightWidget: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade800,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
            // ── Scrollable screen body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
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
                          // FIX 3: bottom padding so last item clears nav bar
                          const SizedBox(height: 100),
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
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  // ── Project Selector ──────────────────────────────────────────────────────

  Widget _buildProjectSelector() {
    // FIX 1: Wrap in InkWell so dropdown tap has ripple
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {}, // placeholder for future dropdown
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.architecture, color: primaryBlue, size: 18),
                    SizedBox(width: 8),
                    Text('Skyline Residences Phase II',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: textDark)),
                  ],
                ),
                Icon(Icons.keyboard_arrow_down, color: textGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress Card ─────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX 5: bumped from 11 → 12
          const Text('OVERALL PROGRESS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textGray,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('68.4%',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: textDark)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('12 Days Ahead',
                      style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  // FIX 5: bumped from 12 → 13
                  Text('Target: Oct 24',
                      style: TextStyle(color: textGray, fontSize: 13)),
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

  // ── Cost Row ──────────────────────────────────────────────────────────────

  Widget _buildCostRow() {
    return Row(
      children: [
        Expanded(
            child: _costCard('TOTAL COST', '\$2.44M', '2.1% Over Est.', true)),
        const SizedBox(width: 12),
        Expanded(
            child: _costCard("TODAY'S SPEND", '\$14,280', '8 Invoices', false,
                isInvoice: true)),
      ],
    );
  }

  Widget _costCard(String label, String value, String sub, bool isOver,
      {bool isInvoice = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(
                color: isOver ? const Color(0xFFE040FB) : purple, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX 5: bumped from 11 → 12
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: textGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                  isInvoice ? Icons.receipt_outlined : Icons.trending_up,
                  size: 13,
                  color: isOver ? Colors.redAccent : purple),
              const SizedBox(width: 4),
              // FIX 5: bumped from 11 → 12
              Text(sub,
                  style: TextStyle(
                      fontSize: 12,
                      color: isOver ? Colors.redAccent : purple,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category Icons ────────────────────────────────────────────────────────

  Widget _buildCategoryIcons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _categoryIcon(Icons.category_outlined, 'Material', primaryBlue,
              type: 'material'),
          _categoryIcon(Icons.people_outline, 'Labour', purple,
              type: 'labour'),
          _categoryIcon(Icons.construction_outlined, 'Equipment',
              const Color(0xFF7B3FE7),
              type: 'equipment'),
        ],
      ),
    );
  }

  Widget _categoryIcon(IconData icon, String label, Color color,
      {required String type}) {
    // FIX 1: GestureDetector → InkWell + FIX 4: min 48px touch target via padding
    return InkWell(
      onTap: () => _showEntryOptions(context, type),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
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
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textDark)),
          ],
        ),
      ),
    );
  }

  // ── Speak Update ──────────────────────────────────────────────────────────

  Widget _buildSpeakUpdate() {
    // FIX 1: GestureDetector → Material + InkWell with splash
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showVoiceConfirmationSheet(context),
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Ink(
          width: double.infinity,
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
                  offset: const Offset(0, 6)),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Speak Update',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                SizedBox(height: 6),
                // FIX 5: bumped from 11 → 12
                Text('AI FOREMAN IS LISTENING',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────────

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark)),
            // FIX 4: TextButton already has good touch target
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              child: const Text('View All',
                  style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
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
            type: 'material',
            name: 'Concrete'),
        const SizedBox(height: 8),
        _activityItem(
            Icons.check_circle_outline,
            'Safety Audit Passed',
            'External Inspector • 09:12 AM',
            'Cleared',
            const Color(0xFFF3E8FF),
            purple,
            type: 'material',
            name: 'Safety Audit'),
        const SizedBox(height: 8),
        _activityItem(
            Icons.warning_amber_outlined,
            'Weather Alert: High Winds',
            'Crane operations suspended • 08:30 AM',
            'Alert',
            const Color(0xFFFFF3E0),
            Colors.orange,
            type: 'equipment',
            name: 'Crane'),
      ],
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String subtitle,
    String badge,
    Color badgeBg,
    Color badgeColor, {
    required String type,
    required String name,
  }) {
    // FIX 1: GestureDetector → Material + InkWell
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/logs',
            arguments: {'type': type, 'name': name}),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        // FIX 5: bumped from 11.5 → 12.5
                        style: const TextStyle(
                            fontSize: 12.5, color: textGray)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(badge,
                    // FIX 5: bumped from 11 → 12
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}