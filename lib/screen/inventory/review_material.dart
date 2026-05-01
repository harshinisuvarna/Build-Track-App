import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';

class ReviewVoiceEntryScreen extends StatefulWidget {
  const ReviewVoiceEntryScreen({super.key});
  @override
  State<ReviewVoiceEntryScreen> createState() => _ReviewVoiceEntryScreenState();
}

class _ReviewVoiceEntryScreenState extends State<ReviewVoiceEntryScreen> {
  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  PickedAttachment? _attachment;

  // ✅ FIX: receipt attachment state + confirm loading state
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Review voice entry',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
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
                    // ✅ FIX: receipt attachment section
                    _buildReceiptSection(),
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
      bottomNavigationBar: const AppBottomNav(),
    );
  }

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
              color: purple,
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
                    color: purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: 98.4% • Voice timestamp 10:42 AM',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9B7FD6),
                    fontSize: 12,
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

  Widget _buildMaterialLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material Log',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Site: North District Phase 2',
                    style: GoogleFonts.inter(color: textGray, fontSize: 12.5),
                  ),
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
                    _fieldBox(r'₹145.00'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('TOTAL ESTIMATED'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r'₹1,812.50',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'AUTO',
                    style: GoogleFonts.inter(
                      color: primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  // ✅ FIX: receipt attachment section identical to manual entry screens
  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Receipt (Optional)',
          style: GoogleFonts.inter(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        UploadBox(
          attachment: _attachment,
          emptyLabel: 'Tap to attach receipt',
          onPicked: (a) => setState(() => _attachment = a),
          onRemove: () => setState(() => _attachment = null),
        ),
      ],
    );
  }

  Widget _buildTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.format_align_left, color: primaryBlue, size: 15),
            const SizedBox(width: 7),
            Text(
              'ORIGINAL AUDIO TRANSCRIPT',
              style: GoogleFonts.inter(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"Hey SiteTrack, record a material entry for North District. '
          'We just received 12.5 cubic meters of C35 ready-mix concrete. '
          'Rate is fixed at 145 per unit. Confirming receipt for 1,812 '
          'rupees and 50 paise. Log this under structural foundations."',
          style: GoogleFonts.inter(
            color: textDark,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // ✅ FIX: loading state prevents double-tap
  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: _isConfirming
          ? null
          : () async {
              setState(() => _isConfirming = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (!mounted) return;
              Navigator.pop(context);
            },
      child: AnimatedOpacity(
        opacity: _isConfirming ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _isConfirming
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 22,
                    ),
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
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: textGray,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _fieldBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 15.5,
          color: textDark,
        ),
      ),
    );
  }
}
