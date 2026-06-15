// lib/screen/reports/ai_chat_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/themes/app_colors.dart';
import '../../common/themes/app_theme.dart';
import '../../common/widgets/common_widgets.dart';
import '../../controller/ai_chat_report_provider.dart';
import '../../controller/project_provider.dart';
import '../../services/auth_service.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AiChatReportScreen extends StatefulWidget {
  const AiChatReportScreen({super.key});

  @override
  State<AiChatReportScreen> createState() => _AiChatReportScreenState();
}

class _AiChatReportScreenState extends State<AiChatReportScreen> {
  String? token;
  bool loading = true;

  static String get baseUrl {
    //return 'https://build-track.onrender.com';
    /*if (kReleaseMode) {
      return 'https://build-track.onrender.com';
    }*/
    return 'http://localhost:5001';
  }

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
              const Icon(Icons.lock_outline,
                  color: AppColors.textLight, size: 48),
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
      child: const _AiChatView(),
    );
  }
}

// ─── Chat view ────────────────────────────────────────────────────────────────

class _AiChatView extends StatefulWidget {
  const _AiChatView();
  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void send(String text) {
    if (text.trim().isEmpty) return;
    controller.clear();
    context.read<AiChatReportProvider>().send(text);
    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatReportProvider>();
    final projectProvider = context.watch<ProjectProvider>();
    final selectedName =
        projectProvider.selectedProject?.name ?? 'All Projects';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && provider.messages.isNotEmpty) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──
            AppTopBar(
              title: 'Ask AI',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
              rightWidget: provider.messages.isNotEmpty
                  ? GestureDetector(
                      onTap: () => showClearDialog(context, provider),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.textLight, size: 18),
                      ),
                    )
                  : null,
            ),

            // ── Project selector ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _ProjectSelectorPill(
                projects: projectProvider.projects,
                selectedId: projectProvider.selectedProject?.id,
                onChanged: (projectId) {
                  if (projectId == null) {
                    // All Projects — no selectProject call needed,
                    // AiChatReportProvider already sends 'all' when
                    // selectedProject is null on the ProjectProvider
                    provider.clearHistory();
                  } else {
                    final picked = projectProvider.projects
                        .firstWhere((p) => p.id == projectId);
                    projectProvider.selectProject(picked);
                    provider.clearHistory();
                  }
                },
              ),
            ),

            // ── Message list ──
            Expanded(
              child: provider.isEmpty
                  ? _EmptyState(
                      onChipTap: send,
                      projectName: selectedName,
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      itemCount:
                          provider.messages.length + (provider.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.messages.length) {
                          return const _TypingBubble();
                        }
                        final msg = provider.messages[index];
                        if (msg.role == MessageRole.user) {
                          return _UserBubble(message: msg);
                        }
                        return _AssistantBubble(message: msg);
                      },
                    ),
            ),

            // ── Suggested chips ──
            if (!provider.isEmpty && !provider.isTyping)
              _SuggestedChips(onChipTap: send),

            // ── Input bar ──
            _InputBar(
              controller: controller,
              isTyping: provider.isTyping,
              onSend: send,
            ),
          ],
        ),
      ),
    );
  }

  void showClearDialog(BuildContext context, AiChatReportProvider provider) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('All messages will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Project selector pill ────────────────────────────────────────────────────

class _ProjectSelectorPill extends StatelessWidget {
  const _ProjectSelectorPill({
    required this.projects,
    required this.selectedId,
    required this.onChanged,
  });

  final List projects;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE0F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textLight),
          style: AppTheme.body.copyWith(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          items: [
            // All Projects option
            const DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.layers_outlined,
                      size: 15, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('All Projects'),
                ],
              ),
            ),
            // One entry per project
            ...projects.map((p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined,
                          size: 15, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name ?? 'Unnamed',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onChipTap, required this.projectName});
  final ValueChanged<String> onChipTap;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Ask about your project',
              style: AppTheme.heading3.copyWith(color: AppColors.textDark)),
          const SizedBox(height: 6),
          // Shows which project is currently scoped
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              projectName,
              style: AppTheme.caption.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ask anything about costs, entries,\nor inventory across your projects.',
            textAlign: TextAlign.center,
            style: AppTheme.caption
                .copyWith(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: kSuggestedQuestions
                .map((q) => _Chip(label: q, onTap: () => onChipTap(q)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          Text(message.timeString,
              style: AppTheme.caption
                  .copyWith(color: AppColors.textLight, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8)
              ],
            ),
            child: _HighlightedText(text: message.text),
          ),
          if (message.tableType == TableType.entries &&
              message.entryRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _EntryTable(
                title: message.tableTitle ?? 'Entries',
                rows: message.entryRows,
                totalAmount: message.totalAmount,
              ),
            ),
          if (message.tableType == TableType.inventory &&
              message.inventoryRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InventoryTable(rows: message.inventoryRows),
            ),
          const SizedBox(height: 4),
          Text(message.timeString,
              style: AppTheme.caption
                  .copyWith(color: AppColors.textLight, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Highlighted text ─────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'₹[\d,]+');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: const TextStyle(
              color: Color(0xFF2D3142), fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: const TextStyle(
            color: Color(0xFF2D3142), fontSize: 14, height: 1.5),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ─── Entry table ──────────────────────────────────────────────────────────────

class _EntryTable extends StatelessWidget {
  const _EntryTable({
    required this.title,
    required this.rows,
    this.totalAmount,
  });
  final String title;
  final List<ChatTableRow> rows;
  final double? totalAmount;

  String fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasQty =
        rows.any((r) => r.quantity != null && r.quantity!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(title,
                style: AppTheme.label.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                hCell('Date', flex: 2),
                hCell('Item', flex: 3),
                if (hasQty) hCell('Qty', flex: 2),
                hCell('Amount', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          const Divider(height: 10, thickness: 1, color: Color(0xFFF0F1F5)),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                child: Row(
                  children: [
                    dCell(row.date, flex: 2),
                    dCell(row.item, flex: 3),
                    if (hasQty)
                      dCell(
                        row.quantity != null && row.unit != null
                            ? '${row.quantity} ${row.unit}'
                            : row.quantity ?? '-',
                        flex: 2,
                      ),
                    dCell(fmt(row.amount),
                        flex: 2,
                        align: TextAlign.right,
                        bold: true,
                        color: AppColors.primary),
                  ],
                ),
              )),
          if (totalAmount != null) ...[
            const Divider(height: 10, thickness: 1, color: Color(0xFFF0F1F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total',
                        style: AppTheme.label.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(fmt(totalAmount!),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget hCell(String text,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          textAlign: align,
          style: AppTheme.caption.copyWith(
              color: AppColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget dCell(String text,
      {int flex = 1,
      TextAlign align = TextAlign.left,
      bool bold = false,
      Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          textAlign: align,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? const Color(0xFF2D3142),
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          )),
    );
  }
}

// ─── Inventory table ──────────────────────────────────────────────────────────

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.rows});
  final List<InventoryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text('Low stock alerts',
                style: AppTheme.label.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          ...rows.map((row) {
            final Color dotColor;
            final Color badgeColor;
            final Color badgeBg;
            final String label;
            switch (row.severity) {
              case 'critical':
                dotColor = Colors.redAccent;
                badgeColor = Colors.redAccent;
                badgeBg = const Color(0xFFFFEEEE);
                label = 'Critical';
                break;
              case 'low':
                dotColor = Colors.orange;
                badgeColor = Colors.orange;
                badgeBg = const Color(0xFFFFF3E0);
                label = 'Low';
                break;
              default:
                dotColor = AppColors.success;
                badgeColor = AppColors.success;
                badgeBg = const Color(0xFFE8F5E9);
                label = 'OK';
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(row.name,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                            fontWeight: FontWeight.w500)),
                  ),
                  Text('${row.quantity.toStringAsFixed(0)} ${row.unit}',
                      style: AppTheme.caption
                          .copyWith(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  late Animation<double> anim;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    anim = Tween(begin: 0.3, end: 1.0).animate(ctrl);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8)
              ],
            ),
            child: FadeTransition(
              opacity: anim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggested chips ──────────────────────────────────────────────────────────

class _SuggestedChips extends StatelessWidget {
  const _SuggestedChips({required this.onChipTap});
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kSuggestedQuestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _Chip(
          label: kSuggestedQuestions[i],
          onTap: () => onChipTap(kSuggestedQuestions[i]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE0F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(label,
                style: AppTheme.caption.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isTyping,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool isTyping;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gradientStart,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDDE0F0)),
              ),
              child: TextField(
                controller: controller,
                enabled: !isTyping,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                style: AppTheme.body
                    .copyWith(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask about material, inventory…',
                  hintStyle: AppTheme.caption
                      .copyWith(color: AppColors.textLight, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isTyping ? null : () => onSend(controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isTyping
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}