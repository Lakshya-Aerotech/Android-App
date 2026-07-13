import 'package:flutter/material.dart';

class OperationsStatistic {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const OperationsStatistic({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });
}

class OperationsQuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color? iconColor;

  const OperationsQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.iconColor,
  });
}

class ActiveService {
  final String bookingId;
  final String farmerName;
  final String pilotName;
  final String droneId;
  final String village;
  final String status;
  final Color statusColor;

  const ActiveService({
    required this.bookingId,
    required this.farmerName,
    required this.pilotName,
    required this.droneId,
    required this.village,
    required this.status,
    required this.statusColor,
  });
}

class PendingAssignment {
  final String bookingId;
  final String farmerName;
  final String serviceName;
  final String preferredDate;
  final String area;

  const PendingAssignment({
    required this.bookingId,
    required this.farmerName,
    required this.serviceName,
    required this.preferredDate,
    required this.area,
  });
}

class OperationsActivity {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;

  const OperationsActivity({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}
