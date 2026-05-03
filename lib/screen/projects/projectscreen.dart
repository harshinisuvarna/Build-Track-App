import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/screen/projects/add_project.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});
  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;
  static const _stageMeta = <ProjectStage, _StageStyle>{
    ProjectStage.preConstruction: _StageStyle(Color(0xFFE8EAF6), Color(0xFF3949AB)),
    ProjectStage.sitePreparation: _StageStyle(Color(0xFFFCE4EC), Color(0xFFC62828)),
    ProjectStage.foundation:      _StageStyle(Color(0xFFEEEFFF), Color(0xFF4455CC)),
    ProjectStage.plinth:          _StageStyle(Color(0xFFE3F2FD), Color(0xFF1565C0)),
    ProjectStage.superstructure:  _StageStyle(Color(0xFFF3E8FF), Color(0xFF9B59B6)),
    ProjectStage.masonry:         _StageStyle(Color(0xFFFFF3E0), Color(0xFFE65100)),
    ProjectStage.mep:             _StageStyle(Color(0xFFE0F7FA), Color(0xFF00838F)),
    ProjectStage.plastering:      _StageStyle(Color(0xFFF9FBE7), Color(0xFF827717)),
    ProjectStage.finishing:       _StageStyle(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    ProjectStage.fixtures:        _StageStyle(Color(0xFFFFF8E1), Color(0xFFF9A825)),
    ProjectStage.handover:        _StageStyle(Color(0xFFFFF8E1), Color(0xFFF57F17)),
  };
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProjectScreen()),
        ),
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
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(context, provider),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
  Widget _buildBody(BuildContext context, ProjectProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error.isNotEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: provider.error,
        actionLabel: 'Retry',
        onAction: provider.load,
      );
    }
    if (!provider.hasProjects) {
      return const AppEmptyState(
        icon: Icons.folder_open_outlined,
        message: 'No projects yet.\nTap + to create your first project.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE PIPELINE',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Active Builds',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.projects.length} Sites',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...provider.projects.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _projectCard(context, p, provider),
                )),
          ],
        ),
      ),
    );
  }
  Widget _projectCard(
      BuildContext context, ProjectModel p, ProjectProvider provider) {
    final style = _stageMeta[p.stage] ??
        const _StageStyle(Color(0xFFEEEFFF), Color(0xFF4455CC));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          provider.selectProject(p);
          Navigator.pushNamed(context, '/project-detail');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
              // Name + stage badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.stage.label,
                      style: TextStyle(
                        color: style.fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Location
              Text(
                p.location,
                style: TextStyle(
                  color: textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Budget summary
              Text(
                '${p.formattedSpent} of ${p.formattedBudget}',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall Progress',
                      style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  Text('${(p.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value: p.progress,
                  backgroundColor: const Color(0xFFE8ECF8),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryBlue),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFEEF0F5), height: 1),
              const SizedBox(height: 12),

              // View Details link
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    provider.selectProject(p);
                    Navigator.pushNamed(context, '/project-detail');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward,
                            color: primaryBlue, size: 16),
                      ],
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
}
class _StageStyle {
  const _StageStyle(this.bg, this.fg);
  final Color bg;
  final Color fg;
}
