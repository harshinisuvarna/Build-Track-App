import 'package:buildtrack_mobile/screen/add_project.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF9B59B6);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProjectScreen()),
          );
        },
        backgroundColor: primaryBlue,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LIVE PIPELINE',
                        style: GoogleFonts.inter(
                          color: primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Active Builds',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '12 Sites',
                            style: GoogleFonts.inter(
                              color: primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _projectCard(
                      context: context,
                      name: 'Northwest Tech Park',
                      location: 'Bellingham, WA • Sector 04',
                      stage: 'FOUNDATION',
                      stageBg: const Color(0xFFEEEFFF),
                      stageColor: const Color(0xFF4455CC),
                      progress: 0.34,
                      percent: '34%',
                      avatarColors: const [
                        Color(0xFF5B6CF6),
                        Color(0xFF9C59B5),
                      ],
                      extraCount: 4,
                    ),
                    const SizedBox(height: 16),
                    _projectCard(
                      context: context,
                      name: 'Summit Heights Condos',
                      location: 'Denver, CO • Unit B',
                      stage: 'STRUCTURE',
                      stageBg: const Color(0xFFF3E8FF),
                      stageColor: purple,
                      progress: 0.68,
                      percent: '68%',
                      avatarColors: const [
                        Color(0xFF5B6CF6),
                        Color(0xFF9C59B5),
                      ],
                      extraCount: 0,
                    ),
                    const SizedBox(height: 16),
                    _projectCard(
                      context: context,
                      name: 'The Grand Atrium',
                      location: 'Austin, TX • Main Plaza',
                      stage: 'FINISHING',
                      stageBg: const Color(0xFFE8F5E9),
                      stageColor: const Color(0xFF2E7D32),
                      progress: 0.92,
                      percent: '92%',
                      avatarColors: const [Color(0xFF2ECC71)],
                      extraCount: 0,
                    ),
                    const SizedBox(height: 80), // space so FAB doesn't cover last card
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

  Widget _projectCard({
    required BuildContext context,
    required String name,
    required String location,
    required String stage,
    required Color stageBg,
    required Color stageColor,
    required double progress,
    required String percent,
    required List<Color> avatarColors,
    required int extraCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: stageBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stage,
                  style: GoogleFonts.inter(
                    color: stageColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            location,
            style: GoogleFonts.inter(
              color: textGray,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                percent,
                style: GoogleFonts.inter(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE8ECF8),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF0F5), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _avatarRow(avatarColors, extraCount),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/update-progress'),
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: primaryBlue, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarRow(List<Color> colors, int extra) {
    return Row(
      children: [
        ...List.generate(colors.length, (i) {
          return Transform.translate(
            offset: Offset(i * -9.0, 0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          );
        }),
        if (extra > 0)
          Transform.translate(
            offset: Offset(colors.length * -9.0, 0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$extra',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}