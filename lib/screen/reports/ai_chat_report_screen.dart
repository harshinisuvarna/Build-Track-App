// lib/screen/reports/ai_chat_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/themes/app_colors.dart';
import '../../common/themes/app_theme.dart';
import '../../common/widgets/common_widgets.dart';
import '../../controller/ai_chat_report_provider.dart';
import '../../controller/project_provider.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AiChatReportScreen extends StatefulWidget {
  const AiChatReportScreen({super.key});

  @override
  State<AiChatReportScreen> createState() => _AiChatReportScreenState();
}

class _AiChatReportScreenState extends State<AiChatReportScreen> {
  String? token;
  bool loading = true;

  static String get baseUrl => ApiConfig.baseUrl.replaceAll('/api', '');

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final t = await AuthService.getToken();
    if (mounted) {
      setState(() {
        token = t;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.gradientStart,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (token == null || token!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.gradientStart,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.textLight,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Session expired. Please log in again.',
                style: AppTheme.body.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => AiChatReportProvider(
        projectProvider: ctx.read<ProjectProvider>(),
        authToken: token!,
        baseUrl: baseUrl,
      ),
      child: const _AiDashboardView(),
    );
  }
}

// ─── Dashboard view ────────────────────────────────────────────────────────────

class _AiDashboardView extends StatefulWidget {
  const _AiDashboardView();

  @override
  State<_AiDashboardView> createState() => _AiDashboardViewState();
}

class _AiDashboardViewState extends State<_AiDashboardView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<AiChatReportProvider>().sendQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatReportProvider>();

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            AppTopBar(
              title: 'Construction Intelligence',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
              rightWidget: provider.state == AiReportState.results
                  ? IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.resetToInitial();
                      },
                    )
                  : null,
            ),

            // Persistent Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) => _submitSearch(context, val),
                  decoration: InputDecoration(
                    hintText: 'Ask about materials, costs, projects...',
                    hintStyle: AppTheme.body.copyWith(
                      color: AppColors.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(
                                () {},
                              ); // Trigger rebuild to hide clear icon
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Main Content Area based on state
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AiChatReportProvider provider) {
    switch (provider.state) {
      case AiReportState.initial:
        return _InitialState(
          onPromptSelected: (prompt) {
            _searchController.text = prompt;
            _submitSearch(context, prompt);
          },
        );
      case AiReportState.loading:
        return const _LoadingState();
      case AiReportState.error:
        return _ErrorState(
          error: provider.errorMessage ?? 'An unknown error occurred.',
          onRetry: () => _submitSearch(context, _searchController.text),
        );
      case AiReportState.results:
        return _ResultsState(
          result: provider.result!,
          onActionTap: (action) {
            _searchController.text = action;
            _submitSearch(context, action);
          },
        );
    }
  }
}

// ─── Initial State ─────────────────────────────────────────────────────────────

class _InitialState extends StatelessWidget {
  const _InitialState({required this.onPromptSelected});
  final ValueChanged<String> onPromptSelected;

  final List<String> quickPrompts = const [
    'Show material usage',
    'Compare project costs',
    'Low stock materials',
    'Labour summary',
    'Equipment usage',
    'Monthly spending',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatReportProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),
        Text(
          'Quick Insights',
          style: AppTheme.heading3.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: quickPrompts
              .map(
                (p) => _PromptCard(prompt: p, onTap: () => onPromptSelected(p)),
              )
              .toList(),
        ),

