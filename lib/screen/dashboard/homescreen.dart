import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/voice_confirmation_sheet.dart';
import 'package:buildtrack_mobile/common/widgets/nurofin_scaffold.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 13.5, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
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
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BuildTrack Menu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Role: ${UserSession.roleLabel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.textDark),
            title: const Text('Profile',
                style: TextStyle(color: AppColors.textDark)),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          if (RoleManager.canViewReports)
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined,
                  color: AppColors.textDark),
              title: const Text('Reports',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pushNamed(context, '/reports'),
            ),
          if (UserSession.isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
              child: Text('Admin Controls',
                  style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.workspaces_outline,
                  color: AppColors.textDark),
              title: const Text('Create Workspace',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () =>
                  Navigator.pushNamed(context, '/create-workspace'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined,
                  color: AppColors.textDark),
              title: const Text('Assign Roles',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pushNamed(context, '/assign-role'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.textDark),
              title: const Text('Transaction Logs',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pushNamed(context, '/logs'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── KEY FIX ────────────────────────────────────────────────────────────
    // Watch the UserSession ChangeNotifier so this widget rebuilds the moment
    // loadFromPrefs() or fromLoginResponse() calls notifyListeners().
    // Without this, Flutter renders HomeScreen once (session not yet loaded →
    // all RoleManager checks return false → "Limited access"), then never
    // rebuilds because it has no way to know the session changed.
    context.watch<UserSession>();

    // Show a loading screen until the session is fully hydrated.
    if (!UserSession.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile'),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.grey.shade800,
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 17),
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
                        _SupervisorDashboard(
                            onEntryTap: _showEntryOptions),
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

// ════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ════════════════════════════════════════════════════════
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
              Text('OVERALL PROGRESS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textGray,
                      letterSpacing: 0.8)),
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
                        color: textDark),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(project?.name ?? 'No project',
                          style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Text(project != null ? project.city : '',
                          style: TextStyle(color: textGray, fontSize: 13)),
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
                project != null
                    ? formatCurrency(context
                        .read<ProjectProvider>()
                        .totalSpentForProject(project.id))
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
                    context
                            .read<ProjectProvider>()
                            .totalSpentForProject(project.id) >
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

  Widget _buildProjectSelector(
      BuildContext context, ProjectProvider provider) {
    final selectedName =
        provider.selectedProject?.name ?? 'Select Project';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showProjectPicker(context, provider),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.architecture,
                    color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(selectedName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textDark)),
              ]),
              const Icon(Icons.keyboard_arrow_down, color: textGray),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectPicker(
      BuildContext context, ProjectProvider provider) {
    final projects = provider.projects;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text('Select Project',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
              const SizedBox(height: 12),
              ...projects.map((p) {
                final selected =
                    p.id == provider.selectedProject?.id;
                return InkWell(
                  onTap: () {
                    provider.selectProject(p);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                          width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected ? primaryBlue : textGray),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(p.name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:
                                    selected ? primaryBlue : textDark)),
                      ),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costCard(String label, String value, String sub, bool isOver,
      {bool isInvoice = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(
                color: isOver ? const Color(0xFFE040FB) : purple,
                width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: textGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(isInvoice ? Icons.receipt_outlined : Icons.trending_up,
                size: 13,
                color: isOver ? Colors.redAccent : purple),
            const SizedBox(width: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 12,
                    color: isOver ? Colors.redAccent : purple,
                    fontWeight: FontWeight.w600)),
          ]),
        ],
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
                  offset: const Offset(0, 6))
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.mic, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text('Speak Update',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ]),
              SizedBox(height: 6),
              Text('AI FOREMAN IS LISTENING',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ]),
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

    return Column(children: [
      AppSectionHeader(
        title: 'Recent Activity',
        actionLabel: 'View All',
        onAction: () => Navigator.pushNamed(context, '/logs',
            arguments: {'projectId': null}),
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
                  blurRadius: 8)
            ],
          ),
          child: Column(children: [
            Icon(Icons.inbox_outlined, size: 36, color: textGray),
            const SizedBox(height: 8),
            Text('No recent activity',
                style: TextStyle(
                    color: textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
        )
      else
        ...recent.map((entry) => _activityTile(context, entry)),
    ]);
  }

  Widget _activityTile(BuildContext context, EntryModel entry) {
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
    final title =
        entry.description.isNotEmpty ? entry.description : badgeLabel;
    final subtitle =
        '₹${entry.amount.toStringAsFixed(0)} • $timeLabel';

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
                    blurRadius: 8)
              ],
            ),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12.5, color: textGray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(badgeLabel,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// SUPERVISOR DASHBOARD
// ════════════════════════════════════════════════════════
class _SupervisorDashboard extends StatelessWidget {
  const _SupervisorDashboard({required this.onEntryTap});
  final void Function(BuildContext, String) onEntryTap;

  @override
  Widget build(BuildContext context) {
    // Watch UserSession so permission chips update reactively
    context.watch<UserSession>();

    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBanner(),
        const SizedBox(height: 14),

        if (project == null)
          _emptyState('No project assigned',
              'Your admin has not assigned a project yet.')
        else ...[

          if (RoleManager.canViewProjects) ...[
            _projectCard(context, project, provider),
            const SizedBox(height: 12),
          ],

          if (RoleManager.canViewReports) ...[
            _budgetRow(context, project, provider),
            const SizedBox(height: 14),
          ],

          if (RoleManager.canAddEntries) ...[
            _sectionLabel('Add Entry'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _actionButton(
                  context,
                  icon: Icons.category_outlined,
                  label: 'Material',
                  onTap: () => onEntryTap(context, 'material'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  context,
                  icon: Icons.people_outlined,
                  label: 'Labour',
                  onTap: () => onEntryTap(context, 'labour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  context,
                  icon: Icons.precision_manufacturing_outlined,
                  label: 'Equipment',
                  onTap: () => onEntryTap(context, 'equipment'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
          ],

          if (RoleManager.canApprovePayments) ...[
            _sectionLabel('Pending Approvals'),
            const SizedBox(height: 8),
            _pendingApprovalsList(context, provider, project),
            const SizedBox(height: 14),
          ],

          if (RoleManager.canViewProjects)
            _recentActivitySection(context, provider, project),

          if (!RoleManager.canViewProjects &&
              !RoleManager.canAddEntries &&
              !RoleManager.canApprovePayments)
            _emptyState('Limited access',
                'Contact your admin to grant permissions.'),
        ],
      ],
    );
  }

  Widget _roleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_user_outlined,
            color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text('Logged in as Supervisor',
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const Spacer(),
        if (RoleManager.canAddEntries)      _permChip('Add'),
        if (RoleManager.canApprovePayments) _permChip('Approve'),
        if (RoleManager.canViewReports)     _permChip('Reports'),
      ]),
    );
  }

  Widget _permChip(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _projectCard(BuildContext context, ProjectModel project,
      ProjectProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(project.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(project.city,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('OVERALL PROGRESS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(
            '${(project.progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          AppProgressBar(label: '', percent: project.progress),
        ],
      ),
    );
  }

  Widget _budgetRow(BuildContext context, ProjectModel project,
      ProjectProvider provider) {
    final spent = provider.totalSpentForProject(project.id);
    final budget = project.totalBudget;
    final pct =
        budget > 0 ? (spent / budget * 100).toStringAsFixed(0) : '0';

    return Row(children: [
      Expanded(
        child: _miniCard(
            'TOTAL SPENT', formatCurrency(spent), '$pct% of budget',
            isOver: spent > budget * 0.9),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _miniCard('BUDGET', formatCurrency(budget),
            'Remaining: ${formatCurrency((budget - spent).clamp(0, double.infinity))}',
            isOver: false),
      ),
    ]);
  }

  Widget _miniCard(String label, String value, String sub,
      {required bool isOver}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(
                color: isOver
                    ? const Color(0xFFE040FB)
                    : AppColors.primary,
                width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isOver ? Colors.red : AppColors.textDark)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  color:
                      isOver ? Colors.redAccent : AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _pendingApprovalsList(BuildContext context,
      ProjectProvider provider, ProjectModel project) {
    final pending = provider
        .entriesForProject(project.id)
        .where((e) => e.amount == 0)
        .take(5)
        .toList();

    if (pending.isEmpty) {
      return AppCard(
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 20),
          const SizedBox(width: 10),
          const Text('No pending approvals',
              style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Column(
      children: pending.map((e) {
        return AppCard(
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.description.isNotEmpty
                        ? e.description
                        : e.type.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(e.type.name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Pending',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _recentActivitySection(BuildContext context,
      ProjectProvider provider, ProjectModel project) {
    final entries = provider
        .entriesForProject(project.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = entries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent Activity',
          actionLabel: RoleManager.canViewReports ? 'View All' : null,
          onAction: RoleManager.canViewReports
              ? () => Navigator.pushNamed(context, '/logs',
                  arguments: {'projectId': project.id})
              : null,
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No entries yet for this project',
                    style: TextStyle(color: AppColors.textLight)),
              ),
            ),
          )
        else
          ...recent.map((e) => _entryTile(e)),
      ],
    );
  }

  Widget _entryTile(EntryModel entry) {
    final String label;
    final Color color;
    switch (entry.type) {
      case EntryType.labour:
        label = 'Labour';
        color = const Color(0xFF2E7D32);
        break;
      case EntryType.equipment:
        label = 'Equipment';
        color = Colors.orange;
        break;
      case EntryType.material:
        label = 'Material';
        color = AppColors.primary;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    entry.description.isNotEmpty
                        ? entry.description
                        : label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('₹${entry.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark));
  }

  Widget _emptyState(String title, String subtitle) {
    return AppCard(
      child: Column(children: [
        const Icon(Icons.lock_outline,
            size: 40, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textLight, fontSize: 13)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════
// MASON DASHBOARD
// ════════════════════════════════════════════════════════
class _MasonDashboard extends StatelessWidget {
  const _MasonDashboard({required this.onEntryTap});
  final void Function(BuildContext, String) onEntryTap;

  @override
  Widget build(BuildContext context) {
    context.watch<UserSession>();

    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  AppTheme.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.person_outline,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning, Mason', style: AppTheme.heading3),
                Text('Ready for today\'s tasks',
                    style: AppTheme.caption),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),

        if (project == null)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No project assigned by admin.',
                    style:
                        TextStyle(color: AppColors.textLight)),
              ),
            ),
          )
        else ...[
          if (RoleManager.canViewProjects) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  AppProgressBar(
                      label: 'Progress', percent: project.progress),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (RoleManager.canAddEntries) ...[
            AppButton(
              label: 'Add Daily Update',
              icon: Icons.add_circle_outline,
              onPressed: () =>
                  Navigator.pushNamed(context, '/update-progress'),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Add Material Entry',
              icon: Icons.category_outlined,
              variant: AppButtonVariant.outline,
              onPressed: () => onEntryTap(context, 'material'),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Add Labour Entry',
              icon: Icons.people_outlined,
              variant: AppButtonVariant.outline,
              onPressed: () => onEntryTap(context, 'labour'),
            ),
            const SizedBox(height: 16),
          ] else
            AppCard(
              child: Row(children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.textLight, size: 18),
                const SizedBox(width: 10),
                const Text('Adding entries is not permitted',
                    style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13)),
              ]),
            ),
        ],
      ],
    );
  }
}