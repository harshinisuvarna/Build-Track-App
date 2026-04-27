import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Notifications',
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
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today',
                          style: AppTheme.heading2.copyWith(color: textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '3 NEW',
                            style: AppTheme.label.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _criticalAlertCard(),
                    const SizedBox(height: 12),
                    _inventoryWarningCard(),
                    const SizedBox(height: 12),
                    _weeklyReportCard(),
                    const SizedBox(height: 26),
                    Text(
                      'Yesterday',
                      style: AppTheme.heading3.copyWith(color: textGray),
                    ),
                    const SizedBox(height: 12),
                    _yesterdayCard(
                      icon: Icons.check_circle_outline,
                      iconBg: const Color(0xFFF0F2FF),
                      iconColor: primaryBlue,
                      title: 'Safety Audit Completed',
                      body:
                          "The site audit for 'South Wing' was successfully logged by inspector Miller.",
                      time: '1d ago',
                    ),
                    const SizedBox(height: 10),
                    _yesterdayCard(
                      icon: Icons.schedule_outlined,
                      iconBg: const Color(0xFFF5F5F5),
                      iconColor: textGray,
                      title: 'Schedule Update',
                      body:
                          'Arrival of electrical components moved from Tuesday to Wednesday 08:00 AM.',
                      time: '1d ago',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criticalAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: Colors.red.shade400, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withValues(alpha: 0.07), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade400, size: 20),
              ),
              Text('12m ago',
                  style: AppTheme.caption.copyWith(color: textGray)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('CRITICAL ALERT',
                style: AppTheme.label.copyWith(
                    color: Colors.red, fontSize: 10, letterSpacing: 0.9)),
          ]),
          const SizedBox(height: 7),
          Text(
            'Structural Beam Deflection Detected',
            style: AppTheme.heading3
                .copyWith(color: textDark, fontSize: 18, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Sensor 4B in Sector 7 reports stress levels exceeding 15% threshold. Immediate inspection required at the Western support pillar.',
            style: AppTheme.body.copyWith(color: textGray, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text('Resolve',
                      style: AppTheme.body.copyWith(
                          color: Colors.red, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: Color(0xFFDDE0F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text('View Map',
                      style: AppTheme.body.copyWith(
                          color: textDark, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            const Border(left: BorderSide(color: Colors.orange, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EE),
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Colors.orange, size: 20),
              ),
              Text('2h ago',
                  style: AppTheme.caption.copyWith(color: textGray)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('INVENTORY WARNING',
                style: AppTheme.label.copyWith(
                    color: Colors.orange, fontSize: 10, letterSpacing: 0.9)),
          ]),
          const SizedBox(height: 7),
          Text(
            'Low Cement Stock (Phase 2)',
            style: AppTheme.heading3.copyWith(color: textDark, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            "Current supply will be depleted by tomorrow's afternoon shift. Re-order scheduled but requires manual approval.",
            style: AppTheme.body.copyWith(color: textGray, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _weeklyReportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.bar_chart, color: primaryBlue, size: 20),
              ),
              Text('5h ago',
                  style: AppTheme.caption.copyWith(color: textGray)),
            ],
          ),
          const SizedBox(height: 10),
          Text('WEEKLY REPORT',
              style: AppTheme.label.copyWith(
                  color: primaryBlue, fontSize: 10, letterSpacing: 0.9)),
          const SizedBox(height: 7),
          Text(
            'Project Velocity Insight',
            style: AppTheme.heading3.copyWith(color: textDark, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Efficiency on Sector 4 has increased by 12% following the new logistics deployment. View the full technical breakdown.',
            style: AppTheme.body.copyWith(color: textGray, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _yesterdayCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700, color: textDark)),
                const SizedBox(height: 3),
                Text(body,
                    style: AppTheme.caption.copyWith(
                        color: textGray, height: 1.4, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: AppTheme.caption.copyWith(color: textGray)),
        ],
      ),
    );
  }
}
