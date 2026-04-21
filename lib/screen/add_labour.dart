import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});
  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  final _hoursController = TextEditingController(text: '8');
  final _rateController = TextEditingController(text: '18');
  final _nameController = TextEditingController(text: 'Rajesh Kumar & Team');
  final _workTypeController = TextEditingController(text: 'Masonry');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _nameController.dispose();
    _workTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Add Labour',
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
                    _buildStepIndicator(),
                    const SizedBox(height: 18),
                    _buildFormCard(),
                    const SizedBox(height: 28),
                    _buildSaveButton(context),
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

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _stepCircle('1', filled: true),
            SizedBox(
              width: 36,
              child: CustomPaint(
                painter: _DashedLinePainter(),
                size: const Size(36, 2),
              ),
            ),
            _stepCircle('2', filled: true),
          ],
        ),
        Text(
          'STEP 2 OF 2',
          style: GoogleFonts.inter(
            color: primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _stepCircle(String label, {required bool filled}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: filled ? primaryBlue : const Color(0xFFEEF0FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: filled ? Colors.white : primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          // Worker / Team Name
          Text(
            'Worker / Team Name',
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: textGray, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Work Type
          Text(
            'Work Type',
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline, color: textGray, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _workTypeController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g. Masonry, Plumbing',
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hours Worked & Rate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours Worked',
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hoursController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 10,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                          ),
                          Text(
                            'hrs',
                            style: GoogleFonts.inter(
                              color: textGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate',
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '\$ ',
                            style: GoogleFonts.inter(
                              color: textGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 10,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Total Amount Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: GoogleFonts.inter(
                        color: textGray,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$ ${_computeTotal()}',
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notes (optional)
          Text(
            'Notes (Optional)',
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCCFE8), width: 1.5),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add any site notes or remarks…',
                hintStyle: GoogleFonts.inter(
                  color: textGray,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _computeTotal() {
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = hours * rate;
    return total.toStringAsFixed(2);
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
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
            Text(
              'Save entry',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = const Color(0xFF2233DD)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}