import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/enums/booking_status.dart';

enum AnalyticsDateRangePreset {
  today,
  last7Days,
  last30Days,
  thisMonth,
  last3Months,
  thisYear,
  custom,
}

enum AdminReportType {
  complete,
  bookings,
  pesticideSpraying,
  farmers,
  pilots,
  drones,
  operations,
  geographic,
  revenue,
}

class AnalyticsDateRange {
  final DateTime start;
  final DateTime end;
  final AnalyticsDateRangePreset preset;

  const AnalyticsDateRange({
    required this.start,
    required this.end,
    required this.preset,
  });

  factory AnalyticsDateRange.fromPreset(
    AnalyticsDateRangePreset preset, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    switch (preset) {
      case AnalyticsDateRangePreset.today:
        return AnalyticsDateRange(start: dayStart, end: dayEnd, preset: preset);
      case AnalyticsDateRangePreset.last7Days:
        return AnalyticsDateRange(
          start: dayStart.subtract(const Duration(days: 6)),
          end: dayEnd,
          preset: preset,
        );
      case AnalyticsDateRangePreset.last30Days:
        return AnalyticsDateRange(
          start: dayStart.subtract(const Duration(days: 29)),
          end: dayEnd,
          preset: preset,
        );
      case AnalyticsDateRangePreset.thisMonth:
        return AnalyticsDateRange(
          start: DateTime(today.year, today.month),
          end: dayEnd,
          preset: preset,
        );
      case AnalyticsDateRangePreset.last3Months:
        return AnalyticsDateRange(
          start: DateTime(today.year, today.month - 2),
          end: dayEnd,
          preset: preset,
        );
      case AnalyticsDateRangePreset.thisYear:
        return AnalyticsDateRange(
          start: DateTime(today.year),
          end: dayEnd,
          preset: preset,
        );
      case AnalyticsDateRangePreset.custom:
        return AnalyticsDateRange(start: dayStart, end: dayEnd, preset: preset);
    }
  }

  AnalyticsDateRange copyWith({
    DateTime? start,
    DateTime? end,
    AnalyticsDateRangePreset? preset,
  }) {
    return AnalyticsDateRange(
      start: start ?? this.start,
      end: end ?? this.end,
      preset: preset ?? this.preset,
    );
  }

  String get label {
    final formatter = DateFormat('d MMM yyyy');
    if (_sameDay(start, end)) return formatter.format(start);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class AnalyticsFilter {
  final AnalyticsDateRange dateRange;
  final String state;
  final String district;
  final BookingStatus? status;

  const AnalyticsFilter({
    required this.dateRange,
    this.state = AdminAnalyticsConstants.allStates,
    this.district = AdminAnalyticsConstants.allDistricts,
    this.status,
  });

  factory AnalyticsFilter.initial() {
    return AnalyticsFilter(
      dateRange: AnalyticsDateRange.fromPreset(
        AnalyticsDateRangePreset.last30Days,
      ),
    );
  }

  AnalyticsFilter copyWith({
    AnalyticsDateRange? dateRange,
    String? state,
    String? district,
    BookingStatus? status,
    bool clearStatus = false,
  }) {
    return AnalyticsFilter(
      dateRange: dateRange ?? this.dateRange,
      state: state ?? this.state,
      district: district ?? this.district,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}

class AdminAnalyticsConstants {
  AdminAnalyticsConstants._();

  static const allStates = 'All Telugu States';
  static const allDistricts = 'All Districts';
  static const teluguStates = ['Telangana', 'Andhra Pradesh'];
  static const pesticideService = 'Pesticide Spraying';
}

class AnalyticsMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AnalyticsMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint(this.label, this.value);
}

class AnalyticsTable {
  final List<String> columns;
  final List<List<String>> rows;

  const AnalyticsTable({required this.columns, required this.rows});
}

class ReportDefinition {
  final AdminReportType type;
  final String title;
  final String description;
  final IconData icon;

  const ReportDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class ReportPreviewData {
  final ReportDefinition definition;
  final AnalyticsFilter filter;
  final List<AnalyticsMetric> summary;
  final AnalyticsTable table;
  final DateTime generatedAt;

  const ReportPreviewData({
    required this.definition,
    required this.filter,
    required this.summary,
    required this.table,
    required this.generatedAt,
  });
}

class AdminAnalyticsData {
  final List<AnalyticsMetric> overview;
  final List<AnalyticsMetric> bookingMetrics;
  final List<AnalyticsMetric> pesticideMetrics;
  final List<AnalyticsMetric> farmerMetrics;
  final List<AnalyticsMetric> pilotMetrics;
  final List<AnalyticsMetric> droneMetrics;
  final List<AnalyticsMetric> geographicMetrics;
  final List<AnalyticsMetric> operationsMetrics;
  final List<AnalyticsMetric> couponMetrics;
  final List<ChartPoint> bookingTrend;
  final List<ChartPoint> statusDistribution;
  final List<ChartPoint> stateDistribution;
  final List<ChartPoint> districtDistribution;
  final List<String> districts;
  final AnalyticsTable topFarmers;
  final AnalyticsTable pilotTable;
  final AnalyticsTable droneTable;
  final AnalyticsTable geographicTable;
  final AnalyticsTable bookingTable;
  final bool hasRevenueData;
  final List<String> missingFields;

  const AdminAnalyticsData({
    required this.overview,
    required this.bookingMetrics,
    required this.pesticideMetrics,
    required this.farmerMetrics,
    required this.pilotMetrics,
    required this.droneMetrics,
    required this.geographicMetrics,
    required this.operationsMetrics,
    required this.couponMetrics,
    required this.bookingTrend,
    required this.statusDistribution,
    required this.stateDistribution,
    required this.districtDistribution,
    required this.districts,
    required this.topFarmers,
    required this.pilotTable,
    required this.droneTable,
    required this.geographicTable,
    required this.bookingTable,
    required this.hasRevenueData,
    required this.missingFields,
  });

  static const empty = AdminAnalyticsData(
    overview: [],
    bookingMetrics: [],
    pesticideMetrics: [],
    farmerMetrics: [],
    pilotMetrics: [],
    droneMetrics: [],
    geographicMetrics: [],
    operationsMetrics: [],
    couponMetrics: [],
    bookingTrend: [],
    statusDistribution: [],
    stateDistribution: [],
    districtDistribution: [],
    districts: [],
    topFarmers: AnalyticsTable(columns: [], rows: []),
    pilotTable: AnalyticsTable(columns: [], rows: []),
    droneTable: AnalyticsTable(columns: [], rows: []),
    geographicTable: AnalyticsTable(columns: [], rows: []),
    bookingTable: AnalyticsTable(columns: [], rows: []),
    hasRevenueData: false,
    missingFields: [],
  );
}
