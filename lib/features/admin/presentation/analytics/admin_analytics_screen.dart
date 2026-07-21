import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/admin_analytics.dart';
import '../../presentation/reports/admin_report_preview_screen.dart';
import '../../presentation/widgets/analytics_widgets.dart';
import '../../services/admin_excel_report_service.dart';
import '../../viewmodels/admin_analytics_viewmodel.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(adminAnalyticsViewModelProvider);
    final filter = ref.watch(analyticsFilterProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Analytics & Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref
                .read(adminAnalyticsViewModelProvider.notifier)
                .refresh(filter),
          ),
          data: (data) => TabBarView(
            children: [
              _AnalyticsTab(data: data),
              _ReportsTab(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  final AdminAnalyticsData data;

  const _AnalyticsTab({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);

    void apply(AnalyticsFilter next) {
      ref.read(analyticsFilterProvider.notifier).state = next;
      ref.read(adminAnalyticsViewModelProvider.notifier).applyFilter(next);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminAnalyticsViewModelProvider.notifier).refresh(filter),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsFilterBar(filter: filter, data: data, onChanged: apply),
            AppSpacing.verticalLg,
            AnalyticsSection(
              title: 'Overall Platform Summary',
              metrics: data.overview,
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Booking Analytics',
              metrics: data.bookingMetrics,
              children: [
                AnalyticsChartCard(
                  title: 'Booking Trend',
                  points: data.bookingTrend,
                ),
                AnalyticsChartCard(
                  title: 'Booking Status Distribution',
                  points: data.statusDistribution,
                ),
              ],
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Pesticide Spraying Performance',
              metrics: data.pesticideMetrics,
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Farmer Analytics',
              metrics: data.farmerMetrics,
              children: [
                AnalyticsDataTableCard(
                  title: 'Top Farmers',
                  table: data.topFarmers,
                ),
              ],
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Pilot Performance',
              metrics: data.pilotMetrics,
              children: [
                AnalyticsDataTableCard(
                  title: 'Pilot Performance Table',
                  table: data.pilotTable,
                ),
              ],
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Drone Fleet Analytics',
              metrics: data.droneMetrics,
              children: [
                AnalyticsDataTableCard(
                  title: 'Drone Fleet Table',
                  table: data.droneTable,
                ),
              ],
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Geographic Analytics',
              metrics: data.geographicMetrics,
              children: [
                AnalyticsChartCard(
                  title: 'Bookings by State',
                  points: data.stateDistribution,
                ),
                AnalyticsChartCard(
                  title: 'Bookings by District',
                  points: data.districtDistribution,
                ),
                AnalyticsDataTableCard(
                  title: 'District Performance',
                  table: data.geographicTable,
                ),
              ],
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Operational Performance',
              metrics: data.operationsMetrics,
            ),
            AppSpacing.verticalXl,
            AnalyticsSection(
              title: 'Coupon Analytics',
              metrics: data.couponMetrics,
            ),
            if (data.missingFields.isNotEmpty) ...[
              AppSpacing.verticalXl,
              Text('Unavailable Metrics', style: AppTextStyles.titleMedium),
              AppSpacing.verticalSm,
              ...data.missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $field', style: AppTextStyles.bodySmall),
                ),
              ),
            ],
            AppSpacing.verticalXxl,
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final AdminAnalyticsData data;

  const _ReportsTab({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final vm = ref.read(adminAnalyticsViewModelProvider.notifier);

    Future<void> download(AdminReportType type) async {
      final messenger = ScaffoldMessenger.of(context);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final preview = vm.buildReport(type, filter);
        final path = await AdminExcelReportService().generate(preview, data);
        if (context.mounted) Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Excel report generated: $path')),
        );
      } catch (e) {
        if (context.mounted) Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Report generation failed: $e')),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        children: [
          AnalyticsFilterBar(
            filter: filter,
            data: data,
            onChanged: (next) {
              ref.read(analyticsFilterProvider.notifier).state = next;
              ref
                  .read(adminAnalyticsViewModelProvider.notifier)
                  .applyFilter(next);
            },
          ),
          AppSpacing.verticalLg,
          ...AdminAnalyticsViewModel.reportDefinitions.map(
            (definition) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReportTypeCard(
                definition: definition,
                filter: filter,
                onPreview: () {
                  final preview = vm.buildReport(definition.type, filter);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminReportPreviewScreen(
                        preview: preview,
                        analyticsData: data,
                      ),
                    ),
                  );
                },
                onDownload: () => download(definition.type),
              ),
            ),
          ),
          AppSpacing.verticalXxl,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            AppSpacing.verticalMd,
            Text('Unable to load analytics.', style: AppTextStyles.titleMedium),
            AppSpacing.verticalSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            AppSpacing.verticalMd,
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
