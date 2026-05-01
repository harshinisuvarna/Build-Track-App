// lib/screen/report.dart
// Production-quality ReportsScreen.
// Uses Provider (ReportProvider) for all state. No hardcoded values.

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
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
      // Scoped to this screen — no global pollution.
      create: (_) => ReportProvider()..refresh(),
      child: const _ReportsView(),
    );
  }
}

// ── Internal view ─────────────────────────────────────────────────────────────

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    // Link to the global ProjectProvider so reports use real data
    final projectProvider = context.watch<ProjectProvider>();
    provider.linkProjectProvider(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            AppTopBar(
              title: 'Dashboard',
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),

            // ── Period tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PeriodTabs(
                tabIndex: provider.tabIndex,
                onTabChanged: (i) {
                  provider.selectTab(i);
                  // Guard against same-tab tap causing redundant animation.
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

            // ── Body (PageView) ───────────────────────────────────────────
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
    // ── Loading state ─────────────────────────────────────────────────────
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // ── Error state ───────────────────────────────────────────────────────
    if (provider.error != null) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: 'Failed to load report.\nPull down to retry.',
        actionLabel: 'Retry',
        onAction: provider.refresh,
      );
    }

    // ── Empty state ───────────────────────────────────────────────────────
    if (!provider.hasData) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'No report data available.',
      );
    }

    final report = provider.report!;

    // ── Main content ──────────────────────────────────────────────────────
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Project filter
          ProjectSelector(provider: provider),
          const SizedBox(height: 14),

          // 2. Cost summary metric cards
          const AppSectionHeader(title: 'Cost Summary'),
          MetricGrid(report: report, period: provider.currentPeriod),
          const SizedBox(height: 14),

          // 3. Cost-per-unit chart
          const AppSectionHeader(title: 'Cost per Unit'),
          ChartSection(provider: provider),
          const SizedBox(height: 14),

          // 4. Category budget progress
          const AppSectionHeader(title: 'Category Budget'),
          CategoryBudgetSection(categoryBudget: report.categoryBudget),
          const SizedBox(height: 14),

          // 5. Efficiency banner
          EfficiencyBanner(
            note: report.efficiencyNote,
            selectedProjectName: provider.selectedProject,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period tabs (Monthly / Quarterly / Yearly)
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.tabIndex, required this.onTabChanged});

  final int                   tabIndex;
  final ValueChanged<int>     onTabChanged;

  static const _tabs = ['Monthly', 'Quarterly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == tabIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(i),
              borderRadius: BorderRadius.circular(26),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
