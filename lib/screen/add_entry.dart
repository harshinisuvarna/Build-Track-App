import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  static const primaryBlue = Color(0xFF2233DD);
  static const purple = Color(0xFF6B3FE7);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF5A6B82); // FIX 5: darker

  static const List<Map<String, dynamic>> _entries = [
    {
      'icon': Icons.category,
      'title': 'Material',
      'subtitle': 'Log concrete, steel, lumber, or site-specific procurement items.',
      'type': 'material',
    },
    {
      'icon': Icons.people,
      'title': 'Labour',
      'subtitle': 'Track crew hours, specialized trade performance, and site presence.',
      'type': 'labour',
    },
    {
      'icon': Icons.precision_manufacturing,
      'title': 'Equipment',
      'subtitle': 'Record heavy machinery runtime, fuel logs, and maintenance events.',
      'type': 'equipment',
    },
  ];

  // ── Bottom sheet: Voice or Manual entry ─────────────────────────────────
  void _showEntryOptions(BuildContext context, String type) {
    const Map<String, String> voiceRoutes = {
      'material': '/review-material',
      'labour': '/review-labour',
      'equipment': '/review-equipment',
    };
    const Map<String, String> manualRoutes = {
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How do you want to add?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Adding ${type[0].toUpperCase()}${type.substring(1)} entry',
                style: GoogleFonts.inter(color: textGray, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Use Voice
              _bottomSheetOption(
                icon: Icons.mic,
                iconColor: primaryBlue,
                iconBg: const Color(0xFFEEF0FF),
                title: 'Use Voice',
                subtitle: 'Speak and let AI capture the details',
                onTap: () {
                  Navigator.pop(ctx);
                  final route = voiceRoutes[type];
                  if (route != null) {
                    Navigator.pushNamed(
                      context,
                      route,
                      arguments: {'type': type},
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Enter Manually
              _bottomSheetOption(
                icon: Icons.edit_outlined,
                iconColor: purple,
                iconBg: const Color(0xFFF0EEFF),
                title: 'Enter Manually',
                subtitle: 'Fill the form manually',
                onTap: () {
                  Navigator.pop(ctx);
                  final route = manualRoutes[type];
                  if (route != null) {
                    Navigator.pushNamed(
                      context,
                      route,
                      arguments: {'type': type},
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

            // FIX 1 + 4: InkWell with padding for bigger touch target
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet option tile ─────────────────────────────────────────────
  Widget _bottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: textGray,
                      ),
                    ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'What are you\nadding?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select the entry type to log for the current shift.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: textGray,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 34),
                    ...List.generate(_entries.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _entryCard(context, index),
                      );
                    }),
                    // FIX 3: bottom padding so last card clears nav bar
                    const SizedBox(height: 100),
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

  // ── Entry card ───────────────────────────────────────────────────────────
  Widget _entryCard(BuildContext context, int index) {
    final entry = _entries[index];
    final String type = entry['type'] as String;

    // Restore original icon colors per type
    final Map<String, Color> iconColors = {
      'material': primaryBlue,
      'labour': purple,
      'equipment': const Color(0xFF7B3FE7),
    };
    final Map<String, Color> iconBgColors = {
      'material': primaryBlue.withValues(alpha: 0.1),
      'labour': purple.withValues(alpha: 0.1),
      'equipment': const Color(0xFF7B3FE7).withValues(alpha: 0.1),
    };
    final Color iconColor = iconColors[type] ?? primaryBlue;
    final Color iconBg = iconBgColors[type] ?? const Color(0xFFF0F2F8);

    // FIX 1: Material + InkWell for ripple
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showEntryOptions(context, type),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry['icon'] as IconData, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry['subtitle'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textGray, // FIX 5: uses darker textGray
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right, color: textGray.withValues(alpha: 0.5), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}