        if (provider.recentSearches.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'Recent Searches',
            style: AppTheme.heading3.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          ...provider.recentSearches.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppColors.textLight),
              title: Text(
                s,
                style: AppTheme.body.copyWith(color: AppColors.textDark),
              ),
              onTap: () => onPromptSelected(s),
            ),
          ),
        ],
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.onTap});
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) - 24,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insights, color: AppColors.primary, size: 20),
            const SizedBox(height: 12),
            Text(
              prompt,
              style: AppTheme.body.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading State ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(height: 100, width: double.infinity),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(height: 80)),
              const SizedBox(width: 16),
              Expanded(child: _buildSkeletonBox(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSkeletonBox(height: 200, width: double.infinity),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Generating analytics...',
                  style: AppTheme.body.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to generate report',
              style: AppTheme.heading3.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Results State ─────────────────────────────────────────────────────────────

class _ResultsState extends StatelessWidget {
  const _ResultsState({required this.result, required this.onActionTap});
  final AiReportResult result;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatReportProvider>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // Alerts Section
        if (result.alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: result.alerts.map((alert) {
                final isCritical = alert['type'] == 'critical';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCritical
                          ? Colors.red.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCritical ? Icons.warning : Icons.info,
                        color: isCritical ? Colors.red : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alert['message'] ?? '',
                          style: TextStyle(
                            color: isCritical
                                ? Colors.red.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Executive Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Executive Summary',
                      style: AppTheme.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.summary,
                  style: AppTheme.body.copyWith(
                    color: AppColors.textDark,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => provider.shareSummary(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              if (result.tableRows.isNotEmpty)
                TextButton.icon(
                  onPressed: () => provider.exportCsv(),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),

        // Metrics Grid (Collapsible/Dynamic based on what's available)
        if (result.totalAmount != null || result.rowCount != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (result.totalAmount != null)
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Amount',
                      value: _formatCurrency(result.totalAmount!),
                      icon: Icons.currency_rupee,
                    ),
                  ),
                if (result.totalAmount != null && result.rowCount != null)
                  const SizedBox(width: 16),
                if (result.rowCount != null)
                  Expanded(
                    child: _MetricCard(
                      title: result.tableType == 'inventory'
                          ? 'Items Tracked'
                          : 'Total Entries',
                      value: result.rowCount.toString(),
                      icon: Icons.format_list_numbered,
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Project Breakdown
        if (result.projectBreakdown.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By Project', style: AppTheme.heading3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDE0F0)),
                  ),
                  child: Column(
                    children: List.generate(result.projectBreakdown.length, (
                      index,
                    ) {
                      final item = result.projectBreakdown[index];
                      final isTop = index == 0;
                      // Fallback to quantity if amount is 0 (for inventory queries)
                      final val =
                          (item['totalAmount'] as num?)?.toDouble() ?? 0;
                      final valStr = val > 0
                          ? _formatCurrency(val)
                          : '${item['totalQty'] ?? 0} units';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isTop)
                                  const Text(
                                    '🏆 ',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                if (!isTop) const SizedBox(width: 16),
                                Text(
                                  item['projectName']?.toString() ?? 'Unknown',
                                  style: AppTheme.body.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: isTop
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              valStr,
                              style: AppTheme.body.copyWith(
                                fontWeight: isTop
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

        // Data Table
        if (result.tableRows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE0F0)),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  result.tableType == 'inventory'
                      ? 'Inventory Details'
                      : 'Transaction Details',
                  style: AppTheme.heading3.copyWith(fontSize: 16),
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: result.tableType == 'inventory'
                        ? _buildInventoryTable()
                        : _buildTransactionTable(),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Suggested Actions
        if (result.actions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested Explorations',
              style: AppTheme.label.copyWith(color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: result.actions.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                return ActionChip(
                  label: Text(result.actions[i]),
                  onPressed: () => onActionTap(result.actions[i]),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Widget _buildTransactionTable() {
    return DataTable(
      headingTextStyle: AppTheme.label.copyWith(
        color: AppColors.textLight,
        fontWeight: FontWeight.bold,
      ),
      dataTextStyle: AppTheme.body.copyWith(
        color: AppColors.textDark,
        fontSize: 13,
      ),
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Project')),
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Amount'), numeric: true),
      ],
      rows: result.tableRows.map((r) {
        final qty = r['quantity'] != null && r['quantity'].toString().isNotEmpty
            ? '${r['quantity']} ${r['unit'] ?? ''}'
            : '-';
        return DataRow(
          cells: [
            DataCell(Text(r['date']?.toString() ?? '-')),
            DataCell(Text(r['projectName']?.toString() ?? '-')),
            DataCell(Text(r['item']?.toString() ?? '-')),
            DataCell(Text(qty)),
            DataCell(
              Text(_formatCurrency((r['amount'] as num?)?.toDouble() ?? 0)),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInventoryTable() {
    return DataTable(
      headingTextStyle: AppTheme.label.copyWith(
        color: AppColors.textLight,
        fontWeight: FontWeight.bold,
      ),
      dataTextStyle: AppTheme.body.copyWith(
        color: AppColors.textDark,
        fontSize: 13,
      ),
      columns: const [
        DataColumn(label: Text('Material')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Status')),
      ],
      rows: result.tableRows.map((r) {
        final severity = r['severity']?.toString() ?? 'ok';
        Color statusColor = AppColors.success;
        if (severity == 'critical') statusColor = AppColors.error;
        if (severity == 'low') statusColor = Colors.orange;

        return DataRow(
          cells: [
            DataCell(Text(r['name']?.toString() ?? '-')),
            DataCell(Text(r['category']?.toString().toUpperCase() ?? '-')),
            DataCell(Text('${r['quantity'] ?? 0} ${r['unit'] ?? ''}')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.heading2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
