import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — call this from anywhere to show the sheet
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showVoiceConfirmationSheet(
  BuildContext context, {
  /// Optionally pass a pre-detected type ('material'|'labour'|'equipment')
  /// Leave null to simulate AI detection (shows loading state first)
  String? detectedType,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => VoiceConfirmationSheet(initialType: detectedType),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────
class VoiceConfirmationSheet extends StatefulWidget {
  final String? initialType;
  const VoiceConfirmationSheet({super.key, this.initialType});

  @override
  State<VoiceConfirmationSheet> createState() => _VoiceConfirmationSheetState();
}

/// Sheet has 3 phases
enum _SheetPhase { loading, detected, editing }

class _VoiceConfirmationSheetState extends State<VoiceConfirmationSheet>
    with TickerProviderStateMixin {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const _blue = Color(0xFF2233DD);
  static const _purple = Color(0xFF6B3FE7);
  static const _bgColor = Color(0xFFF4F6FB);
  static const _textDark = Color(0xFF0F1724);
  static const _textGray = Color(0xFF5A6B82);

  static const _types = {
    'material': (
      icon: Icons.inventory_2_outlined,
      label: 'Material Entry',
      route: '/review-material',
    ),
    'labour': (
      icon: Icons.people_outline,
      label: 'Labour Entry',
      route: '/review-labour',
    ),
    'equipment': (
      icon: Icons.construction_outlined,
      label: 'Equipment Entry',
      route: '/review-equipment',
    ),
  };

  // ── State ──────────────────────────────────────────────────────────────────
  _SheetPhase _phase = _SheetPhase.loading;
  String _selectedType = 'labour'; // will be replaced after "AI detection"

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Outer mic pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Waveform
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Content fade-in
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _phase = _SheetPhase.detected;
      _fadeCtrl.forward();
    } else {
      // Simulate 1.6s AI analysis
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() {
          _selectedType = 'labour'; // ← replace with real AI result
          _phase = _SheetPhase.detected;
        });
        _fadeCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _confirmAndNavigate() {
    final route = _types[_selectedType]!.route;
    Navigator.pop(context);
    Navigator.pushNamed(context, route, arguments: {'type': _selectedType});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 14, 20,
        20 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE0F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          // ── Mic + waveform header
          _buildMicHeader(),
          const SizedBox(height: 20),

          // ── Phase content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _phase == _SheetPhase.loading
                ? _buildLoadingState()
                : _buildDetectedContent(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mic header (always visible)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMicHeader() {
    return Column(
      children: [
        // Pulsing mic
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final scale = 1.0 + (_pulseCtrl.value * 0.18);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 76 * scale,
                  height: 76 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: 0.07 * (1 - _pulseCtrl.value)),
                  ),
                ),
                // Mid ring
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: 0.12),
                  ),
                ),
                // Core gradient circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_blue, _purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 26),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Waveform bars
        _buildWaveform(),
        const SizedBox(height: 14),

        Text(
          _phase == _SheetPhase.loading
              ? 'Analysing Voice...'
              : 'Voice Entry Detected',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phase == _SheetPhase.loading
              ? 'Please wait while AI processes your input'
              : 'We analysed your voice input',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(9, (i) {
            final phase = _waveCtrl.value + (i / 9);
            final height = 6 + 18 * math.pow(math.sin(phase * math.pi * 2).abs(), 0.6);
            return Container(
              width: 4,
              height: height.toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [_blue, _purple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Padding(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_blue.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Processing voice data...',
                  style: GoogleFonts.inter(
                    color: _textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Detected + Editing content
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDetectedContent() {
    return FadeTransition(
      key: const ValueKey('detected'),
      opacity: _fadeAnim,
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Detected type card
          _buildTypeCard(),
          const SizedBox(height: 14),
          // Change type pills (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _phase == _SheetPhase.editing
                ? _buildTypePills()
                : const SizedBox.shrink(),
          ),

          // Confirm button
          _buildConfirmButton(),
          const SizedBox(height: 10),

          // Change type / Back button
          if (_phase == _SheetPhase.detected)
            _buildOutlinedButton(
              label: 'Change Type',
              icon: Icons.swap_horiz_rounded,
              onTap: () => setState(() => _phase = _SheetPhase.editing),
            )
          else
            _buildOutlinedButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onTap: () => setState(() => _phase = _SheetPhase.detected),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Detected type card ───────────────────────────────────────────────────
  Widget _buildTypeCard() {
    final t = _types[_selectedType]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_blue, _purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(t.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Type',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textGray,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.label,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blue.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.check, color: _blue, size: 18),
          ),
        ],
      ),
    );
  }


  // ── Selectable type pills ─────────────────────────────────────────────────
  Widget _buildTypePills() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'SELECT ENTRY TYPE',
              style: GoogleFonts.inter(
                color: _textGray,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Row(
            children: _types.entries.map((e) {
              final selected = e.key == _selectedType;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? _blue : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _blue : const Color(0xFFDDE0F0),
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          e.value.icon,
                          color: selected ? Colors.white : _textGray,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.value.label.split(' ').first, // "Material", "Labour" etc.
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Confirm (gradient) button ─────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _confirmAndNavigate,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Confirm',
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

  // ── Outlined secondary button ─────────────────────────────────────────────
  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _blue, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _blue, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: _blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
