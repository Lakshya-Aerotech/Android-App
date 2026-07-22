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
  final String village;
  final String status;
  final Color statusColor;

  const ActiveService({
    required this.bookingId,
    required this.farmerName,
    required this.pilotName,
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

class OpsPilotResource {
  final String uid;
  final String documentId;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String role;
  final bool isActive;
  final bool isAvailable;
  final int? currentWorkload;
  final Map<String, dynamic> details;

  const OpsPilotResource({
    required this.uid,
    required this.documentId,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.isActive,
    required this.isAvailable,
    this.currentWorkload,
    this.details = const {},
  });

  bool get canSelect => isActive && isAvailable;
}

class OpsAssignmentRequest {
  final String bookingDocId;
  final String bookingNumber;
  final String farmerId;
  final OpsPilotResource pilot;
  final OpsPilotResource? copilot;

  const OpsAssignmentRequest({
    required this.bookingDocId,
    required this.bookingNumber,
    required this.farmerId,
    required this.pilot,
    this.copilot,
  });
}
