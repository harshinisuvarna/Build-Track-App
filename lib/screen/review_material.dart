import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewVoiceEntryScreen extends StatefulWidget {
  const ReviewVoiceEntryScreen({super.key});
  @override
  State<ReviewVoiceEntryScreen> createState() => _ReviewVoiceEntryScreenState();
}

class _ReviewVoiceEntryScreenState extends State<ReviewVoiceEntryScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  // ✅ FIX: receipt attachment state + confirm loading state
  String? _receiptFile;
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
              rightWidget: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.grey, size: 18),
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r'$1,812.50',
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
        GestureDetector(
          onTap: _receiptFile == null
              ? () {
                  setState(
                    () => _receiptFile =
                        'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt attached')),
                  );
                }
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _receiptFile != null
                  ? const Color(0xFFEEF8EE)
                  : const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _receiptFile != null
                    ? Colors.green.shade300
                    : const Color(0xFFCCCFE8),
                width: 1.5,
              ),
            ),
            child: _receiptFile != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt attached',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textDark,
                              ),
                            ),
                            Text(
                              _receiptFile!,
                              style: GoogleFonts.inter(
                                color: textGray,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ✅ FIX: remove (❌) button
                      GestureDetector(
                        onTap: () => setState(() => _receiptFile = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to attach receipt',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PNG, JPG OR PDF UP TO 10MB',
                        style: GoogleFonts.inter(
                          color: textGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
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
          'dollars and 50 cents. Log this under structural foundations."',
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
      child: AnimatedOpacity(
        opacity: _isConfirming ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
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
