import 'package:flutter/material.dart';
import '../models/operations_models.dart';
import '../../../core/theme/app_colors.dart';

abstract class OperationsRepository {
  Future<List<OperationsStatistic>> getStatistics();
  Future<List<ActiveService>> getActiveServices();
  Future<List<PendingAssignment>> getPendingAssignments();
  Future<List<OperationsActivity>> getRecentActivities();
}

class OperationsRepositoryImpl implements OperationsRepository {
  @override
  Future<List<OperationsStatistic>> getStatistics() async {
    return [
      const OperationsStatistic(
        icon: Icons.pending_actions,
        iconColor: Colors.orange,
        title: 'Pending Bookings',
        value: '12',
      ),
      const OperationsStatistic(
        icon: Icons.rate_review_outlined,
        iconColor: Colors.blue,
        title: 'Under Review',
        value: '5',
      ),
      const OperationsStatistic(
        icon: Icons.assignment_ind_outlined,
        iconColor: Colors.purple,
        title: 'Assigned Jobs',
        value: '28',
      ),
      const OperationsStatistic(
        icon: Icons.run_circle_outlined,
        iconColor: AppColors.accent,
        title: 'Active Services',
        value: '8',
      ),
      const OperationsStatistic(
        icon: Icons.person_search_outlined,
        iconColor: Colors.teal,
        title: 'Available Pilots',
        value: '15',
      ),
      const OperationsStatistic(
        icon: Icons.precision_manufacturing_outlined,
        iconColor: Colors.indigo,
        title: 'Available Drones',
        value: '10',
      ),
      const OperationsStatistic(
        icon: Icons.task_alt,
        iconColor: Colors.green,
        title: 'Today Completed',
        value: '18',
      ),
      const OperationsStatistic(
        icon: Icons.report_problem_outlined,
        iconColor: Colors.red,
        title: 'Issues Reported',
        value: '2',
      ),
    ];
  }

  @override
  Future<List<ActiveService>> getActiveServices() async {
    return [
      const ActiveService(
        bookingId: 'BK-1024',
        farmerName: 'Ramesh Babu',
        pilotName: 'Suresh Kumar',
        droneId: 'DR-007',
        village: 'Kothapalli',
        status: 'In Progress',
        statusColor: Colors.orange,
      ),
      const ActiveService(
        bookingId: 'BK-1025',
        farmerName: 'Venkatesh Rao',
        pilotName: 'Anil Kumar',
        droneId: 'DR-012',
        village: 'Peddapalli',
        status: 'Started',
        statusColor: Colors.green,
      ),
    ];
  }

  @override
  Future<List<PendingAssignment>> getPendingAssignments() async {
    return [
      const PendingAssignment(
        bookingId: 'BK-1030',
        farmerName: 'Mahesh Reddy',
        serviceName: 'Precision Spraying',
        preferredDate: '24 Oct 2023',
        area: '5.5 Acres',
      ),
      const PendingAssignment(
        bookingId: 'BK-1031',
        farmerName: 'Srinivas Goud',
        serviceName: 'Crop Monitoring',
        preferredDate: '25 Oct 2023',
        area: '10 Acres',
      ),
    ];
  }

  @override
  Future<List<OperationsActivity>> getRecentActivities() async {
    return [
      const OperationsActivity(
        title: 'Pilot Suresh Assigned to BK-1024',
        time: '10 mins ago',
        icon: Icons.assignment_ind,
        iconColor: Colors.blue,
      ),
      const OperationsActivity(
        title: 'Service Started for BK-1025',
        time: '30 mins ago',
        icon: Icons.play_circle_outline,
        iconColor: Colors.green,
      ),
      const OperationsActivity(
        title: 'Booking Request BK-1030 Received',
        time: '1 hour ago',
        icon: Icons.notifications_active_outlined,
        iconColor: Colors.orange,
      ),
    ];
  }
}
