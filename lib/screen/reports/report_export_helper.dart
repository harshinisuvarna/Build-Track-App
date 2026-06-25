import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'save_helper_stub.dart'
    if (dart.library.html) 'save_helper_web.dart'
    if (dart.library.io) 'save_helper_mobile.dart';

class ReportExportHelper {
  static String _formatYmd(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatIndianCurrency(double amount) {
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

  /// Export entries as a CSV file and open share sheet / download
  static Future<void> exportToCsv({
    required List<EntryModel> entries,
    required String Function(String) getProjectName,
    required String quickCategoryTab,
  }) async {
    if (entries.isEmpty) return;

    final csvBuffer = StringBuffer();
    final List<String> headers;
    if (quickCategoryTab == 'Materials') {
      headers = ['Date', 'Project', 'Material', 'Brand', 'Rate', 'Qty', 'Unit', 'Status', 'Amount (INR)'];
    } else if (quickCategoryTab == 'Labour') {
      headers = ['Date', 'Project', 'Worker Type', 'Rate/Day', 'Days', 'Status', 'Amount (INR)'];
    } else if (quickCategoryTab == 'Equipment') {
      headers = ['Date', 'Project', 'Equipment', 'Rent Rate', 'Duration', 'Status', 'Amount (INR)'];
    } else {
      headers = ['Date', 'Project', 'Type', 'Description', 'Brand', 'Floor', 'Phase', 'Activity', 'Unit', 'Status', 'Amount (INR)'];
    }

    // Write header line with quotes
    csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    for (final entry in entries) {
      final dateStr = _formatYmd(entry.date);
      final projectName = getProjectName(entry.projectId);
      final amount = entry.amount;
      final status = entry.approvalStatus;

      final List<String> rowValues;
      if (quickCategoryTab == 'Materials') {
        final rate = entry.ratePerUnit ?? 0.0;
        final qty = (rate == 0) ? 0.0 : entry.amount / rate;
        rowValues = [
          dateStr,
          projectName,
          entry.description,
          entry.brand ?? '—',
          rate.toStringAsFixed(2),
          qty.toStringAsFixed(1),
          entry.unit ?? 'unit',
          status,
          amount.toStringAsFixed(2),
        ];
      } else if (quickCategoryTab == 'Labour') {
        final rate = entry.ratePerUnit ?? 0.0;
        final days = (rate == 0) ? 0.0 : entry.amount / rate;
        rowValues = [
          dateStr,
          projectName,
          entry.description,
          rate.toStringAsFixed(2),
          days.toStringAsFixed(1),
          status,
          amount.toStringAsFixed(2),
        ];
      } else if (quickCategoryTab == 'Equipment') {
        final rate = entry.ratePerUnit ?? 0.0;
        final duration = (rate == 0) ? 0.0 : entry.amount / rate;
        rowValues = [
          dateStr,
          projectName,
          entry.description,
          rate.toStringAsFixed(2),
          duration.toStringAsFixed(1),
          status,
          amount.toStringAsFixed(2),
        ];
      } else {
        rowValues = [
          dateStr,
          projectName,
          entry.type.name.toUpperCase(),
          entry.description.isEmpty ? '—' : entry.description,
          entry.brand ?? '—',
          entry.floor ?? '—',
          entry.phase?.name ?? '—',
          entry.activity ?? '—',
          entry.unit ?? '—',
          status,
          amount.toStringAsFixed(2),
        ];
      }

      final escapedRow = rowValues.map((val) => '"${val.replaceAll('"', '""')}"').join(',');
      csvBuffer.writeln(escapedRow);
    }

    final filename = 'BuildTrack_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final shareText = 'BuildTrack Filtered Report (${entries.length} entries)';

    await saveAndShareCsv(
      csvContent: csvBuffer.toString(),
      filename: filename,
      shareText: shareText,
    );
  }

  /// Generate and open PDF print preview
  static Future<void> exportToPdf({
    required List<EntryModel> entries,
    required String Function(String) getProjectName,
    required String title,
    required String filterSummary,
    required String quickCategoryTab,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    double materialTotal = 0;
    double labourTotal = 0;
    double equipmentTotal = 0;
    double grandTotal = 0;

    for (final entry in entries) {
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

    final List<String> pdfHeaders;
    final List<List<String>> pdfData;
    final Map<int, pw.Alignment> cellAlignmentsMap;
    final double headerFontSize;
    final double cellFontSize;

    if (quickCategoryTab == 'Materials') {
      pdfHeaders = ['Date', 'Project', 'Material', 'Brand', 'Rate', 'Qty', 'Unit', 'Status', 'Amount (INR)'];
      headerFontSize = 8;
      cellFontSize = 7;
      cellAlignmentsMap = {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
        8: pw.Alignment.centerRight,
      };
      pdfData = entries.map((e) {
        final rate = e.ratePerUnit ?? 0.0;
        final qty = (rate == 0) ? 0.0 : e.amount / rate;
        return [
          _formatYmd(e.date),
          getProjectName(e.projectId),
          e.description.isEmpty ? '—' : e.description,
          e.brand ?? '—',
          _formatIndianCurrency(rate),
          qty.toStringAsFixed(1),
          e.unit ?? 'unit',
          e.approvalStatus,
          _formatIndianCurrency(e.amount),
        ];
      }).toList();
    } else if (quickCategoryTab == 'Labour') {
      pdfHeaders = ['Date', 'Project', 'Worker Type', 'Rate/Day', 'Days', 'Status', 'Amount (INR)'];
      headerFontSize = 8;
      cellFontSize = 7;
      cellAlignmentsMap = {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      };
      pdfData = entries.map((e) {
        final rate = e.ratePerUnit ?? 0.0;
        final days = (rate == 0) ? 0.0 : e.amount / rate;
        return [
          _formatYmd(e.date),
          getProjectName(e.projectId),
          e.description.isEmpty ? '—' : e.description,
          _formatIndianCurrency(rate),
          days.toStringAsFixed(1),
          e.approvalStatus,
          _formatIndianCurrency(e.amount),
        ];
      }).toList();
    } else if (quickCategoryTab == 'Equipment') {
      pdfHeaders = ['Date', 'Project', 'Equipment', 'Rent Rate', 'Duration', 'Status', 'Amount (INR)'];
      headerFontSize = 8;
      cellFontSize = 7;
      cellAlignmentsMap = {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      };
      pdfData = entries.map((e) {
        final rate = e.ratePerUnit ?? 0.0;
        final duration = (rate == 0) ? 0.0 : e.amount / rate;
        return [
          _formatYmd(e.date),
          getProjectName(e.projectId),
          e.description.isEmpty ? '—' : e.description,
          _formatIndianCurrency(rate),
          duration.toStringAsFixed(1),
          e.approvalStatus,
          _formatIndianCurrency(e.amount),
        ];
      }).toList();
    } else {
      // All
      pdfHeaders = ['Date', 'Project', 'Type', 'Description', 'Brand', 'Floor', 'Phase', 'Activity', 'Unit', 'Status', 'Amount (INR)'];
      headerFontSize = 7;
      cellFontSize = 6;
      cellAlignmentsMap = {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerLeft,
        6: pw.Alignment.centerLeft,
        7: pw.Alignment.centerLeft,
        8: pw.Alignment.center,
        9: pw.Alignment.center,
        10: pw.Alignment.centerRight,
      };
      pdfData = entries.map((e) {
        return [
          _formatYmd(e.date),
          getProjectName(e.projectId),
          e.type.name.toUpperCase(),
          e.description.isEmpty ? '—' : e.description,
          e.brand ?? '—',
          e.floor ?? '—',
          e.phase?.name ?? '—',
          e.activity ?? '—',
          e.unit ?? '—',
          e.approvalStatus,
          _formatIndianCurrency(e.amount),
        ];
      }).toList();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Branded Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BuildTrack Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#173EEA'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColor.fromHex('#6B7280'),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on:',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      _formatDateTime(DateTime.now()),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColor.fromHex('#173EEA')),
            pw.SizedBox(height: 12),

            // Active Filters Box
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F4F6'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Filters applied: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      filterSummary,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Totals Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfSummaryCard('Material', _formatIndianCurrency(materialTotal), '#5B5FCF'),
                _buildPdfSummaryCard('Labour', _formatIndianCurrency(labourTotal), '#B137FF'),
                _buildPdfSummaryCard('Equipment', _formatIndianCurrency(equipmentTotal), '#67C8FF'),
                _buildPdfSummaryCard('Total Cost', _formatIndianCurrency(grandTotal), '#173EEA'),
              ],
            ),
            pw.SizedBox(height: 20),

            // Table Header
            pw.Text(
              'Report Logs',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1A2E'),
              ),
            ),
            pw.SizedBox(height: 8),

            // Data Table
            pw.TableHelper.fromTextArray(
              context: context,
              headers: pdfHeaders,
              data: pdfData,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: headerFontSize,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#173EEA'),
              ),
              cellStyle: pw.TextStyle(fontSize: cellFontSize),
              cellAlignments: cellAlignmentsMap,
            ),
          ];
        },
      ),
    );

    // Open print preview UI using the printing package
    await Printing.layoutPdf(
      name: 'BuildTrack_Report_${_formatYmd(DateTime.now())}',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildPdfSummaryCard(String title, String value, String colorHex) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(colorHex),
            ),
          ),
        ],
      ),
    );
  }
}
