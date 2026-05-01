// lib/common/widgets/subscription_card.dart
//
// A premium gradient card shown on the Profile screen.
// Displays the user's current plan, renewal date, and CTAs.
//
// Usage:
//   const SubscriptionCard()   (reads SubscriptionProvider via context)

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/premium_cta_button.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final plan = sub.currentPlan;
    final isPaid = sub.isPaid;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _gradientFor(plan),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _shadowColorFor(plan),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPaid ? Icons.workspace_premium : Icons.star_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.label} Plan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _StatusBadge(status: sub.status),
                        ],
                      ),
                    ),
                    // Plan badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        plan.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Renewal date ───────────────────────────────────────────
                if (sub.renewalDate != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.autorenew,
                          color: Colors.white60, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Renews ${_fmtDate(sub.renewalDate!)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),

                // ── CTA buttons ────────────────────────────────────────────
                Row(
                  children: [
                    // Primary CTA
                    Expanded(
                      flex: 5,
                      child: PremiumCtaButton(
                        label: isPaid ? 'Manage Plan' : 'Upgrade to Pro',
                        icon: isPaid
                            ? Icons.manage_accounts_rounded
                            : Icons.rocket_launch_rounded,
                        onTap: () =>
                            Navigator.pushNamed(context, '/subscription'),
                        variant: CtaVariant.primary,
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Restore button
                    Expanded(
                      flex: 4,
                      child: PremiumCtaButton(
                        label: 'Restore',
                        icon: Icons.restore_rounded,
                        onTap: () => _onRestore(context, sub),
                        variant: CtaVariant.secondary,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRestore(
      BuildContext context, SubscriptionProvider sub) async {
    await sub.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sub.error.isEmpty
              ? 'Purchases restored successfully!'
              : sub.error,
        ),
        backgroundColor:
            sub.error.isEmpty ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  LinearGradient _gradientFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.pro:
        return const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryPurple, Color(0xFF9B59FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SubscriptionPlan.enterprise:
        return const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SubscriptionPlan.free:
        return const LinearGradient(
          colors: [Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _shadowColorFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.pro:        return AppColors.primaryPurple.withValues(alpha: 0.4);
      case SubscriptionPlan.enterprise: return Colors.black.withValues(alpha: 0.4);
      case SubscriptionPlan.free:       return const Color(0xFF6B7280).withValues(alpha: 0.3);
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Internal badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SubscriptionStatus.active  => 'Active',
      SubscriptionStatus.expired => 'Expired',
      SubscriptionStatus.unknown => 'Unknown',
    };
    final color = switch (status) {
      SubscriptionStatus.active  => const Color(0xFF4ADE80),
      SubscriptionStatus.expired => const Color(0xFFFCA5A5),
      SubscriptionStatus.unknown => const Color(0xFFFCD34D),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


