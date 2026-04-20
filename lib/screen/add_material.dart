import 'package:flutter/material.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  static const errorRed = Color(0xFFD32F2F);

  final _qtyController = TextEditingController(text: '45');
  final _rateController = TextEditingController(text: '120');
  bool _supplierError = true;
  int _selectedNavIndex = 2; // ENTRY is active

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
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
            _buildTopBar(context),
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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          const Text(
            'Add Material',
            style: TextStyle(
                color: primaryBlue, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.list_alt, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _stepCircle('1', filled: true),
            // Dashed line between steps
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
        const Text(
          'STEP 2 OF 2',
          style: TextStyle(
              color: primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
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
          style: TextStyle(
              color: filled ? Colors.white : primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 14),
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
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          const Text('Item name',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: primaryBlue, width: 2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: textGray, size: 18),
                SizedBox(width: 10),
                Text('Premium Ready-Mix Concret',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quantity and Rate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity',
                        style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: primaryBlue, width: 2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 10),
                              ),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textDark),
                            ),
                          ),
                          const Text('m³',
                              style: TextStyle(
                                  color: textGray,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
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
                    const Text('Rate',
                        style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: primaryBlue, width: 2)),
                      ),
                      child: Row(
                        children: [
                          const Text('\$ ',
                              style: TextStyle(
                                  color: textGray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          Expanded(
                            child: TextField(
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 10),
                              ),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textDark),
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

          // Total amount
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL AMOUNT',
                        style: TextStyle(
                            color: textGray,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    SizedBox(height: 4),
                    Text('\$ 5,400.00',
                        style: TextStyle(
                            color: primaryBlue,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3)),
                  ],
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_outlined,
                      color: primaryBlue, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Supplier ID
          RichText(
            text: const TextSpan(
              text: 'Supplier ID ',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
              children: [
                TextSpan(
                  text: '(Required)',
                  style: TextStyle(color: errorRed),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: _supplierError ? errorRed : primaryBlue,
                    width: 2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_outlined,
                    color: textGray, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Select supplier',
                      style: TextStyle(color: textGray, fontSize: 15)),
                ),
                if (_supplierError)
                  const Icon(Icons.error, color: errorRed, size: 22),
              ],
            ),
          ),
          if (_supplierError) ...[
            const SizedBox(height: 6),
            const Text(
              'Please select a valid supplier from the database.',
              style: TextStyle(
                  color: errorRed,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 20),

          // Upload receipt
          const Text('Upload Receipt / Bill',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
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
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: primaryBlue, size: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tap to upload bill',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textDark)),
                  const SizedBox(height: 4),
                  const Text('PNG, JPG OR PDF UP TO 10MB',
                      style: TextStyle(
                          color: textGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _supplierError = false);
        Navigator.pushNamed(context, '/review-voice');
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
                offset: const Offset(0, 5)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Save entry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
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
              _navItem(0, Icons.home_rounded, 'HOME'),
              _navItem(1, Icons.bar_chart_outlined, 'PROJECTS'),
              _navEntryButton(),
              _navItem(3, Icons.inventory_2_outlined, 'INVENTORY'),
              _navItem(4, Icons.assessment_outlined, 'REPORTS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _navEntryButton() {
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

// ── Dashed Line Painter ───────────────────────────────────────────────────────

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