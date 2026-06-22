import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/nurofin_scaffold.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- TASK 3: Imported API Service ---
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/models/project_model.dart';

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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How do you want to add?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adding ${type[0].toUpperCase()}${type.substring(1)} entry',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BuildTrack Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${UserSession.roleLabel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
  leading: const Icon(
    Icons.supervisor_account_outlined,
    color: AppColors.textDark,
  ),
  title: const Text(
    'Team Overview',
    style: TextStyle(color: AppColors.textDark),
  ),
  onTap: () => Navigator.pushNamed(context, '/admin-overview'),
),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.textDark),
            title: const Text(
              'Profile',
              style: TextStyle(color: AppColors.textDark),
            ),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          if (UserSession.isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
              child: Text(
                'Admin Controls',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.workspaces_outline,
                color: AppColors.textDark,
              ),
              title: const Text(
                'Create Workspace',
                style: TextStyle(color: AppColors.textDark),
              ),
              onTap: () => Navigator.pushNamed(context, '/create-workspace'),
            ),
            ListTile(
              leading: const Icon(
                Icons.manage_accounts_outlined,
                color: AppColors.textDark,
              ),
              title: const Text(
                'Assign Roles',
                style: TextStyle(color: AppColors.textDark),
              ),
              onTap: () => Navigator.pushNamed(context, '/assign-role'),
            ),
            ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textDark,
              ),
              title: const Text(
                'Transaction Logs',
                style: TextStyle(color: AppColors.textDark),
              ),
              onTap: () => Navigator.pushNamed(context, '/logs'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NurofinScaffold(
      drawer: _buildDrawer(context),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (ctx) => Column(
            children: [
              AppTopBar(
                title: 'BuildTrack',
                leftIcon: Icons.menu,
                onLeftTap: () => Scaffold.of(ctx).openDrawer(),
                rightWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.grey.shade800,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
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
                      if (UserSession.isSupervisor)
                        const _SupervisorDashboard(),
                      if (UserSession.isMason)
                        _MasonDashboard(onEntryTap: _showEntryOptions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}

// ADMIN DASHBOARD
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
        const ApprovalsAlertWidget(),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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
                    style: TextStyle(
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
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        project != null ? project.city : '',
                        style: TextStyle(color: textGray, fontSize: 13),
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

        Row(
          children: [
            Expanded(
              child: _costCard(
                'TOTAL COST',
                // ✅ show only actually paid amounts from entries
                project != null
                    ? formatCurrency(
                        context.read<ProjectProvider>().totalSpentForProject(
                          project.id,
                        ),
                      )
                    : '₹—',
                project != null
                    ? () {
                        final paid = context
                            .read<ProjectProvider>()
                            .totalSpentForProject(project.id);
                        final budget = project.totalBudget;
                        final pct = budget > 0
                            ? (paid / budget * 100).toStringAsFixed(0)
                            : '0';
                        return '$pct% Used';
                      }()
                    : '—',
                project != null &&
                    context.read<ProjectProvider>().totalSpentForProject(
                          project.id,
                        ) >
                        project.totalBudget * 0.9,
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
        _buildSpeakUpdate(context),
        const SizedBox(height: 14),
        _buildRecentActivity(context),
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
                    style: TextStyle(
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
              Text(
                'Select Project',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: projects.map((p) {
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
                              color: selected
                                  ? primaryBlue
                                  : Colors.transparent,
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
                    }).toList(),
                  ),
                ),
              ),
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
            style: TextStyle(
              fontSize: 12,
              color: textGray,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
              maxLines: 1,
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

  Widget _buildSpeakUpdate(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/review-material'),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 24),
                    SizedBox(width: 8),
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
    final provider = context.watch<ProjectProvider>();
    final allEntries = provider.entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = allEntries.take(5).toList();

    return Column(
      children: [
        AppSectionHeader(
          title: 'Recent Activity',
          actionLabel: 'View All',
          onAction: () => Navigator.pushNamed(
            context,
            '/logs',
            arguments: {'projectId': null},
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 36, color: textGray),
                const SizedBox(height: 8),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((entry) => _activityTile(context, entry)),
      ],
    );
  }

  Widget _activityTile(BuildContext context, EntryModel entry) {
    // Icon & colors by type
    final IconData icon;
    final Color badgeBg;
    final Color badgeColor;
    final String badgeLabel;

    switch (entry.type) {
      case EntryType.labour:
        icon = Icons.people_outlined;
        badgeBg = const Color(0xFFE8F5E9);
        badgeColor = const Color(0xFF2E7D32);
        badgeLabel = 'Labour';
        break;
      case EntryType.equipment:
        icon = Icons.precision_manufacturing_outlined;
        badgeBg = const Color(0xFFFFF3E0);
        badgeColor = Colors.orange;
        badgeLabel = 'Equipment';
        break;
      case EntryType.material:
        icon = Icons.category_outlined;
        badgeBg = const Color(0xFFEEF0FF);
        badgeColor = primaryBlue;
        badgeLabel = 'Material';
        break;
    }

    // Format date/time
    final now = DateTime.now();
    final diff = now.difference(entry.date);
    final String timeLabel;
    if (diff.inMinutes < 60) {
      timeLabel = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeLabel = '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      timeLabel = 'Yesterday';
    } else {
      timeLabel = '${diff.inDays}d ago';
    }

    final title = entry.description.isNotEmpty ? entry.description : badgeLabel;
    final subtitle = '₹${entry.amount.toStringAsFixed(0)} • $timeLabel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/logs'),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12.5, color: textGray),
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
                    badgeLabel,
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
  List<dynamic> _pendingTransactions = [];
  List<dynamic> _pendingUpdates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await ApiService.fetchPendingApprovals();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _pendingTransactions =
            (data['transactions'] as List?) ?? [];
        _pendingUpdates =
            (data['projectUpdates'] as List?) ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load approvals';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(String id) async {
    final ok = await ApiService.approveTransaction(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction approved'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadApprovals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject(String id) async {
    final ok =
        await ApiService.rejectTransaction(id, 'Rejected by supervisor');
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction rejected'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadApprovals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingTransactions.length + _pendingUpdates.length;

    return RefreshIndicator(
      onRefresh: _loadApprovals,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary chips ──────────────────────────────────────────
            Row(
              children: [
                _summaryChip(
                  '$pendingCount',
                  'Pending',
                  AppTheme.warning,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  '${_pendingTransactions.where((t) => t['approvalStatus'] == 'Approved').length}',
                  'Approved',
                  AppTheme.success,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  '${_pendingTransactions.where((t) => t['approvalStatus'] == 'Rejected').length}',
                  'Rejected',
                  AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Content ────────────────────────────────────────────────
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.textLight)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadApprovals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (pendingCount == 0)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.textLight
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No pending approvals',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              )
            else ...[
              const AppSectionHeader(title: 'Pending Approvals'),
              const SizedBox(height: 8),
              ..._pendingTransactions.map(
                (tx) => _PendingTxCard(
                  tx: tx as Map<String, dynamic>,
                  onApprove: () =>
                      _handleApprove(tx['_id']?.toString() ?? ''),
                  onReject: () =>
                      _handleReject(tx['_id']?.toString() ?? ''),
                ),
              ),
            ],
          ],
        ),
      ),
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
}

// ── Pending transaction card ───────────────────────────────────────────────────

class _PendingTxCard extends StatelessWidget {
  const _PendingTxCard({
    required this.tx,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> tx;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final title = tx['title']?.toString() ?? 'Entry';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final type = tx['type']?.toString() ?? '';
    final createdByName =
        (tx['createdBy'] is Map ? tx['createdBy']['name'] : null)
                ?.toString() ??
            'Unknown';
    final createdByRole =
        (tx['createdBy'] is Map ? tx['createdBy']['role'] : null)
                ?.toString() ??
            '';
    final projectName =
        (tx['project'] is Map ? tx['project']['projectName'] : null)
                ?.toString() ??
            'Unknown Project';

    String dateStr = '';
    final rawDate = tx['date'] ?? tx['createdAt'];
    if (rawDate != null) {
      try {
        final d = DateTime.parse(rawDate.toString());
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
      } catch (_) {}
    }

    IconData typeIcon;
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'wages':
        typeIcon = Icons.people_outlined;
        typeColor = const Color(0xFF2E7D32);
        break;
      case 'expense':
        typeIcon = Icons.precision_manufacturing_outlined;
        typeColor = const Color(0xFFE65100);
        break;
      default:
        typeIcon = Icons.category_outlined;
        typeColor = AppColors.primary;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$createdByName${createdByRole.isNotEmpty ? ' · $createdByRole' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Meta ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.folder_outlined,
                  size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  projectName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dateStr.isNotEmpty) ...[
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Actions ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  icon: Icons.check_circle_outline,
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// MASON DASHBOARD (TASK 3 UPDATED)
class _MasonDashboard extends StatefulWidget {
  const _MasonDashboard({required this.onEntryTap});
  final void Function(BuildContext, String) onEntryTap;

  @override
  State<_MasonDashboard> createState() => _MasonDashboardState();
}

class _MasonDashboardState extends State<_MasonDashboard> {
  // --- TASK 3: REPLACED HARDCODED LIST WITH FUTURE ---
  late Future<List<dynamic>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = ApiService.fetchDailyTasks();
  }

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
                  Text('Ready for today\'s tasks', style: AppTheme.caption),
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
          onPressed: () => widget.onEntryTap(context, 'material'),
        ),
        const SizedBox(height: 16),

        // Today's tasks with FutureBuilder
        const AppSectionHeader(title: "Today's Tasks"),
        FutureBuilder<List<dynamic>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load tasks from server.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final liveTasks = snapshot.data ?? [];
            if (liveTasks.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tasks assigned for today.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: liveTasks
                  .map((t) => _taskCard(t as Map<String, dynamic>))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final statusMap = {
      'Completed': AppStatus.completed,
      'In Progress': AppStatus.inProgress,
      'Not Started': AppStatus.notStarted,
    };

    // Smart parsing for dynamic backend data
    final taskName = task['task'] ?? task['title'] ?? 'Task';
    final phaseStr = task['phase'] ?? task['category'] ?? 'General';
    final statusStr = task['status'] ?? 'Not Started';

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(phaseStr, style: AppTheme.caption),
              ],
            ),
          ),
          AppStatusBadge(status: statusMap[statusStr] ?? AppStatus.notStarted),
        ],
      ),
    );
  }
}

class ApprovalsAlertWidget extends StatefulWidget {
  const ApprovalsAlertWidget({super.key});

  @override
  State<ApprovalsAlertWidget> createState() => _ApprovalsAlertWidgetState();
}

class _ApprovalsAlertWidgetState extends State<ApprovalsAlertWidget> {
  int _pendingCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final data = await ApiService.fetchPendingApprovals();
    if (mounted) {
      setState(() {
        final txs = (data?['transactions'] as List?)?.length ?? 0;
        final updates = (data?['projectUpdates'] as List?)?.length ?? 0;
        _pendingCount = txs + updates;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide widget entirely if loaded and nothing pending
    if (_loaded && _pendingCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/approvals'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8E5FF), Color(0xFFF0EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loaded
                        ? '$_pendingCount Approval${_pendingCount == 1 ? "" : "s"} Pending'
                        : 'Checking Approvals…',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review pending project updates and expenses.',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
