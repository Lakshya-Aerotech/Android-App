import 'package:cloud_firestore/cloud_firestore.dart';

enum DroneStatus { available, busy, maintenance }

class DroneModel {
  final String? docId;
  final String droneId;
  final String model;
  final int capacity; // In Litres
  final int batteryPercentage;
  final DroneStatus status;
  final String currentLocation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DroneModel({
    this.docId,
    required this.droneId,
    required this.model,
    required this.capacity,
    required this.batteryPercentage,
    required this.status,
    required this.currentLocation,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'droneId': droneId,
      'model': model,
      'capacity': capacity,
      'batteryPercentage': batteryPercentage,
      'status': status.name,
      'currentLocation': currentLocation,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DroneModel.fromMap(Map<String, dynamic> map, String docId) {
    return DroneModel(
      docId: docId,
      droneId: map['droneId'] ?? '',
      model: map['model'] ?? '',
      capacity: map['capacity'] ?? 0,
      batteryPercentage: map['batteryPercentage'] ?? 0,
      status: DroneStatus.values.byName(map['status'] ?? 'available'),
      currentLocation: map['currentLocation'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  DroneModel copyWith({
    String? docId,
    String? droneId,
    String? model,
    int? capacity,
    int? batteryPercentage,
    DroneStatus? status,
    String? currentLocation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DroneModel(
      docId: docId ?? this.docId,
      droneId: droneId ?? this.droneId,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
