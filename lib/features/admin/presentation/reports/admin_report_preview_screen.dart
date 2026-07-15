import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/admin_analytics.dart';
import '../../presentation/widgets/analytics_widgets.dart';
import '../../services/admin_excel_report_service.dart';

class AdminReportPreviewScreen extends StatefulWidget {
  final ReportPreviewData preview;
  final AdminAnalyticsData analyticsData;

  const AdminReportPreviewScreen({
    super.key,
    required this.preview,
    required this.analyticsData,
  });

  @override
  State<AdminReportPreviewScreen> createState() =>
      _AdminReportPreviewScreenState();
}

class _AdminReportPreviewScreenState extends State<AdminReportPreviewScreen> {
  bool _isExporting = false;

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);
    try {
      final path = await AdminExcelReportService().generate(
        widget.preview,
        widget.analyticsData,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Excel report generated: $path')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Report generation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Report Preview'),
        actions: [
          IconButton(
            tooltip: 'Download Excel',
            onPressed: _isExporting ? null : _download,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportSummarySection(preview: widget.preview),
                AppSpacing.verticalLg,
                AnalyticsDataTableCard(
                  title:
                      'Report Table (${widget.preview.table.rows.length} records)',
                  table: widget.preview.table,
                ),
                AppSpacing.verticalXxl,
              ],
            ),
          ),
          if (_isExporting)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _download,
            icon: const Icon(Icons.download_outlined),
            label: Text(
              _isExporting ? 'Generating...' : 'Download Excel',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
