import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  int _tabIndex = 0;
  int _unitIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'SiteTrack',
              rightWidget: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade800,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    _buildTabs(),
                    const SizedBox(height: 14),
                    _buildProjectFilter(),
                    const SizedBox(height: 14),
                    _buildMetricGrid(),
                    const SizedBox(height: 14),
                    _buildChartCard(),
                    const SizedBox(height: 14),
                    _buildCategoryBudget(),
                    const SizedBox(height: 14),
                    _buildEfficiencyReport(context),
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

  Widget _buildTabs() {
    final tabs = ['Monthly', 'Quarterly', 'Yearly'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style:  GoogleFonts.inter(
                    color: active ? Colors.white : textGray,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Project Filter ────────────────────────────────────────────────────────

  Widget _buildProjectFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Active Projects',
            style:  GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: textDark,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: textGray, size: 22),
        ],
      ),
    );
  }

  // ── 4 Metric Cards ────────────────────────────────────────────────────────

  Widget _buildMetricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.credit_card_outlined,
                label: 'TOTAL COST',
                value: r'$2.4M',
                subIcon: Icons.trending_up,
                subText: '12% vs LY',
                subColor: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.architecture,
                label: 'MATERIAL',
                value: r'$842k',
                subIcon: Icons.check_box_outline_blank,
                subText: 'On Track',
                subColor: textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.people_outline,
                label: 'LABOUR',
                value: r'$1.2M',
                subIcon: Icons.trending_up,
                subText: '+4% Over',
                subColor: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.construction_outlined,
                label: 'EQUIPMENT',
                value: r'$318k',
                subIcon: Icons.trending_down,
                subText: '-2% Saving',
                subColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required IconData subIcon,
    required String subText,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style:  GoogleFonts.inter(
              fontSize: 10,
              color: textGray,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:  GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(subIcon, size: 13, color: subColor),
              const SizedBox(width: 4),
              Text(
                subText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: subColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart Card ────────────────────────────────────────────────────────────

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost per Unit',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Concrete pouring efficiency\nvs target',
                    style: GoogleFonts.inter(
                      color: textGray,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDE0F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: ['SQFT', 'CUYD'].asMap().entries.map((e) {
                    final sel = e.key == _unitIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _unitIndex = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            color: sel ? Colors.white : textGray,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _LineChartPainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('WK 12', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
              Text('WK 13', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
              Text('WK 14', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
              Text('WK 15', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
              Text('WK 16', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
              Text('WK 17', style: GoogleFonts.inter(color: textGray, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, color: primaryBlue, size: 10),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  r'Actual: $14.20/sqft',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: textDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.circle, color: Color(0xFFBBC0D0), size: 10),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  r'Target: $13.50/sqft',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: textGray,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category Budget ───────────────────────────────────────────────────────

  Widget _buildCategoryBudget() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            'Category Budget',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 18),
          _budgetBar('STRUCTURAL', 0.82, '82%', primaryBlue),
          const SizedBox(height: 16),
          _budgetBar('ELECTRICAL', 0.45, '45%', const Color(0xFF8B3FE7)),
          const SizedBox(height: 16),
          _budgetBar('FINISHING', 0.18, '18%', const Color(0xFF9B5FFF)),
          const SizedBox(height: 16),
          _budgetBar('LANDSCAPING', 0.95, '95%', Colors.red),
        ],
      ),
    );
  }

  Widget _budgetBar(String label, double val, String pct, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: textDark,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              pct,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val,
            backgroundColor: const Color(0xFFEEF0F8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ── Efficiency Report Banner ──────────────────────────────────────────────

  Widget _buildEfficiencyReport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Efficiency Report',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Labour costs are 12% under budget for this quarter due to optimized scheduling.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Text(
              'View Details',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final actualPaint = Paint()
      ..color = const Color(0xFF2233DD)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final targetPaint = Paint()
      ..color = const Color(0xFFBBC0D0)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final actualPts = [
      Offset(0, size.height * 0.60),
      Offset(size.width * 0.15, size.height * 0.32),
      Offset(size.width * 0.32, size.height * 0.55),
      Offset(size.width * 0.50, size.height * 0.22),
      Offset(size.width * 0.68, size.height * 0.48),
      Offset(size.width * 0.85, size.height * 0.18),
      Offset(size.width, size.height * 0.30),
    ];

    final targetPts = [
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.20, size.height * 0.67),
      Offset(size.width * 0.40, size.height * 0.62),
      Offset(size.width * 0.60, size.height * 0.58),
      Offset(size.width * 0.80, size.height * 0.55),
      Offset(size.width, size.height * 0.52),
    ];

    _drawCurve(canvas, actualPts, actualPaint);
    _drawCurve(canvas, targetPts, targetPaint);
  }

  void _drawCurve(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => false;
}
