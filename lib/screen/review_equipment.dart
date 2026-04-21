import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewEquipmentEntryScreen extends StatelessWidget {
  const ReviewEquipmentEntryScreen({super.key});

  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  static const voicePurple = Color(0xFF6C3FC8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back, color: textDark, size: 22),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Review voice entry',
                        style: GoogleFonts.inter(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: const NetworkImage(
                      'https://i.pravatar.cc/150?img=5',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildVoiceBanner(),
                    const SizedBox(height: 20),
                    _buildEquipmentCard(context),
                    const SizedBox(height: 20),
                    _buildTranscript(),
                    const SizedBox(height: 32),
                    _buildConfirmButton(context),
                    const SizedBox(height: 24),
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

  Widget _buildVoiceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: voicePurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parsed from voice',
                  style: GoogleFonts.inter(
                    color: voicePurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: 97.2% • Voice timestamp 11:30 AM',
                  style: GoogleFonts.inter(
                    color: voicePurple.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipment Log',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Site: North District Phase 2',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice input active'),
                    duration: Duration(seconds: 1),
                  ),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic, color: primaryBlue, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _label('EQUIPMENT NAME'),
          const SizedBox(height: 8),
          _box('Excavator JCB 3CX (Unit 04)'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('USAGE HOURS'),
                    const SizedBox(height: 8),
                    _box('6 hrs'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('COST / HOUR'),
                    const SizedBox(height: 8),
                    _box('\$85.00'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _label('FUEL CONSUMPTION'),
          const SizedBox(height: 8),
          _box('42 L'),
          const SizedBox(height: 18),
          _label('TOTAL ESTIMATED'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$510.00',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryBlue.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'AUTO',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.subject, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              'ORIGINAL AUDIO TRANSCRIPT',
              style: GoogleFonts.inter(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"Hey SiteTrack, log equipment usage for North District. Excavator JCB 3CX unit 04 ran for 6 hours today. Rate is 85 dollars per hour. Fuel consumed was 42 liters. Total cost is 510 dollars. Log under earthworks and excavation."',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textGray,
            fontStyle: FontStyle.italic,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
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
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Confirm and save',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textGray,
          letterSpacing: 0.8,
        ),
      );

  Widget _box(String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      );
}