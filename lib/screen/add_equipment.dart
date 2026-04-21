import 'package:buildtrack_mobile/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});
  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  final _hoursController = TextEditingController(text: '6');
  final _rateController = TextEditingController(text: '85');
  final _nameController = TextEditingController(text: 'Excavator JCB 3CX');
  final _fuelController = TextEditingController(text: '42');
  final _operatorController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _nameController.dispose();
    _fuelController.dispose();
    _operatorController.dispose();
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
              title: 'Add Equipment',
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
          // Equipment Name
          Text(
            'Equipment Name',
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
                const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: textGray,
                  size: 18,
                ),
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

          // Usage Hours & Cost per Hour
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Hours',
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
                      'Cost / Hour',
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

          // Fuel Consumption (Optional)
          Text(
            'Fuel Consumption (Optional)',
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
                const Icon(
                  Icons.local_gas_station_outlined,
                  color: textGray,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fuelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
                Text(
                  'L',
                  style: GoogleFonts.inter(
                    color: textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Operator Name (Optional)
          Text(
            'Operator Name (Optional)',
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
                const Icon(
                  Icons.engineering_outlined,
                  color: textGray,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _operatorController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter operator name',
                      hintStyle: GoogleFonts.inter(
                        color: textGray,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

          // Upload Log
          Text(
            'Upload Equipment Log / Bill',
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File picker would open here')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFCCCFE8),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to upload log',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
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