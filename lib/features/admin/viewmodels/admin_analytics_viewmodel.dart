import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../shared/enums/booking_status.dart';
import '../../auth/models/user_model.dart';
import '../models/admin_analytics.dart';
import '../repositories/admin_analytics_repository.dart';

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>(
  (ref) => AdminAnalyticsRepositoryImpl(),
);

final adminAnalyticsViewModelProvider =
    StateNotifierProvider<
      AdminAnalyticsViewModel,
      AsyncValue<AdminAnalyticsData>
    >((ref) {
      return AdminAnalyticsViewModel(
        ref.watch(adminAnalyticsRepositoryProvider),
      );
    });

final analyticsFilterProvider = StateProvider<AnalyticsFilter>(
  (ref) => AnalyticsFilter.initial(),
);

class AdminAnalyticsViewModel
    extends StateNotifier<AsyncValue<AdminAnalyticsData>> {
  final AdminAnalyticsRepository _repository;
  AdminAnalyticsSource? _source;

  AdminAnalyticsViewModel(this._repository)
    : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh([AnalyticsFilter? filter]) async {
    state = const AsyncValue.loading();
    try {
      _source = await _repository.fetchAnalyticsSource();
      state = AsyncValue.data(buildData(filter ?? AnalyticsFilter.initial()));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyFilter(AnalyticsFilter filter) {
    final source = _source;
    if (source == null) {
      refresh(filter);
      return;
    }
    state = AsyncValue.data(_build(source, filter));
  }

  AdminAnalyticsData buildData(AnalyticsFilter filter) {
    final source = _source;
    if (source == null) return AdminAnalyticsData.empty;
    return _build(source, filter);
  }

  ReportPreviewData buildReport(AdminReportType type, AnalyticsFilter filter) {
    final data = buildData(filter);
    final definition = reportDefinitions.firstWhere((r) => r.type == type);
    final table = switch (type) {
      AdminReportType.complete => data.bookingTable,
      AdminReportType.bookings => data.bookingTable,
      AdminReportType.pesticideSpraying => data.bookingTable,
      AdminReportType.farmers => data.topFarmers,
      AdminReportType.pilots => data.pilotTable,
      AdminReportType.operations => AnalyticsTable(
        columns: ['Metric', 'Value'],
        rows: data.operationsMetrics.map((m) => [m.title, m.value]).toList(),
      ),
      AdminReportType.geographic => data.geographicTable,
      AdminReportType.revenue => AnalyticsTable(
        columns: ['Metric', 'Value'],
        rows: [
          ['Revenue data available', data.hasRevenueData ? 'Yes' : 'No'],
          [
            'Total Revenue',
            data.overview.firstWhere((m) => m.title == 'Total Revenue').value,
          ],
        ],
      ),
    };

    final summary = switch (type) {
      AdminReportType.bookings => data.bookingMetrics,
      AdminReportType.pesticideSpraying => data.pesticideMetrics,
      AdminReportType.farmers => data.farmerMetrics,
      AdminReportType.pilots => data.pilotMetrics,
      AdminReportType.operations => data.operationsMetrics,
      AdminReportType.geographic => data.geographicMetrics,
      AdminReportType.revenue => [
        data.overview.firstWhere((m) => m.title == 'Total Revenue'),
      ],
      AdminReportType.complete => data.overview,
    };

    return ReportPreviewData(
      definition: definition,
      filter: filter,
      summary: summary,
      table: table,
      generatedAt: DateTime.now(),
    );
  }

  AdminAnalyticsData _build(
    AdminAnalyticsSource source,
    AnalyticsFilter filter,
  ) {
    final users = source.users;
    final farms = source.farms.where(_isTeluguState).toList();
    final filteredBookings = source.bookings.where((b) {
      final createdAt = _date(b['createdAt']);
      if (createdAt == null ||
          createdAt.isBefore(filter.dateRange.start) ||
          createdAt.isAfter(filter.dateRange.end)) {
        return false;
      }
      if (!_isTeluguState(b)) return false;
      if (filter.state != AdminAnalyticsConstants.allStates &&
          _text(b['state']) != filter.state) {
        return false;
      }
      if (filter.district != AdminAnalyticsConstants.allDistricts &&
          _text(b['district']) != filter.district) {
        return false;
      }
      if (filter.status != null &&
          BookingStatus.fromString(_text(b['status'])) != filter.status) {
        return false;
      }
      return true;
    }).toList();

    final matchingFarms = farms.where((f) {
      if (filter.state != AdminAnalyticsConstants.allStates &&
          _text(f['state']) != filter.state) {
        return false;
      }
      if (filter.district != AdminAnalyticsConstants.allDistricts &&
          _text(f['district']) != filter.district) {
        return false;
      }
      return true;
    }).toList();

    final farmers = users.where((u) => _role(u) == UserRole.farmer).toList();
    final pilots = users.where((u) => _role(u) == UserRole.pilot).toList();
    final ops = users.where((u) => _role(u) == UserRole.operations).toList();
    final completed = filteredBookings.where(_isCompleted).toList();
    final active = filteredBookings.where(_isActiveJob).toList();
    final assigned = filteredBookings.where(_isAssigned).toList();
    final pending = filteredBookings.where(
      (b) => _status(b) == BookingStatus.pending,
    );
    final approved = filteredBookings.where(
      (b) => _status(b) == BookingStatus.reviewed,
    );
    final cancelled = filteredBookings.where(
      (b) => _status(b) == BookingStatus.cancelled,
    );
    final revenue = filteredBookings.fold<double>(
      0,
      (totalRevenue, b) =>
          totalRevenue + (_isCompleted(b) ? (_revenue(b) ?? 0) : 0),
    );
    final hasRevenue = filteredBookings.any((b) => _revenue(b) != null);
    final completedArea = completed.fold<double>(0, (s, b) => s + _area(b));
    final bookedArea = filteredBookings.fold<double>(0, (s, b) => s + _area(b));

    final overview = [
      _metric('Total Farmers', farmers.length, Icons.agriculture, Colors.blue),
      _metric('Total Pilots', pilots.length, Icons.flight, Colors.orange),
      _metric(
        'Total Operations Staff',
        ops.length,
        Icons.engineering,
        Colors.purple,
      ),
      _metric(
        'Total Bookings',
        filteredBookings.length,
        Icons.book_online,
        Colors.green,
      ),
      _metric(
        'Pending Bookings',
        pending.length,
        Icons.pending_actions,
        Colors.orange,
      ),
      _metric(
        'Approved Bookings',
        approved.length,
        Icons.verified_outlined,
        Colors.blue,
      ),
      _metric(
        'Assigned Jobs',
        assigned.length,
        Icons.assignment_ind_outlined,
        Colors.indigo,
      ),
      _metric('Active Jobs', active.length, Icons.track_changes, Colors.teal),
      _metric('Completed Jobs', completed.length, Icons.task_alt, Colors.green),
      _metric(
        'Cancelled Bookings',
        cancelled.length,
        Icons.cancel_outlined,
        Colors.red,
      ),
      _metric(
        'Available Pilots',
        pilots.where(_isAvailableUser).length,
        Icons.person_pin_circle_outlined,
        Colors.cyan,
      ),
      _metricValue(
        'Total Farm Area Serviced',
        _areaText(completedArea),
        Icons.crop_free,
        Colors.green,
      ),
      _metricValue(
        'Total Revenue',
        hasRevenue ? _currency(revenue) : '₹0',
        Icons.payments_outlined,
        Colors.amber,
      ),
    ];

    final statusCounts = <BookingStatus, int>{};
    for (final b in filteredBookings) {
      final status = _status(b);
      if (status == BookingStatus.accepted) continue;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final total = filteredBookings.length;
    final completionRate = total == 0 ? 0.0 : completed.length / total * 100;
    final cancellationRate = total == 0 ? 0.0 : cancelled.length / total * 100;

    final bookingTrend = _trend(filteredBookings, filter.dateRange);
    final bookingMetrics = [
      _metric('Total Bookings', total, Icons.book_online, Colors.green),
      _metric(
        'Completed Bookings',
        completed.length,
        Icons.task_alt,
        Colors.green,
      ),
      _metric('Active Jobs', active.length, Icons.track_changes, Colors.teal),
      _metric(
        'Pending Requests',
        pending.length,
        Icons.pending_actions,
        Colors.orange,
      ),
      _metric(
        'Approved Bookings',
        approved.length,
        Icons.verified_outlined,
        Colors.blue,
      ),
      _metric(
        'Cancelled Bookings',
        cancelled.length,
        Icons.cancel_outlined,
        Colors.red,
      ),
      _metricValue(
        'Completion Rate',
        _percent(completionRate),
        Icons.trending_up,
        Colors.green,
      ),
      _metricValue(
        'Cancellation Rate',
        _percent(cancellationRate),
        Icons.trending_down,
        Colors.red,
      ),
      _metricValue(
        'Average Bookings per Day',
        (total / max(1, _days(filter.dateRange))).toStringAsFixed(1),
        Icons.calendar_today,
        Colors.blue,
      ),
      _metricValue(
        'Busiest Booking Day',
        _busiestDay(filteredBookings),
        Icons.event_available,
        Colors.purple,
      ),
    ];

    final completedDurations = completed
        .map(
          (b) => _durationBetweenStatuses(
            b,
            BookingStatus.inProgress,
            BookingStatus.completed,
          ),
        )
        .whereType<Duration>()
        .toList();
    final pesticideMetrics = [
      _metric(
        'Total Pesticide Spraying Bookings',
        total,
        Icons.spa_outlined,
        Colors.green,
      ),
      _metric(
        'Completed Spraying Jobs',
        completed.length,
        Icons.task_alt,
        Colors.green,
      ),
      _metric(
        'Active Spraying Jobs',
        active.length,
        Icons.track_changes,
        Colors.teal,
      ),
      _metric(
        'Pending Spraying Requests',
        pending.length,
        Icons.pending_actions,
        Colors.orange,
      ),
      _metricValue(
        'Total Farm Area Booked',
        _areaText(bookedArea),
        Icons.crop_square,
        Colors.blue,
      ),
      _metricValue(
        'Total Farm Area Serviced',
        _areaText(completedArea),
        Icons.crop_free,
        Colors.green,
      ),
      _metricValue(
        'Average Area per Completed Job',
        _areaText(completed.isEmpty ? 0 : completedArea / completed.length),
        Icons.functions,
        Colors.indigo,
      ),
      _metricValue(
        'Largest Completed Farm Area',
        _areaText(
          completed.fold<double>(0, (largest, b) => max(largest, _area(b))),
        ),
        Icons.open_in_full,
        Colors.purple,
      ),
      _metricValue(
        'Average Spraying Duration',
        completedDurations.isEmpty
            ? 'Not available'
            : _durationText(_averageDuration(completedDurations)),
        Icons.timer_outlined,
        Colors.cyan,
      ),
      _metricValue(
        'Total Revenue from Completed Spraying Jobs',
        hasRevenue ? _currency(revenue) : '₹0',
        Icons.payments_outlined,
        Colors.amber,
      ),
    ];

    final farmerIds = filteredBookings
        .map((b) => _text(b['farmerUid']))
        .toSet();
    final completedFarmerIds = completed
        .map((b) => _text(b['farmerUid']))
        .toSet();
    final farmerBookingCounts = <String, int>{};
    for (final b in filteredBookings) {
      final id = _text(b['farmerUid']);
      if (id.isNotEmpty) {
        farmerBookingCounts[id] = (farmerBookingCounts[id] ?? 0) + 1;
      }
    }
    final newFarmers = farmers.where((f) {
      final created = _date(f['createdAt']);
      return created != null &&
          !created.isBefore(filter.dateRange.start) &&
          !created.isAfter(filter.dateRange.end);
    }).length;
    final farmerMetrics = [
      _metric(
        'Total Registered Farmers',
        farmers.length,
        Icons.agriculture,
        Colors.blue,
      ),
      _metric(
        'Active Farmers',
        farmerIds.length,
        Icons.person_pin,
        Colors.green,
      ),
      _metric('New Farmers', newFarmers, Icons.person_add_alt, Colors.teal),
      _metric(
        'Farmers With Bookings',
        farmerIds.length,
        Icons.receipt_long,
        Colors.indigo,
      ),
      _metric(
        'Farmers With Completed Bookings',
        completedFarmerIds.length,
        Icons.task_alt,
        Colors.green,
      ),
      _metric(
        'Farmers With No Bookings',
        max(0, farmers.length - farmerIds.length),
        Icons.person_off_outlined,
        Colors.orange,
      ),
      _metric(
        'Returning Farmers',
        farmerBookingCounts.values
            .where((bookingCount) => bookingCount > 1)
            .length,
        Icons.repeat,
        Colors.purple,
      ),
      _metric(
        'Total Registered Farms',
        matchingFarms.length,
        Icons.grass,
        Colors.green,
      ),
      _metricValue(
        'Total Booked Farm Area',
        _areaText(bookedArea),
        Icons.crop_square,
        Colors.blue,
      ),
      _metricValue(
        'Total Completed Farm Area',
        _areaText(completedArea),
        Icons.crop_free,
        Colors.green,
      ),
      _metricValue(
        'Average Bookings per Farmer',
        farmers.isEmpty ? '0' : (total / farmers.length).toStringAsFixed(1),
        Icons.functions,
        Colors.cyan,
      ),
    ];

    final pilotMetrics = _pilotMetrics(pilots, filteredBookings, completed);
    final geo = _geographic(filteredBookings);
    final operationsMetrics = _operationsMetrics(filteredBookings);

    // Coupon metrics calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final totalCoupons = source.coupons.length;
    
    int activeCouponsCount = 0;
    int inactiveCouponsCount = 0;
    int expiredCouponsCount = 0;
    
    for (final c in source.coupons) {
      final isActive = c['isActive'] as bool? ?? false;
      final Timestamp? validUntilTs = c['validUntil'] as Timestamp?;
      
      if (!isActive) {
        inactiveCouponsCount++;
      } else if (validUntilTs != null && validUntilTs.toDate().isBefore(today)) {
        expiredCouponsCount++;
      } else {
        activeCouponsCount++;
      }
    }
    
    final couponBookings = filteredBookings.where((b) => b['couponId'] != null).toList();
    final totalRedemptions = couponBookings.length;
    
    final double totalDiscount = couponBookings.fold<double>(
      0.0,
      (acc, b) => acc + ((b['discountAmount'] as num?)?.toDouble() ?? 0.0),
    );
    
    final Map<String, int> couponCounts = {};
    for (final b in couponBookings) {
      final code = (b['couponCode'] as String?) ?? '';
      if (code.isNotEmpty) {
        couponCounts[code] = (couponCounts[code] ?? 0) + 1;
      }
    }
    
    String mostUsedCoupon = 'None';
    int maxUses = 0;
    couponCounts.forEach((code, occurrences) {
      if (occurrences > maxUses) {
        maxUses = occurrences;
        mostUsedCoupon = code;
      }
    });
    if (mostUsedCoupon != 'None') {
      mostUsedCoupon = '$mostUsedCoupon ($maxUses)';
    }

    final couponMetrics = [
      _metric('Total Coupons', totalCoupons, Icons.local_offer, Colors.blue),
      _metric('Active Coupons', activeCouponsCount, Icons.check_circle, Colors.green),
      _metric('Inactive Coupons', inactiveCouponsCount, Icons.cancel, Colors.grey),
      _metric('Expired Coupons', expiredCouponsCount, Icons.timer_off, Colors.red),
      _metric('Total Redemptions', totalRedemptions, Icons.shopping_bag, Colors.orange),
      _metricValue('Most Used Coupon', mostUsedCoupon, Icons.star, Colors.purple),
      _metricValue('Total Discount', _currency(totalDiscount), Icons.card_giftcard, Colors.teal),
    ];

    return AdminAnalyticsData(
      overview: overview,
      bookingMetrics: bookingMetrics,
      pesticideMetrics: pesticideMetrics,
      farmerMetrics: farmerMetrics,
      pilotMetrics: pilotMetrics,
      geographicMetrics: geo.metrics,
      operationsMetrics: operationsMetrics,
      couponMetrics: couponMetrics,
      bookingTrend: bookingTrend,
      statusDistribution: statusCounts.entries
          .map((e) => ChartPoint(e.key.displayName, e.value.toDouble()))
          .toList(),
      stateDistribution: geo.states,
      districtDistribution: geo.districts,
      districts: _districtOptions(source, filter.state),
      topFarmers: _topFarmers(farmers, filteredBookings, completed, hasRevenue),
      pilotTable: _pilotTable(pilots, filteredBookings, completed),
      geographicTable: geo.table,
      bookingTable: _bookingTable(filteredBookings, hasRevenue),
      hasRevenueData: hasRevenue,
      missingFields: [
        if (!hasRevenue) 'No real payment/revenue field was found on bookings.',
        'Dedicated lifecycle timestamp fields were not found; timing uses statusHistory when available.',
        'Farm area unit is not stored on bookings; area totals use booking numeric area fields as-is.',
      ],
    );
  }

  List<AnalyticsMetric> _pilotMetrics(
    List<Map<String, dynamic>> pilots,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> completed,
  ) {
    final activeAssignments = bookings
        .where(_isActiveJob)
        .where((b) => _text(b['assignedPilotId']).isNotEmpty)
        .length;
    final assigned = bookings
        .where((b) => _text(b['assignedPilotId']).isNotEmpty)
        .length;
    final durations = completed
        .map(
          (b) => _durationBetweenStatuses(
            b,
            BookingStatus.pilotAssigned,
            BookingStatus.completed,
          ),
        )
        .whereType<Duration>()
        .toList();
    return [
      _metric('Total Pilots', pilots.length, Icons.flight, Colors.orange),
      _metric(
        'Active Pilots',
        pilots.where((p) => p['isActive'] != false).length,
        Icons.check_circle_outline,
        Colors.green,
      ),
      _metric(
        'Inactive Pilots',
        pilots.where((p) => p['isActive'] == false).length,
        Icons.block,
        Colors.red,
      ),
      _metric(
        'Available Pilots',
        pilots.where(_isAvailableUser).length,
        Icons.person_pin_circle_outlined,
        Colors.cyan,
      ),
      _metric(
        'Pilots Assigned To Active Jobs',
        activeAssignments,
        Icons.assignment_ind_outlined,
        Colors.indigo,
      ),
      _metric('Total Assigned Jobs', assigned, Icons.assignment, Colors.blue),
      _metric(
        'Total Active Assignments',
        activeAssignments,
        Icons.track_changes,
        Colors.teal,
      ),
      _metric(
        'Total Completed Jobs',
        completed.length,
        Icons.task_alt,
        Colors.green,
      ),
      _metricValue(
        'Total Farm Area Serviced',
        _areaText(completed.fold<double>(0, (s, b) => s + _area(b))),
        Icons.crop_free,
        Colors.green,
      ),
      _metricValue(
        'Average Job Completion Duration',
        durations.isEmpty
            ? 'Not available'
            : _durationText(_averageDuration(durations)),
        Icons.timer_outlined,
        Colors.purple,
      ),
    ];
  }

  _GeoData _geographic(List<Map<String, dynamic>> bookings) {
    final stateCounts = <String, int>{};
    final districtCounts = <String, int>{};
    final villageCounts = <String, int>{};
    for (final b in bookings) {
      final state = _text(b['state']).isEmpty ? 'Unknown' : _text(b['state']);
      final district = _text(b['district']).isEmpty
          ? 'Unknown'
          : _text(b['district']);
      final village = _text(b['village']).isEmpty
          ? 'Unknown'
          : _text(b['village']);
      stateCounts[state] = (stateCounts[state] ?? 0) + 1;
      districtCounts[district] = (districtCounts[district] ?? 0) + 1;
      villageCounts[village] = (villageCounts[village] ?? 0) + 1;
    }
    final completed = bookings.where(_isCompleted).toList();
    final active = bookings.where(_isActiveJob).toList();
    return _GeoData(
      metrics: [
        _metric(
          'States Covered',
          stateCounts.length,
          Icons.map_outlined,
          Colors.blue,
        ),
        _metric(
          'Districts Covered',
          districtCounts.length,
          Icons.location_city_outlined,
          Colors.indigo,
        ),
        _metricValue(
          'Most Active District',
          _topKey(districtCounts),
          Icons.place_outlined,
          Colors.green,
        ),
        _metricValue(
          'Most Active Village',
          _topKey(villageCounts),
          Icons.home_work_outlined,
          Colors.teal,
        ),
        _metric(
          'Completed Jobs By State',
          completed.length,
          Icons.task_alt,
          Colors.green,
        ),
        _metric(
          'Active Jobs By State',
          active.length,
          Icons.track_changes,
          Colors.teal,
        ),
      ],
      states: stateCounts.entries
          .map((e) => ChartPoint(e.key, e.value.toDouble()))
          .toList(),
      districts: districtCounts.entries
          .map((e) => ChartPoint(e.key, e.value.toDouble()))
          .toList(),
      table: AnalyticsTable(
        columns: [
          'Location',
          'Total bookings',
          'Completed',
          'Active',
          'Area serviced',
        ],
        rows: districtCounts.keys.map((district) {
          final districtBookings = bookings
              .where(
                (b) =>
                    (_text(b['district']).isEmpty
                        ? 'Unknown'
                        : _text(b['district'])) ==
                    district,
              )
              .toList();
          return [
            district,
            districtBookings.length.toString(),
            districtBookings.where(_isCompleted).length.toString(),
            districtBookings.where(_isActiveJob).length.toString(),
            _areaText(
              districtBookings
                  .where(_isCompleted)
                  .fold<double>(0, (s, b) => s + _area(b)),
            ),
          ];
        }).toList(),
      ),
    );
  }

  List<AnalyticsMetric> _operationsMetrics(
    List<Map<String, dynamic>> bookings,
  ) {
    final review = _averageStatusGap(
      bookings,
      BookingStatus.pending,
      BookingStatus.reviewed,
    );
    final assignment = _averageStatusGap(
      bookings,
      BookingStatus.reviewed,
      BookingStatus.pilotAssigned,
    );
    final travel = _averageStatusGap(
      bookings,
      BookingStatus.enRoute,
      BookingStatus.arrived,
    );
    final spraying = _averageStatusGap(
      bookings,
      BookingStatus.inProgress,
      BookingStatus.completed,
    );
    final total = bookings
        .where(_isCompleted)
        .map(
          (b) => _date(b['createdAt']) == null
              ? null
              : _date(b['updatedAt'])?.difference(_date(b['createdAt'])!),
        )
        .whereType<Duration>()
        .toList();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return [
      _metricValue(
        'Average Booking Review Time',
        review == null ? 'Not available' : _durationText(review),
        Icons.rate_review_outlined,
        Colors.blue,
      ),
      _metricValue(
        'Average Booking Approval Time',
        review == null ? 'Not available' : _durationText(review),
        Icons.verified_outlined,
        Colors.green,
      ),
      _metricValue(
        'Average Approval-to-Pilot-Assignment Time',
        assignment == null ? 'Not available' : _durationText(assignment),
        Icons.assignment_ind_outlined,
        Colors.indigo,
      ),
      _metricValue(
        'Average Assignment-to-Travelling Time',
        _averageStatusGap(
                  bookings,
                  BookingStatus.pilotAssigned,
                  BookingStatus.enRoute,
                ) ==
                null
            ? 'Not available'
            : _durationText(
                _averageStatusGap(
                  bookings,
                  BookingStatus.pilotAssigned,
                  BookingStatus.enRoute,
                )!,
              ),
        Icons.route_outlined,
        Colors.cyan,
      ),
      _metricValue(
        'Average Travel Duration',
        travel == null ? 'Not available' : _durationText(travel),
        Icons.local_shipping_outlined,
        Colors.teal,
      ),
      _metricValue(
        'Average Pesticide Spraying Duration',
        spraying == null ? 'Not available' : _durationText(spraying),
        Icons.timer_outlined,
        Colors.orange,
      ),
      _metricValue(
        'Average Total Booking Completion Duration',
        total.isEmpty
            ? 'Not available'
            : _durationText(_averageDuration(total)),
        Icons.av_timer,
        Colors.purple,
      ),
      _metric(
        'Approved Bookings Awaiting Assignment',
        bookings
            .where(
              (b) =>
                  _status(b) == BookingStatus.reviewed &&
                  _text(b['assignedPilotId']).isEmpty,
            )
            .length,
        Icons.pending_actions,
        Colors.orange,
      ),
      _metric(
        'Active Jobs',
        bookings.where(_isActiveJob).length,
        Icons.track_changes,
        Colors.teal,
      ),
      _metric(
        'Jobs Completed Today',
        bookings
            .where(
              (b) =>
                  _isCompleted(b) &&
                  (_date(b['updatedAt'])?.isAfter(start) ?? false),
            )
            .length,
        Icons.today,
        Colors.green,
      ),
    ];
  }

  AnalyticsTable _topFarmers(
    List<Map<String, dynamic>> farmers,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> completed,
    bool hasRevenue,
  ) {
    final rows =
        farmers
            .map((farmer) {
              final uid = _text(farmer['uid']).isNotEmpty
                  ? _text(farmer['uid'])
                  : _text(farmer['_docId']);
              final farmerBookings = bookings
                  .where((b) => _text(b['farmerUid']) == uid)
                  .toList();
              final completedBookings = completed
                  .where((b) => _text(b['farmerUid']) == uid)
                  .toList();
              return [
                _text(farmer['name']).isEmpty
                    ? 'Farmer'
                    : _text(farmer['name']),
                _text(farmer['district']),
                _text(farmer['state']),
                farmerBookings.length.toString(),
                completedBookings.length.toString(),
                _areaText(
                  completedBookings.fold<double>(0, (s, b) => s + _area(b)),
                ),
                if (hasRevenue)
                  _currency(
                    completedBookings.fold<double>(
                      0,
                      (s, b) => s + (_revenue(b) ?? 0),
                    ),
                  ),
              ];
            })
            .where((row) => row[3] != '0')
            .toList()
          ..sort((a, b) => int.parse(b[3]).compareTo(int.parse(a[3])));
    return AnalyticsTable(
      columns: [
        'Farmer',
        'District',
        'State',
        'Bookings',
        'Completed',
        'Area serviced',
        if (hasRevenue) 'Amount spent',
      ],
      rows: rows.take(10).toList(),
    );
  }

  AnalyticsTable _pilotTable(
    List<Map<String, dynamic>> pilots,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> completed,
  ) {
    return AnalyticsTable(
      columns: [
        'Pilot',
        'Status',
        'Assigned',
        'Active',
        'Completed',
        'Completion rate',
        'Area serviced',
        'Rating',
      ],
      rows: pilots.map((pilot) {
        final uid = _text(pilot['uid']).isNotEmpty
            ? _text(pilot['uid'])
            : _text(pilot['_docId']);
        final assigned = bookings
            .where((b) => _text(b['assignedPilotId']) == uid)
            .toList();
        final done = completed
            .where((b) => _text(b['assignedPilotId']) == uid)
            .toList();
        final ratings = done
            .map((b) => (b['rating'] as num?)?.toDouble())
            .whereType<double>()
            .toList();
        return [
          _text(pilot['name']).isEmpty ? 'Pilot' : _text(pilot['name']),
          _isAvailableUser(pilot)
              ? 'Available'
              : (pilot['isActive'] == false ? 'Inactive' : 'Assigned'),
          assigned.length.toString(),
          assigned.where(_isActiveJob).length.toString(),
          done.length.toString(),
          _percent(assigned.isEmpty ? 0 : done.length / assigned.length * 100),
          _areaText(done.fold<double>(0, (s, b) => s + _area(b))),
          ratings.isEmpty
              ? 'Not available'
              : (ratings.reduce((a, b) => a + b) / ratings.length)
                    .toStringAsFixed(1),
        ];
      }).toList(),
    );
  }

  AnalyticsTable _bookingTable(
    List<Map<String, dynamic>> bookings,
    bool hasRevenue,
  ) {
    return AnalyticsTable(
      columns: [
        'Booking ID',
        'Farmer',
        'Farm',
        'District',
        'State',
        'Status',
        'Area',
        'Created',
        if (hasRevenue) 'Revenue',
      ],
      rows: bookings
          .map(
            (b) => [
              _text(b['bookingId']).isEmpty
                  ? _text(b['_docId'])
                  : _text(b['bookingId']),
              _text(b['farmerName']).isEmpty
                  ? 'Farmer'
                  : _text(b['farmerName']),
              _text(b['farmName']),
              _text(b['district']),
              _text(b['state']),
              _status(b).displayName,
              _areaText(_area(b)),
              _date(b['createdAt']) == null
                  ? 'Not available'
                  : DateFormat('d MMM yyyy').format(_date(b['createdAt'])!),
              if (hasRevenue)
                _revenue(b) == null ? 'Not available' : _currency(_revenue(b)!),
            ],
          )
          .toList(),
    );
  }

  List<ChartPoint> _trend(
    List<Map<String, dynamic>> bookings,
    AnalyticsDateRange range,
  ) {
    final labels = <String, int>{};
    final formatter = range.preset == AnalyticsDateRangePreset.today
        ? DateFormat('ha')
        : DateFormat('d MMM');
    for (final b in bookings) {
      final date = _date(b['createdAt']);
      if (date == null) continue;
      final label = formatter.format(date);
      labels[label] = (labels[label] ?? 0) + 1;
    }
    return labels.entries
        .map((e) => ChartPoint(e.key, e.value.toDouble()))
        .toList();
  }

  List<String> _districtOptions(AdminAnalyticsSource source, String state) {
    final districts = <String>{};
    for (final doc in [...source.bookings, ...source.farms]) {
      if (!_isTeluguState(doc)) continue;
      if (state != AdminAnalyticsConstants.allStates &&
          _text(doc['state']) != state) {
        continue;
      }
      final district = _text(doc['district']);
      if (district.isNotEmpty) districts.add(district);
    }
    final sorted = districts.toList()..sort();
    return [AdminAnalyticsConstants.allDistricts, ...sorted];
  }

  static final reportDefinitions = [
    const ReportDefinition(
      type: AdminReportType.complete,
      title: 'Complete Platform Report',
      description:
          'Executive overview across bookings, farmers, pilots, operations, geography, and revenue.',
      icon: Icons.dashboard_customize_outlined,
    ),
    const ReportDefinition(
      type: AdminReportType.bookings,
      title: 'Booking Report',
      description:
          'Booking trend, status distribution, and filtered booking records.',
      icon: Icons.book_online,
    ),
    const ReportDefinition(
      type: AdminReportType.pesticideSpraying,
      title: 'Pesticide Spraying Performance Report',
      description: 'Dedicated performance metrics for pesticide spraying jobs.',
      icon: Icons.spa_outlined,
    ),
    const ReportDefinition(
      type: AdminReportType.farmers,
      title: 'Farmer Report',
      description:
          'Farmer activity, farms, returning farmers, and top farmer records.',
      icon: Icons.agriculture,
    ),
    const ReportDefinition(
      type: AdminReportType.pilots,
      title: 'Pilot Performance Report',
      description: 'Assigned, active, and completed job performance by pilot.',
      icon: Icons.flight,
    ),
    const ReportDefinition(
      type: AdminReportType.operations,
      title: 'Operational Performance Report',
      description: 'Workflow duration metrics and assignment pipeline status.',
      icon: Icons.engineering,
    ),
    const ReportDefinition(
      type: AdminReportType.geographic,
      title: 'Geographic Performance Report',
      description:
          'State, district, and village performance for Telugu states.',
      icon: Icons.map_outlined,
    ),
    const ReportDefinition(
      type: AdminReportType.revenue,
      title: 'Revenue Report',
      description:
          'Revenue metrics when real payment fields exist on completed bookings.',
      icon: Icons.payments_outlined,
    ),
  ];

  static BookingStatus _status(Map<String, dynamic> b) =>
      BookingStatus.fromString(_text(b['status']));
  static bool _isCompleted(Map<String, dynamic> b) =>
      _status(b) == BookingStatus.completed ||
      _status(b) == BookingStatus.farmerConfirmed ||
      _status(b) == BookingStatus.closed;
  static bool _isAssigned(Map<String, dynamic> b) =>
      _status(b) == BookingStatus.pilotAssigned ||
      _text(b['assignedPilotId']).isNotEmpty;
  static bool _isActiveJob(Map<String, dynamic> b) => {
    BookingStatus.pilotAssigned,
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.inProgress,
  }.contains(_status(b));
  static bool _isTeluguState(Map<String, dynamic> doc) =>
      AdminAnalyticsConstants.teluguStates.contains(_text(doc['state']));
  static UserRole? _role(Map<String, dynamic> user) {
    try {
      return UserRole.values.byName(_text(user['role']));
    } catch (_) {
      return null;
    }
  }

  static bool _isAvailableUser(Map<String, dynamic> user) {
    final availability = _text(user['availability']).toLowerCase();
    return user['isActive'] != false &&
        user['isAvailable'] != false &&
        user['isAvailableForJobs'] != false &&
        availability != 'unavailable' &&
        availability != 'assigned';
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _area(Map<String, dynamic> b) {
    return (b['actualAreaCovered'] as num?)?.toDouble() ??
        (b['estimatedArea'] as num?)?.toDouble() ??
        (b['farmArea'] as num?)?.toDouble() ??
        (b['area'] as num?)?.toDouble() ??
        0;
  }

  static double? _revenue(Map<String, dynamic> b) {
    for (final key in [
      'paymentAmount',
      'finalAmount',
      'bookingCharge',
      'serviceCost',
      'totalAmount',
      'amountPaid',
      'revenue',
    ]) {
      final value = b[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }

  static AnalyticsMetric _metric(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return _metricValue(title, value.toString(), icon, color);
  }

  static AnalyticsMetric _metricValue(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnalyticsMetric(
      title: title,
      value: value,
      icon: icon,
      color: color,
    );
  }

  static String _currency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  static String _percent(double value) =>
      '${value.isFinite ? value.toStringAsFixed(1) : '0.0'}%';
  static String _areaText(double value) =>
      '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} acres';
  static int _days(AnalyticsDateRange range) =>
      range.end.difference(range.start).inDays + 1;
  static String _busiestDay(List<Map<String, dynamic>> bookings) {
    final counts = <String, int>{};
    for (final b in bookings) {
      final date = _date(b['createdAt']);
      if (date == null) continue;
      final label = DateFormat('EEE, d MMM').format(date);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return _topKey(counts);
  }

  static String _topKey(Map<String, int> values) {
    if (values.isEmpty) return 'Not available';
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static Duration _averageDuration(List<Duration> durations) {
    final total = durations.fold<int>(0, (minutes, d) => minutes + d.inMinutes);
    return Duration(minutes: (total / durations.length).round());
  }

  static String _durationText(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${max(0, d.inMinutes)}m';
  }

  static Duration? _averageStatusGap(
    List<Map<String, dynamic>> bookings,
    BookingStatus from,
    BookingStatus to,
  ) {
    final durations = bookings
        .map((b) => _durationBetweenStatuses(b, from, to))
        .whereType<Duration>()
        .toList();
    return durations.isEmpty ? null : _averageDuration(durations);
  }

  static Duration? _durationBetweenStatuses(
    Map<String, dynamic> b,
    BookingStatus from,
    BookingStatus to,
  ) {
    final fromDate = _statusDate(b, from);
    final toDate = _statusDate(b, to);
    if (fromDate == null || toDate == null || toDate.isBefore(fromDate)) {
      return null;
    }
    return toDate.difference(fromDate);
  }

  static DateTime? _statusDate(Map<String, dynamic> b, BookingStatus status) {
    final history = b['statusHistory'];
    if (history is! List) return null;
    for (final item in history) {
      if (item is! Map) continue;
      if (BookingStatus.fromString(_text(item['status'])) == status) {
        return _date(item['timestamp']);
      }
    }
    return null;
  }
}

class _GeoData {
  final List<AnalyticsMetric> metrics;
  final List<ChartPoint> states;
  final List<ChartPoint> districts;
  final AnalyticsTable table;

  const _GeoData({
    required this.metrics,
    required this.states,
    required this.districts,
    required this.table,
  });
}
