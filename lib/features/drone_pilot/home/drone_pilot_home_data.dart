import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PilotOverviewMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const PilotOverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class PilotAssignment {
  final String bookingId;
  final String status;
  final String statusValue;
  final String farmer;
  final String service;
  final String farm;
  final String location;
  final String time;
  final String area;
  final String drone;

  const PilotAssignment({
    required this.bookingId,
    required this.status,
    required this.statusValue,
    required this.farmer,
    required this.service,
    required this.farm,
    required this.location,
    required this.time,
    required this.area,
    required this.drone,
  });
}

class PilotProgressStage {
  final String label;
  final String value;

  const PilotProgressStage({required this.label, required this.value});
}

class PilotUpcomingJob {
  final String service;
  final String farmer;
  final String location;
  final String time;
  final String status;

  const PilotUpcomingJob({
    required this.service,
    required this.farmer,
    required this.location,
    required this.time,
    required this.status,
  });
}

const pilotOverviewMetrics = [
  PilotOverviewMetric(
    label: 'Assigned Jobs',
    value: '3',
    icon: Icons.assignment_outlined,
    color: AppColors.primary,
  ),
  PilotOverviewMetric(
    label: 'Completed',
    value: '1',
    icon: Icons.check_circle_outline,
    color: AppColors.accent,
  ),
  PilotOverviewMetric(
    label: 'Pending',
    value: '2',
    icon: Icons.schedule_outlined,
    color: AppColors.warning,
  ),
];

const currentPilotAssignment = PilotAssignment(
  bookingId: 'LA-2026-00124',
  status: 'Travelling',
  statusValue: 'travelling',
  farmer: 'Ravi Kumar',
  service: 'Precision Spraying',
  farm: 'Green Field Farm',
  location: 'Warangal, Telangana',
  time: '10:30 AM',
  area: '5.2 acres',
  drone: 'LA-DR-007',
);

const pilotProgressStages = [
  PilotProgressStage(label: 'Assigned', value: 'assigned'),
  PilotProgressStage(label: 'Travelling', value: 'travelling'),
  PilotProgressStage(label: 'Operator Arrived', value: 'operator_arrived'),
  PilotProgressStage(label: 'Service Started', value: 'service_started'),
  PilotProgressStage(label: 'Completed', value: 'completed'),
];

const pilotUpcomingJobs = [
  PilotUpcomingJob(
    service: 'Precision Spraying',
    farmer: 'Suresh Reddy',
    location: 'Karimnagar, Telangana',
    time: '1:30 PM',
    status: 'Assigned',
  ),
  PilotUpcomingJob(
    service: 'Crop Monitoring',
    farmer: 'Mahesh Rao',
    location: 'Warangal, Telangana',
    time: '4:00 PM',
    status: 'Assigned',
  ),
];
