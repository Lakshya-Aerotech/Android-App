import 'package:flutter/material.dart';
import '../../booking/models/booking_model.dart';

/// Specialized model for Operations Dashboard Statistics
class OperationsDashboardStats {
  final int pending;
  final int reviewed;
  final int pilotAssigned;
  final int completedToday;
  final int cancelled;
  final int todayBookings;

  OperationsDashboardStats({
    this.pending = 0,
    this.reviewed = 0,
    this.pilotAssigned = 0,
    this.completedToday = 0,
    this.cancelled = 0,
    this.todayBookings = 0,
  });
}

/// Model for Recent Activity logs
class OperationsActivity {
  final String bookingId;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  OperationsActivity({
    required this.bookingId,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

/// Alias for BookingModel when used in Operations context
typedef OperationsBookingModel = BookingModel;

/// Model for specific dashboard statistic cards
class DashboardStatisticModel {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  DashboardStatisticModel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
