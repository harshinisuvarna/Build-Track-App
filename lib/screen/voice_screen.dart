import 'package:flutter/material.dart';

class ReviewVoiceEntryScreen extends StatefulWidget {
  const ReviewVoiceEntryScreen({super.key});

  @override
  State<ReviewVoiceEntryScreen> createState() =>
      _ReviewVoiceEntryScreenState();
}

class _ReviewVoiceEntryScreenState
    extends State<ReviewVoiceEntryScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  int _selectedNavIndex = 2; // ENTRY is active

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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    _buildParsedBanner(),
                    const SizedBox(height: 18),
                    _buildMaterialLogCard(),
                    const SizedBox(height: 22),
                    _buildTranscript(),
                    const SizedBox(height: 34),
                    _buildConfirmButton(context),
                    const SizedBox(height: 24),
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
          const Text('Review voice entry',
              style: TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.grey.shade400,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Parsed Banner ─────────────────────────────────────────────────────────

  Widget _buildParsedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: purple, shape: BoxShape.circle),
            child: const Icon(Icons.verified,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parsed from voice',
                  style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              SizedBox(height: 2),
              Text(
                  'Confidence: 98.4% • Voice timestamp 10:42 AM',
                  style: TextStyle(
                      color: Color(0xFF9B7FD6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Material Log Card ─────────────────────────────────────────────────────

  Widget _buildMaterialLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Material Log',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textDark)),
                  SizedBox(height: 3),
                  Text('Site: North District Phase 2',
                      style: TextStyle(
                          color: textGray, fontSize: 12.5)),
                ],
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.mic, color: purple, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _fieldLabel('NAME'),
          const SizedBox(height: 6),
          _fieldBox('Premium Ready-Mix Concrete (C35)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('QUANTITY'),
                    const SizedBox(height: 6),
                    _fieldBox('12.5 m³'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('RATE'),
                    const SizedBox(height: 6),
                    _fieldBox(r'$145.00'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('TOTAL ESTIMATED'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFDDE0F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(r'$1,812.50',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: primaryBlue,
                        letterSpacing: -0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('AUTO',
                      style: TextStyle(
                          color: primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 11,
            color: textGray,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9));
  }

  Widget _fieldBox(String value) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border:
            Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: textDark)),
    );
  }

  // ── Audio Transcript ──────────────────────────────────────────────────────

  Widget _buildTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.format_align_left,
                color: primaryBlue, size: 15),
            SizedBox(width: 7),
            Text('ORIGINAL AUDIO TRANSCRIPT',
                style: TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3)),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '"Hey SiteTrack, record a material entry for North District. '
          'We just received 12.5 cubic meters of C35 ready-mix concrete. '
          'Rate is fixed at 145 per unit. Confirming receipt for 1,812 '
          'dollars and 50 cents. Log this under structural foundations."',
          style: TextStyle(
              color: textDark,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.65),
        ),
      ],
    );
  }

  // ── Confirm Button ────────────────────────────────────────────────────────

  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamedAndRemoveUntil(
          context, '/home', (route) => false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2233DD), Color(0xFF5B3FE0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
                color: primaryBlue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Confirm and save',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ],
        ),
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
    final isActive = _selectedNavIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 2),
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
            child: const Icon(Icons.add,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            'ENTRY',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isActive ? primaryBlue : textGray,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}