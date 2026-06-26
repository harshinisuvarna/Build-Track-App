// lib/screen/reports/report.dart

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/report_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/screen/reports/report_export_helper.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
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
  bool _linked = false;

  // Filter State
  String _selectedProjectId = 'all';
  String? _selectedFloor;
  String? _selectedPhaseId;
  String? _selectedActivityName;

  // Category specific search & filter state
  String _searchQuery = '';
  String? _selectedItemName;
  bool _reportGenerated = false;
  bool _showSuggestions = false;
  final TextEditingController _searchController = TextEditingController();

  final Set<EntryType> _selectedTypes = {
    EntryType.material,
    EntryType.labour,
    EntryType.equipment,
  };
  final String _selectedStatus = 'All'; // All, Approved, Pending, Rejected
  DateTime? _startDate;
  DateTime? _endDate;
  String _datePreset = 'All Time'; // All Time, Today, This Week, This Month, Last 30 Days, This Year, Custom

  // Sorting & Pagination State
  String _sortColumn = 'date'; // date, amount, project
  bool _sortAscending = false;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Columns customization lists for each tab
  List<String> _activeColumnsAll = ['Purchased Date', 'Project', 'Type', 'Description', 'Brand', 'Floor', 'Phase', 'Activity', 'Unit', 'Status', 'Amount', 'Payment Date'];
  List<String> _activeColumnsMaterials = ['Purchased Date', 'Project', 'Material', 'Brand', 'Rate', 'Qty', 'Unit', 'Status', 'Amount', 'Payment Date'];
  List<String> _activeColumnsLabour = ['Purchased Date', 'Project', 'Worker Type', 'Rate/Day', 'Days', 'Status', 'Amount', 'Payment Date'];
  List<String> _activeColumnsEquipment = ['Purchased Date', 'Project', 'Equipment', 'Rent Rate', 'Duration', 'Status', 'Amount', 'Payment Date'];

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
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAllColumnsForTab(String tabName) {
    if (tabName == 'Materials') {
      return ['Purchased Date', 'Project', 'Material', 'Brand', 'Rate', 'Qty', 'Unit', 'Floor', 'Phase', 'Activity', 'Status', 'Amount', 'Payment Date'];
    } else if (tabName == 'Labour') {
      return ['Purchased Date', 'Project', 'Worker Type', 'Rate/Day', 'Days', 'Unit', 'Floor', 'Phase', 'Activity', 'Status', 'Amount', 'Payment Date'];
    } else if (tabName == 'Equipment') {
      return ['Purchased Date', 'Project', 'Equipment', 'Rent Rate', 'Duration', 'Unit', 'Floor', 'Phase', 'Activity', 'Status', 'Amount', 'Payment Date'];
    } else {
      return ['Purchased Date', 'Project', 'Type', 'Description', 'Brand', 'Floor', 'Phase', 'Activity', 'Unit', 'Status', 'Amount', 'Payment Date'];
    }
  }

  List<String> _getActiveColumnsForTab(String tabName) {
    if (tabName == 'Materials') {
      return _activeColumnsMaterials;
    } else if (tabName == 'Labour') {
      return _activeColumnsLabour;
    } else if (tabName == 'Equipment') {
      return _activeColumnsEquipment;
    } else {
      return _activeColumnsAll;
    }
  }

  void _setActiveColumnsForTab(String tabName, List<String> cols) {
    setState(() {
      if (tabName == 'Materials') {
        _activeColumnsMaterials = cols;
      } else if (tabName == 'Labour') {
        _activeColumnsLabour = cols;
      } else if (tabName == 'Equipment') {
        _activeColumnsEquipment = cols;
      } else {
        _activeColumnsAll = cols;
      }
    });
  }

  void _showCustomizeColumnsDialog(BuildContext context, String tabName) {
    final List<String> allCols = _getAllColumnsForTab(tabName);
    List<String> tempActive = List.from(_getActiveColumnsForTab(tabName));
    final inactive = allCols.where((c) => !tempActive.contains(c)).toList();
    List<String> tempAll = [...tempActive, ...inactive];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customize Columns',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    const Text(
                      'Drag items to reorder. Toggle checkbox to show/hide columns.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: tempAll.length,
                        onReorder: (oldIndex, newIndex) {
                          setDialogState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = tempAll.removeAt(oldIndex);
                            tempAll.insert(newIndex, item);

                            // Re-align tempActive's order with tempAll
                            final newTempActive = <String>[];
                            for (final col in tempAll) {
                              if (tempActive.contains(col)) {
                                newTempActive.add(col);
                              }
                            }
                            tempActive = newTempActive;
                          });
                        },
                        itemBuilder: (context, index) {
                          final col = tempAll[index];
                          final isChecked = tempActive.contains(col);

                          return ListTile(
                            key: ValueKey(col),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              col,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            leading: Checkbox(
                              activeColor: AppColors.primary,
                              value: isChecked,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    tempActive.add(col);
                                    // Keep order of tempActive aligned with tempAll
                                    final newTempActive = <String>[];
                                    for (final c in tempAll) {
                                      if (tempActive.contains(c)) {
                                        newTempActive.add(c);
                                      }
                                    }
                                    tempActive = newTempActive;
                                  } else {
                                    if (tempActive.length > 1) {
                                      tempActive.remove(col);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('At least one column must be visible.'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                            ),
                            trailing: const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempActive = List.from(allCols);
                              tempAll = List.from(allCols);
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            _setActiveColumnsForTab(tabName, tempActive);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Formatting Helpers (avoids package:intl dependency) ---

  String _formatDateShort(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year.toString().substring(dt.year.toString().length - 2);
    return '$day $month $year';
  }

  String _formatDateLong(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour24 = dt.hour;
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute $ampm';
  }

  String _formatIndianCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];

    if (whole.length <= 3) {
      return 'Rs. $whole.$decimal';
    }

    final lastThree = whole.substring(whole.length - 3);
    final remaining = whole.substring(0, whole.length - 3);

    final buffer = StringBuffer();
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      if (count > 0 && count % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
      count++;
    }
    final formattedRemaining = buffer.toString().split('').reversed.join('');
    return 'Rs. $formattedRemaining,$lastThree.$decimal';
  }

  void _setDatePreset(String preset) {
    setState(() {
      _datePreset = preset;
      final now = DateTime.now();
      _currentPage = 1;

      switch (preset) {
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Week':
          final weekday = now.weekday;
          final start = now.subtract(Duration(days: weekday - 1));
          _startDate = DateTime(start.year, start.month, start.day);
          _endDate = null;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = null;
          break;
        case 'Last 30 Days':
          _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
          _endDate = null;
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = null;
          break;
        case 'Custom':
          // User must manually select dates
          break;
      }
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _datePreset = 'Custom';
        _currentPage = 1;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _datePreset = 'Custom';
        _currentPage = 1;
      });
    }
  }

  Future<void> _handleCsvExport(
    List<EntryModel> filtered,
    String Function(String) getProjectName,
    String quickCategoryTab, {
    List<String>? activeColumns,
  }) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report entries to export.')),
      );
      return;
    }
    try {
      await ReportExportHelper.exportToCsv(
        entries: filtered,
        getProjectName: getProjectName,
        quickCategoryTab: quickCategoryTab,
        activeColumns: activeColumns,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV Export failed: $e')),
      );
    }
  }

  // ignore: unused_element
  Future<void> _handlePdfExport(
    List<EntryModel> filtered,
    String Function(String) getProjectName,
    String quickCategoryTab, {
    List<String>? activeColumns,
  }) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report entries to export.')),
      );
      return;
    }
    try {
      final List<String> parts = [];
      if (_selectedProjectId != 'all') {
        parts.add('Project: ${getProjectName(_selectedProjectId)}');
        if (_selectedFloor != null) {
          parts.add('Floor: $_selectedFloor');
        }
        if (_selectedPhaseId != null) {
          final projectProvider = context.read<ProjectProvider>();
          final proj = projectProvider.projects.where((p) => p.id == _selectedProjectId).firstOrNull;
          final phaseName = proj?.selectedPhases?.where((ph) => ph.id == _selectedPhaseId).firstOrNull?.phaseName;
          parts.add('Phase: ${phaseName ?? _selectedPhaseId}');
        }
        if (_selectedActivityName != null) {
          parts.add('Activity: $_selectedActivityName');
        }
      } else {
        parts.add('All Projects');
      }
      parts.add('Types: ${_selectedTypes.map((t) => t.name.toUpperCase()).join(", ")}');
      parts.add('Status: $_selectedStatus');
      parts.add('Date Range: $_datePreset');

      await ReportExportHelper.exportToPdf(
        entries: filtered,
        getProjectName: getProjectName,
        title: _selectedProjectId == 'all'
            ? 'All Active Projects Summary Report'
            : '${getProjectName(_selectedProjectId)} Report',
        filterSummary: parts.join(' | '),
        quickCategoryTab: quickCategoryTab,
        activeColumns: activeColumns,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final projectProvider = context.watch<ProjectProvider>();
    final List<EntryModel> allEntries = projectProvider.entries;

    // Helper to resolve project name
    String getProjectName(String id) {
      return projectProvider.projects
              .where((p) => p.id == id)
              .firstOrNull
              ?.name ??
          'Unknown Project';
    }

    // Determine active quick category tab based on _selectedTypes
    String quickCategoryTab = 'All';
    if (_selectedTypes.length == 1) {
      if (_selectedTypes.contains(EntryType.material)) {
        quickCategoryTab = 'Materials';
      } else if (_selectedTypes.contains(EntryType.labour)) {
        quickCategoryTab = 'Labour';
      } else if (_selectedTypes.contains(EntryType.equipment)) {
        quickCategoryTab = 'Equipment';
      }
    } else if (_selectedTypes.length == 3) {
      quickCategoryTab = 'All';
    } else {
      quickCategoryTab = ''; // custom subset
    }

    // Filter Logic
    final filtered = allEntries.where((entry) {
      if (_selectedProjectId != 'all' && entry.projectId.trim() != _selectedProjectId.trim()) {
        return false;
      }

      if (_selectedProjectId != 'all') {
        if (_selectedFloor != null && _selectedFloor != 'Select Floor') {
          if (entry.floor != _selectedFloor) return false;
        }

        if (_selectedPhaseId != null && _selectedPhaseId != 'Select Phase') {
          final project = projectProvider.projects
              .where((p) => p.id == _selectedProjectId)
              .firstOrNull;
          final phaseName = project?.selectedPhases
              ?.where((ph) => ph.id == _selectedPhaseId)
              .firstOrNull
              ?.phaseName;

          if (entry.phaseId != _selectedPhaseId &&
              (phaseName == null || entry.phase?.name != phaseName)) {
            return false;
          }
        }

        if (_selectedActivityName != null && _selectedActivityName != 'Select Activity') {
          if (entry.activity != _selectedActivityName && entry.description != _selectedActivityName) {
            return false;
          }
        }
      }

      if (!_selectedTypes.contains(entry.type)) {
        return false;
      }

      // Dynamic sub-filters for category report tab
      if (quickCategoryTab != 'All' && _reportGenerated) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final descMatch = entry.description.toLowerCase().contains(query);
          final brandMatch = (entry.brand ?? '').toLowerCase().contains(query);
          if (!descMatch && !brandMatch) return false;
        }

        if (_selectedItemName != null && _selectedItemName != 'All') {
          if (entry.description != _selectedItemName) return false;
        }
      }

      // Search filter for All tab (real-time filtering without requiring report generation)
      if (quickCategoryTab == 'All' && _searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final projectName = getProjectName(entry.projectId).toLowerCase();
        final descMatch = entry.description.toLowerCase().contains(query);
        final brandMatch = (entry.brand ?? '').toLowerCase().contains(query);
        final projectMatch = projectName.contains(query);
        final floorMatch = (entry.floor ?? '').toLowerCase().contains(query);
        final phaseMatch = (entry.phase?.name ?? '').toLowerCase().contains(query);
        final activityMatch = (entry.activity ?? '').toLowerCase().contains(query);
        final amountMatch = entry.amount.toString().contains(query);
        final typeMatch = entry.type.name.toLowerCase().contains(query);
        final statusMatch = _getPaymentStatusLabel(entry.paymentStatus).toLowerCase().contains(query);
        final dateMatch = _formatDateShort(entry.date).toLowerCase().contains(query);
        final payDateMatch = entry.paymentDate != null ? _formatDateShort(entry.paymentDate!).toLowerCase().contains(query) : false;
 
        if (!descMatch &&
            !brandMatch &&
            !projectMatch &&
            !floorMatch &&
            !phaseMatch &&
            !activityMatch &&
            !amountMatch &&
            !typeMatch &&
            !statusMatch &&
            !dateMatch &&
            !payDateMatch) {
          return false;
        }
      }

      if (_selectedStatus != 'All' &&
          entry.approvalStatus.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      if (_startDate != null) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (entryDate.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (entryDate.isAfter(end)) return false;
      }

      return true;
    }).toList();

    // Sorting Logic
    filtered.sort((a, b) {
      int cmp = 0;
      if (_sortColumn == 'date') {
        cmp = a.date.compareTo(b.date);
      } else if (_sortColumn == 'amount') {
        cmp = a.amount.compareTo(b.amount);
      } else if (_sortColumn == 'project') {
        cmp = getProjectName(a.projectId).compareTo(getProjectName(b.projectId));
      }
      return _sortAscending ? cmp : -cmp;
    });

    // Dynamic Calculations based on filtered results
    double materialTotal = 0;
    double labourTotal = 0;
    double equipmentTotal = 0;
    double grandTotal = 0;

    for (final entry in filtered) {
      grandTotal += entry.amount;
      switch (entry.type) {
        case EntryType.material:
          materialTotal += entry.amount;
          break;
        case EntryType.labour:
          labourTotal += entry.amount;
          break;
        case EntryType.equipment:
          equipmentTotal += entry.amount;
          break;
      }
    }

    // Pagination Calculations
    final totalCount = filtered.length;
    final totalPages = (totalCount / _rowsPerPage).ceil() == 0 ? 1 : (totalCount / _rowsPerPage).ceil();
    int safeCurrentPage = _currentPage;
    if (safeCurrentPage > totalPages) safeCurrentPage = totalPages;
    if (safeCurrentPage < 1) safeCurrentPage = 1;

    final startIndex = (safeCurrentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage < totalCount) ? startIndex + _rowsPerPage : totalCount;

    final List<EntryModel> paginatedEntries = (totalCount > 0) ? filtered.sublist(startIndex, endIndex) : [];

    final List<String> activeCols = _getActiveColumnsForTab(quickCategoryTab);
    final List<String> uiActiveCols = [...activeCols, 'Add More', 'Record Payment', 'Edit Entry'];
    final List<DataColumn> columns = uiActiveCols.map((colName) {
      if (colName == 'Date') {
        return DataColumn(
          label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          onSort: (colIndex, ascending) {
            setState(() {
              _sortColumn = 'date';
              _sortAscending = ascending;
            });
          },
        );
      } else if (colName == 'Project') {
        return DataColumn(
          label: const Text('Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          onSort: (colIndex, ascending) {
            setState(() {
              _sortColumn = 'project';
              _sortAscending = ascending;
            });
          },
        );
      } else if (colName == 'Amount') {
        return DataColumn(
          label: const Text('Amount (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          numeric: true,
          onSort: (colIndex, ascending) {
            setState(() {
              _sortColumn = 'amount';
              _sortAscending = ascending;
            });
          },
        );
      } else if (colName == 'Rate' || colName == 'Rate/Day' || colName == 'Rent Rate' || colName == 'Qty' || colName == 'Days' || colName == 'Duration') {
        return DataColumn(
          label: Text(colName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          numeric: true,
        );
      } else if (colName == 'Add More' || colName == 'Record Payment' || colName == 'Edit Entry') {
        return DataColumn(
          label: Text(colName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        );
      } else {
        return DataColumn(label: Text(colName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
      }
    }).toList();

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

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: provider.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Ask AI" banner (exactly as requested to keep)
                      _AskAiBanner(projectName: provider.selectedProjectName),
                      const SizedBox(height: 18),

                      // Filters Card Section
                      _buildFiltersCard(context, projectProvider),
                      const SizedBox(height: 20),

                      // Cost Summary Cards (Real-time dynamic calculations)
                      const Text(
                        'Filtered Cost Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                        children: [
                          _buildCostCard(
                            title: 'Total Cost',
                            value: grandTotal,
                            isFeatured: true,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          _buildCostCard(
                            title: 'Material',
                            value: materialTotal,
                            color: const Color(0xFF5B5FCF),
                            icon: Icons.construction,
                          ),
                          _buildCostCard(
                            title: 'Labour',
                            value: labourTotal,
                            color: AppColors.primaryPurple,
                            icon: Icons.people_outline,
                          ),
                          _buildCostCard(
                            title: 'Equipment',
                            value: equipmentTotal,
                            color: AppColors.primaryLightBlue,
                            icon: Icons.precision_manufacturing_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Category Quick Filter Tabs
                      _CategoryTabs(
                        activeTab: quickCategoryTab,
                        onTabChanged: (newTab) {
                          setState(() {
                            _currentPage = 1;
                            _searchQuery = '';
                            _selectedItemName = null;
                            _reportGenerated = false;
                            _searchController.clear();
                            _showSuggestions = false;
                            
                            if (newTab == 'All') {
                              _selectedTypes.addAll({
                                EntryType.material,
                                EntryType.labour,
                                EntryType.equipment,
                              });
                            } else if (newTab == 'Materials') {
                              _selectedTypes.clear();
                              _selectedTypes.add(EntryType.material);
                            } else if (newTab == 'Labour') {
                              _selectedTypes.clear();
                              _selectedTypes.add(EntryType.labour);
                            } else if (newTab == 'Equipment') {
                              _selectedTypes.clear();
                              _selectedTypes.add(EntryType.equipment);
                            }
                          });
                        },
                      ),
                      if (quickCategoryTab != 'All') ...[
                        const SizedBox(height: 14),
                        _buildCategorySubFilters(context, quickCategoryTab, allEntries),
                      ] else ...[
                        const SizedBox(height: 14),
                        _buildAllTabSearchBar(context),
                      ],
                      const SizedBox(height: 18),

                      // Dynamic Data Table Section
                      if (quickCategoryTab != 'All' && !_reportGenerated)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (quickCategoryTab == 'Materials'
                                            ? const Color(0xFF5B5FCF)
                                            : (quickCategoryTab == 'Labour'
                                                ? AppColors.primaryPurple
                                                : AppColors.primaryLightBlue))
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.analytics_outlined,
                                    size: 40,
                                    color: quickCategoryTab == 'Materials'
                                        ? const Color(0xFF5B5FCF)
                                        : (quickCategoryTab == 'Labour'
                                            ? AppColors.primaryPurple
                                            : AppColors.primaryLightBlue),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Configure filters above and tap\n"Generate CSV Report" to view logs.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quickCategoryTab == 'All' ? 'Report Logs' : '$quickCategoryTab Report Logs',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$totalCount entries found',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (quickCategoryTab == 'All') ...[
                                          InkWell(
                                            onTap: () => _showCustomizeColumnsDialog(context, quickCategoryTab),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary.withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.edit_note,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Edit Columns',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        IconButton(
                                          tooltip: 'View Full Screen',
                                          icon: const Icon(Icons.fullscreen, color: AppColors.primary, size: 22),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => _FullScreenLogsViewer(
                                                  columns: columns,
                                                  filteredEntries: filtered,
                                                  getProjectName: getProjectName,
                                                  quickCategoryTab: quickCategoryTab,
                                                  title: quickCategoryTab == 'All' ? 'Report Logs' : '$quickCategoryTab Report Logs',
                                                  onExportCsv: () => _handleCsvExport(filtered, getProjectName, quickCategoryTab, activeColumns: activeCols),
                                                  onExportPdf: () => _handlePdfExport(filtered, getProjectName, quickCategoryTab, activeColumns: activeCols),
                                                  activeColumns: uiActiveCols,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            cardColor: Colors.white,
                                          ),
                                          child: PopupMenuButton<String>(
                                            tooltip: 'Export options',
                                            offset: const Offset(0, 32),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (val) {
                                              if (val == 'csv') {
                                                _handleCsvExport(filtered, getProjectName, quickCategoryTab, activeColumns: activeCols);
                                              } else if (val == 'pdf') {
                                                _handlePdfExport(filtered, getProjectName, quickCategoryTab, activeColumns: activeCols);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'csv',
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Download CSV'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'pdf',
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Download PDF'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary.withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.download,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Export',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 2),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    size: 12,
                                                    color: AppColors.primary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Horizontal scroll wrapper for DataTable
                              if (paginatedEntries.isNotEmpty)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      cardColor: AppColors.cardBg,
                                    ),
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowColor: WidgetStateProperty.all(
                                        AppColors.primary.withValues(alpha: 0.04),
                                      ),
                                      horizontalMargin: 16,
                                      columnSpacing: 24,
                                      sortColumnIndex: (() {
                                        if (_sortColumn == 'date') {
                                          final idx = activeCols.indexOf('Date');
                                          return idx != -1 ? idx : null;
                                        } else if (_sortColumn == 'project') {
                                          final idx = activeCols.indexOf('Project');
                                          return idx != -1 ? idx : null;
                                        } else if (_sortColumn == 'amount') {
                                          final idx = activeCols.indexOf('Amount');
                                          return idx != -1 ? idx : null;
                                        }
                                        return null;
                                      })(),
                                      sortAscending: _sortAscending,
                                      columns: columns,
                                      rows: paginatedEntries.map((entry) {
                                        final projectName = getProjectName(entry.projectId);
                                        return _buildDataRowForCategory(
                                          context: context,
                                          entry: entry,
                                          projectName: projectName,
                                          quickCategoryTab: quickCategoryTab,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_outlined, size: 44, color: Colors.grey.shade400),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No transaction logs match filters.',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Pagination Row
                              if (totalCount > 0) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Show: ',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          DropdownButton<int>(
                                            value: _rowsPerPage,
                                            underline: const SizedBox(),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                            items: const [
                                              DropdownMenuItem(value: 10, child: Text('10')),
                                              DropdownMenuItem(value: 20, child: Text('20')),
                                              DropdownMenuItem(value: 50, child: Text('50')),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _rowsPerPage = val;
                                                  _currentPage = 1;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.chevron_left, size: 20),
                                            onPressed: safeCurrentPage > 1
                                                ? () {
                                                    setState(() {
                                                      _currentPage = safeCurrentPage - 1;
                                                    });
                                                  }
                                                : null,
                                          ),
                                          Text(
                                            'Page $safeCurrentPage of $totalPages',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right, size: 20),
                                            onPressed: safeCurrentPage < totalPages
                                                ? () {
                                                    setState(() {
                                                      _currentPage = safeCurrentPage + 1;
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  // Cost card builder helper
  Widget _buildCostCard({
    required String title,
    required double value,
    bool isFeatured = false,
    Color? color,
    required IconData icon,
  }) {
    final currencyStr = _formatIndianCurrency(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFeatured ? null : AppColors.cardBg,
        gradient: isFeatured
            ? const LinearGradient(
                colors: [Color(0xFF173EEA), Color(0xFF67C8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: isFeatured ? null : Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isFeatured ? 0.12 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isFeatured ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                icon,
                color: isFeatured ? Colors.white : (color ?? AppColors.primary),
                size: 18,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currencyStr,
                style: TextStyle(
                  color: isFeatured ? Colors.white : AppColors.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  // Filters Panel Widget Card (Redesigned as "Project Context" matching mockup)
  Widget _buildFiltersCard(BuildContext context, ProjectProvider projectProvider) {
    // Resolve selected project model
    final proj = projectProvider.projects
        .where((p) => p.id == _selectedProjectId)
        .firstOrNull;

    // Build project selector name
    final projectNameSelected = _selectedProjectId == 'all'
        ? 'All projects'
        : (proj?.name ?? 'Unknown Project');

    // Build floors options
    final floors = proj?.floors ?? [];

    // Build phase selected name
    final selectedPhase = proj?.selectedPhases
        ?.where((p) => p.id == _selectedPhaseId)
        .firstOrNull;
    final selectedPhaseName = selectedPhase?.phaseName ?? 'Select Phase';

    // Build activities options
    final List<ProjectActivity> activities = [];
    if (_selectedPhaseId != null) {
      activities.addAll(selectedPhase?.activities ?? []);
    } else if (proj != null) {
      activities.addAll(proj.selectedPhases?.expand((p) => p.activities).toList() ?? []);
    }
    final uniqueActivityNames = activities.map((a) => a.name).toSet().toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching mockup styling
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFF173EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Project Context',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select project details',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2x2 Grid of Dropdowns matching the layout mockup
                Row(
                  children: [
                    Expanded(
                      child: _buildProjectContextDropdown(
                        label: 'Project',
                        selectedLabel: projectNameSelected,
                        items: [
                          const PopupMenuItem(value: 'all', child: Text('All projects')),
                          ...projectProvider.projects.map((p) => PopupMenuItem(value: p.id, child: Text(p.name))),
                        ],
                        onSelected: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProjectId = val;
                              _selectedFloor = null;
                              _selectedPhaseId = null;
                              _selectedActivityName = null;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProjectContextDropdown(
                        label: 'Floor',
                        selectedLabel: _selectedFloor ?? 'Select Floor',
                        enabled: _selectedProjectId != 'all' && floors.isNotEmpty,
                        items: [
                          const PopupMenuItem(value: 'Select Floor', child: Text('Select Floor (All)')),
                          ...floors.map((f) => PopupMenuItem(value: f, child: Text(f))),
                        ],
                        onSelected: (val) {
                          setState(() {
                            _selectedFloor = (val == 'Select Floor') ? null : val;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildProjectContextDropdown(
                        label: 'Phase',
                        selectedLabel: selectedPhaseName,
                        enabled: _selectedProjectId != 'all' && (proj?.selectedPhases?.isNotEmpty ?? false),
                        items: [
                          const PopupMenuItem(value: 'Select Phase', child: Text('Select Phase (All)')),
                          ...(proj?.selectedPhases?.map((ph) => PopupMenuItem(value: ph.id, child: Text(ph.phaseName))) ?? []),
                        ],
                        onSelected: (val) {
                          setState(() {
                            _selectedPhaseId = (val == 'Select Phase') ? null : val;
                            _selectedActivityName = null;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProjectContextDropdown(
                        label: 'Activity',
                        selectedLabel: _selectedActivityName ?? 'Select Activity',
                        enabled: _selectedProjectId != 'all' && uniqueActivityNames.isNotEmpty,
                        items: [
                          const PopupMenuItem(value: 'Select Activity', child: Text('Select Activity (All)')),
                          ...uniqueActivityNames.map((name) => PopupMenuItem(value: name, child: Text(name))),
                        ],
                        onSelected: (val) {
                          setState(() {
                            _selectedActivityName = (val == 'Select Activity') ? null : val;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Preset Selector styled like other dropdowns
                _buildProjectContextDropdown(
                  label: 'Date Period',
                  selectedLabel: _datePreset,
                  items: const [
                    PopupMenuItem(value: 'All Time', child: Text('All Time')),
                    PopupMenuItem(value: 'Today', child: Text('Today')),
                    PopupMenuItem(value: 'This Week', child: Text('This Week')),
                    PopupMenuItem(value: 'This Month', child: Text('This Month')),
                    PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                    PopupMenuItem(value: 'This Year', child: Text('This Year')),
                    PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
                  ],
                  onSelected: (val) {
                    if (val != null) {
                      _setDatePreset(val);
                    }
                  },
                ),

                // Custom date pickers using the matching style box
                if (_datePreset == 'Custom') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerBox(
                          label: 'Start Date',
                          selectedLabel: _startDate == null ? 'Select Date' : _formatDateShort(_startDate!),
                          onTap: () => _selectStartDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePickerBox(
                          label: 'End Date',
                          selectedLabel: _endDate == null ? 'Select Date' : _formatDateShort(_endDate!),
                          onTap: () => _selectEndDate(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom Dropdown UI helper using PopupMenuButton to display options
  Widget _buildProjectContextDropdown({
    required String label,
    required String selectedLabel,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String?> onSelected,
    bool enabled = true,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: Colors.white,
      ),
      child: PopupMenuButton<String>(
        enabled: enabled,
        onSelected: onSelected,
        itemBuilder: (context) => items,
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? const Color(0xFFE2E4FA) : Colors.grey.shade200,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: enabled ? AppColors.textSecondary : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppColors.textPrimary : Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: enabled ? const Color(0xFF6B7280) : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditColumnsButton(String tabName) {
    return InkWell(
      onTap: () => _showCustomizeColumnsDialog(context, tabName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.edit_note,
              size: 16,
              color: AppColors.primary,
            ),
            SizedBox(width: 4),
            Text(
              'Edit Columns',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Date selection input box helper matching project context dropdown aesthetics
  Widget _buildDatePickerBox({
    required String label,
    required String selectedLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E4FA),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.date_range_outlined,
              color: Color(0xFF6B7280),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Search bar helper panel for All tab
  Widget _buildAllTabSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by description, brand, project, phase, activity...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E4FA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E4FA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Category specific sub-filters helper panel
  Widget _buildCategorySubFilters(BuildContext context, String tabName, List<EntryModel> allEntries) {
    final String searchPlaceholder;
    final String dropdownLabel;
    final EntryType targetType;
    if (tabName == 'Materials') {
      searchPlaceholder = 'Search Materials...';
      dropdownLabel = 'Material Name';
      targetType = EntryType.material;
    } else if (tabName == 'Labour') {
      searchPlaceholder = 'Search Labour...';
      dropdownLabel = 'Worker Type';
      targetType = EntryType.labour;
    } else {
      searchPlaceholder = 'Search Equipment...';
      dropdownLabel = 'Equipment Name';
      targetType = EntryType.equipment;
    }

    final uniqueNames = allEntries
        .where((e) => e.type == targetType && (_selectedProjectId == 'all' || e.projectId.trim() == _selectedProjectId.trim()))
        .map((e) => e.description)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final suggestions = uniqueNames
        .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final showSuggestionsList = _showSuggestions &&
        _searchQuery.isNotEmpty &&
        suggestions.isNotEmpty &&
        !(suggestions.length == 1 && suggestions.first.toLowerCase() == _searchQuery.toLowerCase());

    return TapRegion(
      onTapOutside: (event) {
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                  _showSuggestions = true;
                  if (_selectedItemName != null && _selectedItemName != _searchQuery) {
                    _selectedItemName = null;
                  }
                });
              },
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: searchPlaceholder,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E4FA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E4FA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            if (showSuggestionsList) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E4FA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: suggestions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final name = suggestions[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.text = name;
                          _searchQuery = name;
                          _selectedItemName = name;
                          _showSuggestions = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.subdirectory_arrow_right_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildProjectContextDropdown(
                    label: dropdownLabel,
                    selectedLabel: _selectedItemName ?? 'All',
                    items: [
                      const PopupMenuItem(value: 'All', child: Text('All')),
                      ...uniqueNames.map((name) => PopupMenuItem(value: name, child: Text(name))),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _selectedItemName = (val == 'All' || val == null) ? null : val;
                        final selectedVal = val == 'All' ? '' : (val ?? '');
                        _searchController.text = selectedVal;
                        _searchQuery = selectedVal;
                        _showSuggestions = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _buildEditColumnsButton(tabName),
              ],
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Generate CSV Report', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tabName == 'Materials'
                      ? const Color(0xFF5B5FCF)
                      : (tabName == 'Labour' ? AppColors.primaryPurple : AppColors.primaryLightBlue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _reportGenerated = true;
                    _currentPage = 1;
                    _showSuggestions = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Type Chip inside table
  Widget _buildTypeChip(EntryType type) {
    Color color;
    IconData icon;
    switch (type) {
      case EntryType.material:
        color = const Color(0xFF5B5FCF);
        icon = Icons.construction;
        break;
      case EntryType.labour:
        color = AppColors.primaryPurple;
        icon = Icons.people_outline;
        break;
      case EntryType.equipment:
        color = AppColors.primaryLightBlue;
        icon = Icons.precision_manufacturing_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Status Badge helper
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    final label = _getPaymentStatusLabel(status);
    switch (label) {
      case 'Fully Paid':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case 'Partial':
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        break;
      case 'Not Paid':
      default:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Detail Modal Dialog popup on Row Click
  void _showEntryDetailsDialog(BuildContext context, EntryModel entry, String projectName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Entry Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow('Project', projectName),
                  _buildDetailRow('Type', entry.type.name.toUpperCase()),
                  _buildDetailRow('Date', _formatDateLong(entry.date)),
                  _buildDetailRow('Amount', _formatIndianCurrency(entry.amount)),
                  _buildDetailRow('Status', _getPaymentStatusLabel(entry.paymentStatus)),
                  if (entry.description.isNotEmpty) _buildDetailRow('Description', entry.description),
                  if (entry.brand != null && entry.brand!.isNotEmpty) _buildDetailRow('Brand', entry.brand!),
                  if (entry.floor != null && entry.floor!.isNotEmpty) _buildDetailRow('Floor', entry.floor!),
                  if (entry.phase != null) _buildDetailRow('Phase', entry.phase!.name),
                  if (entry.unit != null && entry.unit!.isNotEmpty) _buildDetailRow('Unit', entry.unit!),
                  if (entry.rejectionReason != null && entry.rejectionReason!.isNotEmpty)
                    _buildDetailRow('Rejection Reason', entry.rejectionReason!, isWarning: true),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Add More',
                          icon: Icons.add_circle_outline,
                          style: _ReportActionStyle.primary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.addMore(context, entry);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Record Payment',
                          icon: Icons.credit_card_outlined,
                          style: _ReportActionStyle.secondary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.recordPayment(context, entry, projectName);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Edit Entry',
                          icon: Icons.edit_outlined,
                          style: _ReportActionStyle.tertiary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.editEntry(context, entry);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? AppColors.error : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRowForCategory({
    required BuildContext context,
    required EntryModel entry,
    required String projectName,
    required String quickCategoryTab,
  }) {
    final List<String> activeCols = _getActiveColumnsForTab(quickCategoryTab);
    final List<String> uiActiveCols = [...activeCols, 'Add More', 'Record Payment', 'Edit Entry'];

    final List<DataCell> cells = uiActiveCols.map((colName) {
      if (colName == 'Purchased Date') {
        return DataCell(Text(_formatDateShort(entry.date), style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Payment Date') {
        final payDateStr = entry.paymentDate != null ? _formatDateShort(entry.paymentDate!) : '—';
        return DataCell(Text(payDateStr, style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Project') {
        return DataCell(Text(projectName, style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Type') {
        return DataCell(_buildTypeChip(entry.type));
      } else if (colName == 'Description') {
        return DataCell(Text(entry.description.isEmpty ? '—' : entry.description, style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Material' || colName == 'Worker Type' || colName == 'Equipment') {
        return DataCell(Text(entry.description, style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Brand') {
        return DataCell(Text(entry.brand ?? '—', style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Floor') {
        return DataCell(Text(entry.floor ?? '—', style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Phase') {
        return DataCell(Text(entry.phase?.name ?? '—', style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Activity') {
        return DataCell(Text(entry.activity ?? '—', style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Unit') {
        return DataCell(Text(entry.unit ?? '—', style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Status') {
        return DataCell(_buildStatusBadge(entry.paymentStatus));
      } else if (colName == 'Amount') {
        return DataCell(Text(_formatIndianCurrency(entry.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
      } else if (colName == 'Rate' || colName == 'Rate/Day' || colName == 'Rent Rate') {
        final rate = entry.ratePerUnit ?? 0.0;
        return DataCell(Text(_formatIndianCurrency(rate), style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Qty' || colName == 'Days' || colName == 'Duration') {
        final rate = entry.ratePerUnit ?? 0.0;
        final val = (rate == 0) ? 0.0 : entry.amount / rate;
        return DataCell(Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 12)));
      } else if (colName == 'Add More') {
        return DataCell(
          _ReportActionBtn(
            label: 'Add More',
            icon: Icons.add_circle_outline,
            style: _ReportActionStyle.primary,
            onTap: () => _ReportActions.addMore(context, entry),
          ),
        );
      } else if (colName == 'Record Payment') {
        return DataCell(
          _ReportActionBtn(
            label: 'Record Payment',
            icon: Icons.credit_card_outlined,
            style: _ReportActionStyle.secondary,
            onTap: () => _ReportActions.recordPayment(context, entry, projectName),
          ),
        );
      } else if (colName == 'Edit Entry') {
        return DataCell(
          _ReportActionBtn(
            label: 'Edit Entry',
            icon: Icons.edit_outlined,
            style: _ReportActionStyle.tertiary,
            onTap: () => _ReportActions.editEntry(context, entry),
          ),
        );
      } else {
        return const DataCell(SizedBox.shrink());
      }
    }).toList();

    return DataRow(
      onSelectChanged: (selected) {
        if (selected ?? false) {
          _showEntryDetailsDialog(context, entry, projectName);
        }
      },
      cells: cells,
    );
  }
}

// ─── Ask AI banner button (exactly as originally styled) ─────────────────────

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
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask AI',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ask about costs, entries & inventory',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category Quick Filter Tabs ────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.activeTab, required this.onTabChanged});

  final String activeTab;
  final ValueChanged<String> onTabChanged;

  static const _tabs = ['All', 'Materials', 'Labour', 'Equipment'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final active = tab == activeTab;
          Color activeColor;
          switch (tab) {
            case 'Materials':
              activeColor = const Color(0xFF5B5FCF);
              break;
            case 'Labour':
              activeColor = AppColors.primaryPurple;
              break;
            case 'Equipment':
              activeColor = AppColors.primaryLightBlue;
              break;
            case 'All':
            default:
              activeColor = AppColors.primary;
              break;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? activeColor : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FullScreenLogsViewer extends StatefulWidget {
  const _FullScreenLogsViewer({
    required this.columns,
    required this.filteredEntries,
    required this.getProjectName,
    required this.quickCategoryTab,
    required this.title,
    required this.onExportCsv,
    required this.onExportPdf,
    required this.activeColumns,
  });

  final List<DataColumn> columns;
  final List<EntryModel> filteredEntries;
  final String Function(String) getProjectName;
  final String quickCategoryTab;
  final String title;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;
  final List<String> activeColumns;

  @override
  State<_FullScreenLogsViewer> createState() => _FullScreenLogsViewerState();
}

class _FullScreenLogsViewerState extends State<_FullScreenLogsViewer> {
  int _quarterTurns = 0; // 0 for straight, 1 for rotated 90 deg

  void _toggleRotation() {
    setState(() {
      _quarterTurns = (_quarterTurns == 0) ? 1 : 0;
    });
  }

  String _formatDateShort(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year.toString().substring(dt.year.toString().length - 2);
    return '$day $month $year';
  }

  String _formatIndianCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];

    if (whole.length <= 3) {
      return 'Rs. $whole.$decimal';
    }

    final lastThree = whole.substring(whole.length - 3);
    final remaining = whole.substring(0, whole.length - 3);

    final buffer = StringBuffer();
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      if (count > 0 && count % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
      count++;
    }
    final formattedRemaining = buffer.toString().split('').reversed.join('');
    return 'Rs. $formattedRemaining,$lastThree.$decimal';
  }

  Widget _buildTypeChip(EntryType type) {
    Color color;
    IconData icon;
    switch (type) {
      case EntryType.material:
        color = const Color(0xFF5B5FCF);
        icon = Icons.construction;
        break;
      case EntryType.labour:
        color = AppColors.primaryPurple;
        icon = Icons.people_outline;
        break;
      case EntryType.equipment:
        color = AppColors.primaryLightBlue;
        icon = Icons.precision_manufacturing_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    final label = _getPaymentStatusLabel(status);
    switch (label) {
      case 'Fully Paid':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case 'Partial':
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        break;
      case 'Not Paid':
      default:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showEntryDetailsDialog(BuildContext context, EntryModel entry, String projectName) {
    String formatDateLong(DateTime dt) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour24 = dt.hour;
      final ampm = hour24 >= 12 ? 'PM' : 'AM';
      var hour12 = hour24 % 12;
      if (hour12 == 0) hour12 = 12;
      final hour = hour12.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute $ampm';
    }

    Widget detailRow(String label, String value, {bool isWarning = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWarning ? AppColors.error : AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Entry Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  detailRow('Project', projectName),
                  detailRow('Type', entry.type.name.toUpperCase()),
                  detailRow('Date', formatDateLong(entry.date)),
                  detailRow('Amount', _formatIndianCurrency(entry.amount)),
                  detailRow('Status', _getPaymentStatusLabel(entry.paymentStatus)),
                  if (entry.description.isNotEmpty) detailRow('Description', entry.description),
                  if (entry.brand != null && entry.brand!.isNotEmpty) detailRow('Brand', entry.brand!),
                  if (entry.floor != null && entry.floor!.isNotEmpty) detailRow('Floor', entry.floor!),
                  if (entry.phase != null) detailRow('Phase', entry.phase!.name),
                  if (entry.unit != null && entry.unit!.isNotEmpty) detailRow('Unit', entry.unit!),
                  if (entry.rejectionReason != null && entry.rejectionReason!.isNotEmpty)
                    detailRow('Rejection Reason', entry.rejectionReason!, isWarning: true),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Add More',
                          icon: Icons.add_circle_outline,
                          style: _ReportActionStyle.primary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.addMore(context, entry);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Record Payment',
                          icon: Icons.credit_card_outlined,
                          style: _ReportActionStyle.secondary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.recordPayment(context, entry, projectName);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportActionBtn(
                          label: 'Edit Entry',
                          icon: Icons.edit_outlined,
                          style: _ReportActionStyle.tertiary,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _ReportActions.editEntry(context, entry);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rotated = _quarterTurns != 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.title} (${widget.filteredEntries.length} entries)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: rotated ? 'Straight View' : 'Rotate View (Landscape)',
            icon: Icon(rotated ? Icons.screen_lock_portrait : Icons.screen_rotation, color: AppColors.primary),
            onPressed: _toggleRotation,
          ),
          Theme(
            data: Theme.of(context).copyWith(cardColor: Colors.white),
            child: PopupMenuButton<String>(
              tooltip: 'Export Options',
              icon: const Icon(Icons.download, color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'csv') {
                  widget.onExportCsv();
                } else if (val == 'pdf') {
                  widget.onExportPdf();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: const [
                      Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Download CSV'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: const [
                      Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Download PDF'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rows = widget.filteredEntries.map((entry) {
              final projectName = widget.getProjectName(entry.projectId);
              final List<DataCell> cells = widget.activeColumns.map((colName) {
                if (colName == 'Purchased Date') {
                  return DataCell(Text(_formatDateShort(entry.date), style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Payment Date') {
                  final payDateStr = entry.paymentDate != null ? _formatDateShort(entry.paymentDate!) : '—';
                  return DataCell(Text(payDateStr, style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Project') {
                  return DataCell(Text(projectName, style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Type') {
                  return DataCell(_buildTypeChip(entry.type));
                } else if (colName == 'Description') {
                  return DataCell(Text(entry.description.isEmpty ? '—' : entry.description, style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Material' || colName == 'Worker Type' || colName == 'Equipment') {
                  return DataCell(Text(entry.description, style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Brand') {
                  return DataCell(Text(entry.brand ?? '—', style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Floor') {
                  return DataCell(Text(entry.floor ?? '—', style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Phase') {
                  return DataCell(Text(entry.phase?.name ?? '—', style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Activity') {
                  return DataCell(Text(entry.activity ?? '—', style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Unit') {
                  return DataCell(Text(entry.unit ?? '—', style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Status') {
                  return DataCell(_buildStatusBadge(entry.paymentStatus));
                } else if (colName == 'Amount') {
                  return DataCell(Text(_formatIndianCurrency(entry.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
                } else if (colName == 'Rate' || colName == 'Rate/Day' || colName == 'Rent Rate') {
                  final rate = entry.ratePerUnit ?? 0.0;
                  return DataCell(Text(_formatIndianCurrency(rate), style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Qty' || colName == 'Days' || colName == 'Duration') {
                  final rate = entry.ratePerUnit ?? 0.0;
                  final val = (rate == 0) ? 0.0 : entry.amount / rate;
                  return DataCell(Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 12)));
                } else if (colName == 'Add More') {
                  return DataCell(
                    _ReportActionBtn(
                      label: 'Add More',
                      icon: Icons.add_circle_outline,
                      style: _ReportActionStyle.primary,
                      onTap: () => _ReportActions.addMore(context, entry),
                    ),
                  );
                } else if (colName == 'Record Payment') {
                  return DataCell(
                    _ReportActionBtn(
                      label: 'Record Payment',
                      icon: Icons.credit_card_outlined,
                      style: _ReportActionStyle.secondary,
                      onTap: () => _ReportActions.recordPayment(context, entry, projectName),
                    ),
                  );
                } else if (colName == 'Edit Entry') {
                  return DataCell(
                    _ReportActionBtn(
                      label: 'Edit Entry',
                      icon: Icons.edit_outlined,
                      style: _ReportActionStyle.tertiary,
                      onTap: () => _ReportActions.editEntry(context, entry),
                    ),
                  );
                } else {
                  return const DataCell(SizedBox.shrink());
                }
              }).toList();

              return DataRow(
                onSelectChanged: (selected) {
                  if (selected ?? false) {
                    _showEntryDetailsDialog(context, entry, projectName);
                  }
                },
                cells: cells,
              );
            }).toList();

            Widget tableWidget = SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(context).copyWith(cardColor: Colors.white),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.04)),
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    columns: widget.columns,
                    rows: rows,
                  ),
                ),
              ),
            );

            if (rotated) {
              tableWidget = RotatedBox(
                quarterTurns: _quarterTurns,
                child: SizedBox(
                  width: constraints.maxHeight,
                  height: constraints.maxWidth,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(cardColor: Colors.white),
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.04)),
                          horizontalMargin: 16,
                          columnSpacing: 24,
                          columns: widget.columns,
                          rows: rows,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Center(child: tableWidget);
          },
        ),
      ),
    );
  }
}

String _getPaymentStatusLabel(String status) {
  switch (status.toLowerCase().trim()) {
    case 'paid':
    case 'fully paid':
    case 'fullypaid':
      return 'Fully Paid';
    case 'partial':
      return 'Partial';
    case 'pending':
    case 'not paid':
    case 'notpaid':
    case 'unpaid':
    default:
      return 'Not Paid';
  }
}

// ─── REPORT LOG ACTION HELPERS & BUTTONS ────────────────────────────────────

enum _ReportActionStyle { primary, secondary, tertiary }

class _ReportActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final _ReportActionStyle style;
  final VoidCallback onTap;

  const _ReportActionBtn({
    required this.label,
    required this.icon,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration deco;
    Color color;

    switch (style) {
      case _ReportActionStyle.primary:
        deco = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(6),
        );
        color = Colors.white;
        break;
      case _ReportActionStyle.secondary:
        deco = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1.0),
        );
        color = const Color(0xFF3B82F6);
        break;
      case _ReportActionStyle.tertiary:
        deco = BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        );
        color = const Color(0xFF4B5563);
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: deco,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportActions {
  static void addMore(BuildContext context, EntryModel entry) {
    final dupArgs = entry.toJson();
    dupArgs['isDuplicate'] = true;
    dupArgs['sourceTransactionId'] = entry.id;
    dupArgs['projectId'] = entry.projectId;

    String route;
    switch (entry.type) {
      case EntryType.labour:
        route = '/add-labour';
        break;
      case EntryType.equipment:
        route = '/add-equipment';
        break;
      case EntryType.material:
        route = '/add-material';
        break;
    }
    Navigator.pushNamed(context, route, arguments: dupArgs).then((val) {
      if (context.mounted) {
        context.read<ProjectProvider>().load();
      }
    });
  }

  static void editEntry(BuildContext context, EntryModel entry) {
    final editArgs = entry.toJson();
    editArgs['isEditing'] = true;
    editArgs['id'] = entry.id;
    editArgs['projectId'] = entry.projectId;

    String route;
    switch (entry.type) {
      case EntryType.labour:
        route = '/add-labour';
        break;
      case EntryType.equipment:
        route = '/add-equipment';
        break;
      case EntryType.material:
        route = '/add-material';
        break;
    }
    Navigator.pushNamed(context, route, arguments: editArgs).then((val) {
      if (context.mounted) {
        context.read<ProjectProvider>().load();
      }
    });
  }

  static Future<void> recordPayment(BuildContext context, EntryModel entry, String projectName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final tx = await ApiService.fetchTransactionById(entry.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (tx == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load transaction details.')),
        );
      }
      return;
    }

    final pId = entry.projectId;
    final pName = projectName;
    final rawItemName = tx['materialName'] ?? tx['itemName'] ?? tx['title'] ?? tx['name'] ?? entry.description;
    final itemType = tx['type'] ?? entry.type.name;
    final qty = (tx['quantity'] as num?)?.toDouble() ?? ((entry.ratePerUnit ?? 0) == 0 ? 0.0 : entry.amount / entry.ratePerUnit!);
    final rate = (tx['rate'] as num?)?.toDouble() ?? entry.ratePerUnit ?? 0.0;
    final totalAmount = (tx['amount'] as num?)?.toDouble() ?? entry.amount;
    final paidAmount = (tx['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final outstandingAmount = (totalAmount - paidAmount).clamp(0.0, double.infinity);
    final payStatus = EntryModel.fromJson(tx).paymentStatus;

    final payArgs = {
      'id': entry.id,
      'projectId': pId,
      'projectName': pName,
      'itemId': tx['materialId'] ?? tx['itemId'] ?? '',
      'itemName': rawItemName,
      'itemType': itemType,
      'quantity': qty,
      'rate': rate,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'paymentStatus': payStatus,
      'receipt': (tx['attachments'] is List && tx['attachments'].isNotEmpty) ? tx['attachments'].first?.toString() : null,
      'transactionDetails': tx,
    };

    if (context.mounted) {
      Navigator.pushNamed(
        context,
        '/fulfillment-payment',
        arguments: payArgs,
      ).then((updated) {
        if (updated == true && context.mounted) {
          context.read<ProjectProvider>().load();
        }
      });
    }
  }
}
