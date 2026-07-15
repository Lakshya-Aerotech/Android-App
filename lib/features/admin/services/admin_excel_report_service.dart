import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/admin_analytics.dart';

class AdminExcelReportService {
  Future<String> generate(
    ReportPreviewData preview,
    AdminAnalyticsData analyticsData,
  ) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) excel.delete(defaultSheet);

    if (preview.definition.type == AdminReportType.complete) {
      _addSheet(
        excel,
        'Executive Summary',
        preview,
        AnalyticsTable(
          columns: ['Metric', 'Value'],
          rows: preview.summary.map((m) => [m.title, m.value]).toList(),
        ),
      );
      _addSheet(excel, 'Bookings', preview, analyticsData.bookingTable);
      _addSheet(
        excel,
        'Pesticide Spraying',
        preview,
        AnalyticsTable(
          columns: ['Metric', 'Value'],
          rows: analyticsData.pesticideMetrics
              .map((m) => [m.title, m.value])
              .toList(),
        ),
      );
      _addSheet(excel, 'Farmers', preview, analyticsData.topFarmers);
      _addSheet(excel, 'Pilot Performance', preview, analyticsData.pilotTable);
      _addSheet(excel, 'Drone Fleet', preview, analyticsData.droneTable);
      _addSheet(
        excel,
        'Operations Performance',
        preview,
        AnalyticsTable(
          columns: ['Metric', 'Value'],
          rows: analyticsData.operationsMetrics
              .map((m) => [m.title, m.value])
              .toList(),
        ),
      );
      _addSheet(
        excel,
        'Geographic Analysis',
        preview,
        analyticsData.geographicTable,
      );
      _addSheet(
        excel,
        'Revenue',
        preview,
        AnalyticsTable(
          columns: ['Metric', 'Value'],
          rows: [
            [
              'Revenue data available',
              analyticsData.hasRevenueData ? 'Yes' : 'No',
            ],
            ...analyticsData.overview
                .where((m) => m.title == 'Total Revenue')
                .map((m) => [m.title, m.value]),
          ],
        ),
      );
    } else {
      _addSheet(
        excel,
        _safeSheetName(preview.definition.title),
        preview,
        preview.table,
      );
    }

    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel encoding failed.');

    final directory = await getApplicationDocumentsDirectory();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final name = preview.definition.title
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final file = File('${directory.path}/Lakshya_Aerotech_${name}_$date.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: preview.definition.title,
      text: 'Lakshya Aerotech ${preview.definition.title}',
    );
    return file.path;
  }

  void _addSheet(
    Excel excel,
    String sheetName,
    ReportPreviewData preview,
    AnalyticsTable table,
  ) {
    final sheet = excel[_safeSheetName(sheetName)];
    var row = 0;
    _writeRow(sheet, row++, ['Lakshya Aerotech']);
    _writeRow(sheet, row++, [preview.definition.title]);
    _writeRow(sheet, row++, ['Date Range', preview.filter.dateRange.label]);
    _writeRow(sheet, row++, ['State', preview.filter.state]);
    _writeRow(sheet, row++, ['District', preview.filter.district]);
    _writeRow(sheet, row++, [
      'Booking Status',
      preview.filter.status?.displayName ?? 'All',
    ]);
    _writeRow(sheet, row++, [
      'Generated',
      DateFormat('d MMM yyyy, h:mm a').format(preview.generatedAt),
    ]);
    row++;

    if (table.columns.isEmpty) {
      _writeRow(sheet, row, ['No records available']);
      return;
    }

    _writeRow(sheet, row++, table.columns, bold: true);
    for (final tableRow in table.rows) {
      _writeRow(sheet, row++, tableRow);
    }

    for (var i = 0; i < table.columns.length; i++) {
      sheet.setColumnWidth(i, 22);
    }
  }

  void _writeRow(
    Sheet sheet,
    int rowIndex,
    List<String> values, {
    bool bold = false,
  }) {
    for (var column = 0; column < values.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
      );
      cell.value = TextCellValue(values[column]);
      if (bold) {
        cell.cellStyle = CellStyle(bold: true);
      }
    }
  }

  String _safeSheetName(String name) {
    final safe = name.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
    return safe.length <= 31 ? safe : safe.substring(0, 31);
  }
}
