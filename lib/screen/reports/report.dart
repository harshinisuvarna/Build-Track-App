// lib/screen/reports/report.dart
// CHANGES FROM ORIGINAL:
//   1. Added "Ask AI" banner button at the bottom of _buildPageContent
//   2. No other changes — all existing logic preserved

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/report_provider.dart';
import 'package:buildtrack_mobile/screen/reports/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportProvider()..refresh(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  final _pageController = PageController();
  bool _linked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_linked) {
      _linked = true;
      final projectProvider = context.read<ProjectProvider>();
      context.read<ReportProvider>().linkProjectProvider(projectProvider);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    context.watch<ProjectProvider>();

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Reports',
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: const ProfileAvatar(radius: 18),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PeriodTabs(
                tabIndex: provider.tabIndex,
                onTabChanged: (i) {
                  provider.selectTab(i);
                  if (_pageController.page?.round() != i) {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: provider.selectTab,
                itemBuilder: (context, index) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.refresh,
                  child: _buildPageContent(context, provider),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildPageContent(BuildContext context, ReportProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.error != null && provider.error!.trim().isNotEmpty) {
      debugPrint("REPORT CRASH EXCEPTION: ${provider.error}");
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: 'Failed to load report.\nPull down to retry.',
        actionLabel: 'Retry',
        onAction: provider.refresh,
      );
    }

    if (!provider.hasData) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'No report data available.',
      );
    }

    final report = provider.report;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AskAiBanner(projectName: provider.selectedProjectName),
          const SizedBox(height: 14),

          ProjectSelector(provider: provider),
          const SizedBox(height: 14),

          const AppSectionHeader(title: 'Cost Summary'),
          MetricGrid(report: report, period: provider.currentPeriod),

          const SizedBox(height: 14),

          const AppSectionHeader(title: 'Cost per Unit'),
          ChartSection(report: report),

          const SizedBox(height: 14),

          const AppSectionHeader(title: 'Category Budget'),
          const CategoryBudgetSection(),

          const SizedBox(height: 14),

          EfficiencyBanner(
            note: report.efficiencyNote,
            isExceeded: report.isBudgetExceeded,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Ask AI banner button ─────────────────────────────────────────────────────

class _AskAiBanner extends StatelessWidget {
  const _AskAiBanner({required this.projectName});
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/ai-chat',
          arguments: {'projectName': projectName},
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5B5FCF),
                AppColors.primary.withValues(alpha: 0.80),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ask about costs, entries & inventory',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Period tabs (unchanged) ──────────────────────────────────────────────────

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.tabIndex, required this.onTabChanged});

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  static const _tabs = ['Daily', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
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
        children: List.generate(_tabs.length, (i) {
          final active = i == tabIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.primaryButton : null,
                  color: active ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}