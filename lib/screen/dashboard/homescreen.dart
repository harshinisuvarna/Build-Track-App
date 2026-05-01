import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/voice_confirmation_sheet.dart';
import 'package:buildtrack_mobile/common/widgets/nurofin_scaffold.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showEntryOptions(BuildContext context, String type) {
    final Map<String, String> voiceRoutes = {
      'material': '/review-material',
      'labour': '/review-labour',
      'equipment': '/review-equipment',
    };
    final Map<String, String> manualRoutes = {
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE0F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How do you want to add?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adding ${type[0].toUpperCase()}${type.substring(1)} entry',
              style: const TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _bottomSheetOption(
              icon: Icons.mic,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEEF0FF),
              title: 'Use Voice',
              subtitle: 'Speak and let AI capture the details',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  voiceRoutes[type]!,
                  arguments: {'type': type},
                );
              },
            ),
            const SizedBox(height: 12),
            _bottomSheetOption(
              icon: Icons.edit_outlined,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFF0EEFF),
              title: 'Enter Manually',
              subtitle: 'Fill the form manually',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  manualRoutes[type]!,
                  arguments: {'type': type},
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.pop(ctx),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NurofinScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'BuildTrack',
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (UserSession.isAdmin)
                      _AdminDashboard(onEntryTap: _showEntryOptions),
                    if (UserSession.isSupervisor) const _SupervisorDashboard(),
                    if (UserSession.isMason)
                      _MasonDashboard(onEntryTap: _showEntryOptions),
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
}

// ADMIN DASHBOARD

