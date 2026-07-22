import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/enums/booking_status.dart';
import '../../models/admin_analytics.dart';

class AnalyticsSummaryGrid extends StatelessWidget {
  final List<AnalyticsMetric> metrics;

  const AnalyticsSummaryGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const AnalyticsEmptyState();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width / 164,
          ),
          itemBuilder: (context, index) =>
              AnalyticsSummaryCard(metric: metrics[index]),
        );
      },
    );
  }
}

class AnalyticsSummaryCard extends StatelessWidget {
  final AnalyticsMetric metric;

  const AnalyticsSummaryCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 22),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class AnalyticsFilterBar extends StatelessWidget {
  final AnalyticsFilter filter;
  final AdminAnalyticsData data;
  final ValueChanged<AnalyticsFilter> onChanged;

  const AnalyticsFilterBar({
    super.key,
    required this.filter,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Dropdown<AnalyticsDateRangePreset>(
            label: 'Date range',
            value: filter.dateRange.preset,
            items: AnalyticsDateRangePreset.values,
            text: _datePresetText,
            onChanged: (preset) async {
              if (preset == AnalyticsDateRangePreset.custom) {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(
                    start: filter.dateRange.start,
                    end: filter.dateRange.end,
                  ),
                );
                if (picked == null || picked.start.isAfter(picked.end)) {
                  return;
                }
                onChanged(
                  filter.copyWith(
                    dateRange: AnalyticsDateRange(
                      start: DateTime(
                        picked.start.year,
                        picked.start.month,
                        picked.start.day,
                      ),
                      end: DateTime(
                        picked.end.year,
                        picked.end.month,
                        picked.end.day,
                        23,
                        59,
                        59,
                      ),
                      preset: preset,
                    ),
                  ),
                );
                return;
              }
              onChanged(
                filter.copyWith(
                  dateRange: AnalyticsDateRange.fromPreset(preset),
                ),
              );
            },
          ),
          _Dropdown<String>(
            label: 'State',
            value: filter.state,
            items: const [
              AdminAnalyticsConstants.allStates,
              ...AdminAnalyticsConstants.teluguStates,
            ],
            text: (value) => value,
            onChanged: (state) => onChanged(
              filter.copyWith(
                state: state,
                district: AdminAnalyticsConstants.allDistricts,
              ),
            ),
          ),
          _Dropdown<String>(
            label: 'District',
            value: data.districts.contains(filter.district)
                ? filter.district
                : AdminAnalyticsConstants.allDistricts,
            items: data.districts.isEmpty
                ? const [AdminAnalyticsConstants.allDistricts]
                : data.districts,
            text: (value) => value,
            onChanged: (district) =>
                onChanged(filter.copyWith(district: district)),
          ),
          _Dropdown<BookingStatus?>(
            label: 'Status',
            value: filter.status,
            items: const [
              null,
              BookingStatus.pending,
              BookingStatus.reviewed,
              BookingStatus.pilotAssigned,
              BookingStatus.enRoute,
              BookingStatus.arrived,
              BookingStatus.inProgress,
              BookingStatus.completed,
              BookingStatus.farmerConfirmed,
              BookingStatus.closed,
              BookingStatus.issueReported,
              BookingStatus.cancelled,
            ],
            text: (value) => value?.displayName ?? 'All',
            onChanged: (status) => onChanged(
              filter.copyWith(status: status, clearStatus: status == null),
            ),
          ),
        ],
      ),
    );
  }

  String _datePresetText(AnalyticsDateRangePreset preset) {
    switch (preset) {
      case AnalyticsDateRangePreset.today:
        return 'Today';
      case AnalyticsDateRangePreset.last7Days:
        return 'Last 7 Days';
      case AnalyticsDateRangePreset.last30Days:
        return 'Last 30 Days';
      case AnalyticsDateRangePreset.thisMonth:
        return 'This Month';
      case AnalyticsDateRangePreset.last3Months:
        return 'Last 3 Months';
      case AnalyticsDateRangePreset.thisYear:
        return 'This Year';
      case AnalyticsDateRangePreset.custom:
        return 'Custom Date Range';
    }
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 520 ? double.infinity : 210,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodySmall,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(text(item), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null || items.contains(null)) onChanged(value as T);
        },
      ),
    );
  }
}

class AnalyticsChartCard extends StatelessWidget {
  final String title;
  final List<ChartPoint> points;

  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (max, p) => p.value > max ? p.value : max,
    );
    return _SectionCard(
      title: title,
      child: points.isEmpty
          ? const AnalyticsEmptyState(message: 'No chart data available.')
          : Column(
              children: points.take(12).map((point) {
                final fraction = maxValue == 0 ? 0.0 : point.value / maxValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: fraction,
                            backgroundColor: AppColors.border,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(
                          point.value.toInt().toString(),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class AnalyticsDataTableCard extends StatelessWidget {
  final String title;
  final AnalyticsTable table;

  const AnalyticsDataTableCard({
    super.key,
    required this.title,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: table.rows.isEmpty
          ? const AnalyticsEmptyState(message: 'No records available.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: AppTextStyles.bodySmall,
                columns: table.columns
                    .map((column) => DataColumn(label: Text(column)))
                    .toList(),
                rows: table.rows
                    .map(
                      (row) => DataRow(
                        cells: row.map((cell) => DataCell(Text(cell))).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

class ReportTypeCard extends StatelessWidget {
  final ReportDefinition definition;
  final AnalyticsFilter filter;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const ReportTypeCard({
    super.key,
    required this.definition,
    required this.filter,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(definition.icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(definition.title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${filter.dateRange.label} • ${filter.state} • ${filter.district} • ${filter.status?.displayName ?? 'All'}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportSummarySection extends StatelessWidget {
  final ReportPreviewData preview;

  const ReportSummarySection({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Report Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lakshya Smartguard systems', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(preview.definition.title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          Text(
            'Date range: ${preview.filter.dateRange.label}',
            style: AppTextStyles.bodySmall,
          ),
          Text(
            'State: ${preview.filter.state}',
            style: AppTextStyles.bodySmall,
          ),
          Text(
            'District: ${preview.filter.district}',
            style: AppTextStyles.bodySmall,
          ),
          Text(
            'Booking status: ${preview.filter.status?.displayName ?? 'All'}',
            style: AppTextStyles.bodySmall,
          ),
          Text(
            'Generated: ${DateFormat('d MMM yyyy, h:mm a').format(preview.generatedAt)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          AnalyticsSummaryGrid(metrics: preview.summary.take(8).toList()),
        ],
      ),
    );
  }
}

class AnalyticsEmptyState extends StatelessWidget {
  final String message;

  const AnalyticsEmptyState({
    super.key,
    this.message = 'No analytics data available.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class AnalyticsSection extends StatelessWidget {
  final String title;
  final List<AnalyticsMetric> metrics;
  final List<Widget> children;

  const AnalyticsSection({
    super.key,
    required this.title,
    required this.metrics,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalMd,
        AnalyticsSummaryGrid(metrics: metrics),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(top: 16), child: child),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
