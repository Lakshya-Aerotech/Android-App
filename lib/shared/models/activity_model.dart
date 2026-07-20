import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  employeeCreated,
  farmerRegistered,
  farmAdded,
  bookingCreated,
  bookingApproved,
  bookingRejected,
  pilotAssigned,
  droneAssigned,
  missionStarted,
  missionCompleted,
  farmerConfirmedService,
  externalPilotRegistered,
}

class ActivityModel {
  final String? id;
  final ActivityType type;
  final String description;
  final String? userId;
  final String? userName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityModel({
    this.id,
    required this.type,
    required this.description,
    this.userId,
    this.userName,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      type: ActivityType.values.byName(map['type']),
      description: map['description'] ?? '',
      userId: map['userId'],
      userName: map['userName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  IconData get icon {
    switch (type) {
      case ActivityType.employeeCreated:
        return Icons.person_add;
      case ActivityType.farmerRegistered:
        return Icons.agriculture;
      case ActivityType.farmAdded:
        return Icons.landscape;
      case ActivityType.bookingCreated:
        return Icons.book_online;
      case ActivityType.bookingApproved:
        return Icons.verified;
      case ActivityType.bookingRejected:
        return Icons.cancel;
      case ActivityType.pilotAssigned:
        return Icons.assignment_ind;
      case ActivityType.droneAssigned:
        return Icons.precision_manufacturing;
      case ActivityType.missionStarted:
        return Icons.play_circle_outline;
      case ActivityType.missionCompleted:
        return Icons.check_circle_outline;
      case ActivityType.farmerConfirmedService:
        return Icons.star_border;
      case ActivityType.externalPilotRegistered:
        return Icons.person_add_alt_1;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.employeeCreated:
        return Colors.blue;
      case ActivityType.farmerRegistered:
        return Colors.green;
      case ActivityType.farmAdded:
        return Colors.orange;
      case ActivityType.bookingCreated:
        return Colors.indigo;
      case ActivityType.bookingApproved:
        return Colors.teal;
      case ActivityType.bookingRejected:
        return Colors.red;
      case ActivityType.pilotAssigned:
        return Colors.purple;
      case ActivityType.droneAssigned:
        return Colors.indigo;
      case ActivityType.missionStarted:
        return Colors.amber;
      case ActivityType.missionCompleted:
        return Colors.lightGreen;
      case ActivityType.farmerConfirmedService:
        return Colors.pink;
      case ActivityType.externalPilotRegistered:
        return Colors.cyan;
    }
  }
}