// (project list is now driven by ProjectProvider — see _AdminDashboardState)

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard({required this.onEntryTap});
  final void Function(BuildContext, String) onEntryTap;
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  static const primaryBlue = AppColors.primary;
  static const purple = AppColors.primary;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProjectSelector(context, provider),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OVERALL PROGRESS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textGray,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    project != null
                        ? '${(project.progress * 100).toStringAsFixed(1)}%'
                        : '—',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        project?.name ?? 'No project',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        project != null ? project.city : '',
                        style: const TextStyle(color: textGray, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppProgressBar(label: '', percent: project?.progress ?? 0),
            ],
          ),
        ),

        // Cost row
        Row(
          children: [
            Expanded(
              child: _costCard(
                'TOTAL COST',
                project?.formattedSpent ?? '₹—',
                project != null
                    ? '${(project.budgetUtilization * 100).toStringAsFixed(0)}% Used'
                    : '—',
                project != null && project.budgetUtilization > 0.9,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _costCard(
                'BUDGET',
                project?.formattedBudget ?? '₹—',
                'Remaining: ${project?.formattedRemaining ?? '—'}',
                false,
                isInvoice: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AppSectionHeader(title: 'Quick Actions'),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add Project',
                icon: Icons.add_circle_outline,
                onPressed: () => Navigator.pushNamed(context, '/projects'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Reports',
                icon: Icons.bar_chart_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pushNamed(context, '/reports'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Category shortcuts
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _categoryIcon(
                context,
                Icons.category_outlined,
                'Material',
                primaryBlue,
                type: 'material',
              ),
              _categoryIcon(
                context,
                Icons.people_outline,
                'Labour',
                purple,
                type: 'labour',
              ),
              _categoryIcon(
                context,
                Icons.construction_outlined,
                'Equipment',
                const Color(0xFF7B3FE7),
                type: 'equipment',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Speak update
        _buildSpeakUpdate(context),
        const SizedBox(height: 14),

        // Recent activity
        _buildRecentActivity(context),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildProjectSelector(BuildContext context, ProjectProvider provider) {
    final selectedName = provider.selectedProject?.name ?? 'Select Project';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showProjectPicker(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.architecture, color: primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    selectedName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down, color: textGray),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectPicker(BuildContext context, ProjectProvider provider) {
    final projects = provider.projects;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Select Project',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...projects.map((p) {
                final selected = p.id == provider.selectedProject?.id;
                return InkWell(
                  onTap: () {
                    provider.selectProject(p);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryBlue.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? primaryBlue : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected ? primaryBlue : textGray,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? primaryBlue : textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costCard(
    String label,
    String value,
    String sub,
    bool isOver, {
    bool isInvoice = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isOver ? const Color(0xFFE040FB) : purple,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textGray,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isInvoice ? Icons.receipt_outlined : Icons.trending_up,
                size: 13,
                color: isOver ? Colors.redAccent : purple,
              ),
              const SizedBox(width: 4),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: isOver ? Colors.redAccent : purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color, {
    required String type,
  }) {
    return InkWell(
      onTap: () => widget.onEntryTap(context, type),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakUpdate(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showVoiceConfirmationSheet(context),
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Speak Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'AI FOREMAN IS LISTENING',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      children: [
        AppSectionHeader(
          title: 'Recent Activity',
          actionLabel: 'View All',
          onAction: () => Navigator.pushNamed(context, '/notifications'),
        ),
        const SizedBox(height: 8),
        _activityItem(
          context,
          Icons.local_shipping_outlined,
          'Concrete Delivery Confirmed',
          'Section 4A • 10:45 AM',
          'On-Site',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          type: 'material',
          name: 'Concrete',
        ),
        const SizedBox(height: 8),
        _activityItem(
          context,
          Icons.check_circle_outline,
          'Safety Audit Passed',
          'External Inspector • 09:12 AM',
          'Cleared',
          const Color(0xFFF3E8FF),
          purple,
          type: 'material',
          name: 'Safety Audit',
        ),
        const SizedBox(height: 8),
        _activityItem(
          context,
          Icons.warning_amber_outlined,
          'Weather Alert: High Winds',
          'Crane operations suspended • 08:30 AM',
          'Alert',
          const Color(0xFFFFF3E0),
          Colors.orange,
          type: 'equipment',
          name: 'Crane',
        ),
      ],
    );
  }

  Widget _activityItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String badge,
    Color badgeBg,
    Color badgeColor, {
    required String type,
    required String name,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/logs',
          arguments: {'type': type, 'name': name},
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.5, color: textGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SUPERVISOR DASHBOARD

class _SupervisorDashboard extends StatefulWidget {
  const _SupervisorDashboard();

  @override
  State<_SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<_SupervisorDashboard> {
  static const _pendingItems = [
    {
      'mason': 'Rajan Kumar',
      'task': 'Column Casting – Level 3',
      'time': 'Submitted • 08:30 AM',
      'floor': 'Floor 3 • Block A',
    },
    {
      'mason': 'Suresh Babu',
      'task': 'Slab Reinforcement – Level 2',
      'time': 'Submitted • 09:15 AM',
      'floor': 'Floor 2 • Block B',
    },
    {
      'mason': 'Anwar Sheikh',
      'task': 'Plinth Beam Work',
      'time': 'Submitted • 10:00 AM',
      'floor': 'Ground • Parking',
    },
  ];

  // 'pending' | 'approved' | 'rejected'
  late List<String> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = List.filled(_pendingItems.length, 'pending');
  }

  void _approve(int i) {
    setState(() => _statuses[i] = 'approved');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_pendingItems[i]['task']} approved'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reject(int i) {
    setState(() => _statuses[i] = 'rejected');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_pendingItems[i]['task']} rejected'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _statuses.where((s) => s == 'pending').length;
    final approvedCount = _statuses.where((s) => s == 'approved').length;
    final rejectedCount = _statuses.where((s) => s == 'rejected').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips
        Row(
          children: [
            _summaryChip('$pendingCount', 'Pending', AppTheme.warning),
            const SizedBox(width: 10),
            _summaryChip(
              '${approvedCount + 12}',
              'Approved Today',
              AppTheme.success,
            ),
            const SizedBox(width: 10),
            _summaryChip('$rejectedCount', 'Rejected', AppTheme.error),
          ],
        ),
        const SizedBox(height: 16),
        const AppSectionHeader(title: 'Pending Approvals'),
        ...List.generate(
          _pendingItems.length,
          (i) => _pendingCard(context, _pendingItems[i], i),
        ),
        const SizedBox(height: 8),
        const AppSectionHeader(title: 'Recent Updates'),
        AppCard(
          child: Column(
            children: [
              _recentRow(
                'Beam Casting – Level 1',
                'Mohan Singh',
                AppStatus.completed,
              ),
              const AppDivider(verticalPadding: 8),
              _recentRow(
                'Plastering – East Wing',
                'Ravi Teja',
                AppStatus.inProgress,
              ),
              const AppDivider(verticalPadding: 8),
              _recentRow(
                'Curing – Ground Slab',
                'Pradeep K',
                AppStatus.delayed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard(
    BuildContext context,
    Map<String, String> item,
    int index,
  ) {
    final status = _statuses[index];
    final isPending = status == 'pending';

    // Status badge color
    Color badgeColor;
    String badgeLabel;
    if (status == 'approved') {
      badgeColor = Colors.green;
      badgeLabel = 'Approved';
    } else if (status == 'rejected') {
      badgeColor = Colors.red;
      badgeLabel = 'Rejected';
    } else {
      badgeColor = AppTheme.warning;
      badgeLabel = 'Pending';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['mason']!,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item['time']!,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  item['floor']!,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(item['task']!, style: AppTheme.heading3)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  icon: Icons.check_circle_outline,
                  onPressed: isPending ? () => _approve(index) : () {},
                  enabled: isPending,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  onPressed: isPending ? () => _reject(index) : () {},
                  enabled: isPending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentRow(String task, String mason, AppStatus status) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task,
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(mason, style: AppTheme.caption),
            ],
          ),
        ),
        AppStatusBadge(status: status),
      ],
    );
  }
}

// MASON DASHBOARD

class _MasonDashboard extends StatelessWidget {
  const _MasonDashboard({required this.onEntryTap});
  final void Function(BuildContext, String) onEntryTap;

  static const _tasks = [
    {
      'task': 'Column Casting – Level 3',
      'phase': 'Superstructure',
      'status': 'In Progress',
    },
    {
      'task': 'Slab Reinforcement – Level 3',
      'phase': 'Superstructure',
      'status': 'Not Started',
    },
    {
      'task': 'Curing – Level 2 Slab',
      'phase': 'Superstructure',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting card
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning, Mason', style: AppTheme.heading3),
                  Text(
                    'You have ${_tasks.length} tasks today',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Add Entry button (primary action)
        AppButton(
          label: 'Add Daily Update',
          icon: Icons.add_circle_outline,
          onPressed: () => Navigator.pushNamed(context, '/update-progress'),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Add Material Entry',
          icon: Icons.category_outlined,
          variant: AppButtonVariant.outline,
          onPressed: () => onEntryTap(context, 'material'),
        ),
        const SizedBox(height: 16),

        // Today's tasks
        const AppSectionHeader(title: "Today's Tasks"),
        ..._tasks.map((t) => _taskCard(t)),
      ],
    );
  }

  Widget _taskCard(Map<String, String> task) {
    final statusMap = {
      'Completed': AppStatus.completed,
      'In Progress': AppStatus.inProgress,
      'Not Started': AppStatus.notStarted,
    };

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['task']!,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(task['phase']!, style: AppTheme.caption),
              ],
            ),
          ),
          AppStatusBadge(
            status: statusMap[task['status']] ?? AppStatus.notStarted,
          ),
        ],
      ),
    );
  }
}
