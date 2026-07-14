import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/booking_status.dart';

class OperationsRemark {
  final String message;
  final String createdBy;
  final DateTime timestamp;

  OperationsRemark({
    required this.message,
    required this.createdBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'createdBy': createdBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory OperationsRemark.fromMap(Map<String, dynamic> map) {
    return OperationsRemark(
      message: map['message'] ?? '',
      createdBy: map['createdBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class BookingModel {
  final String? docId;
  final String bookingId;
  
  // Farmer Snapshot
  final String farmerUid;
  final String? farmerName;
  final String? farmerPhone;
  final String? preferredLanguage;
  
  // Farm Snapshot
  final String farmId;
  final String farmName;
  final String? village;
  final String? district;
  final String? state;
  final String cropType;
  final double? farmArea; // Total farm area
  final double? latitude;
  final double? longitude;
  
  // Service Details
  final String serviceType;
  final DateTime bookingDate;
  final String preferredTime;
  final double estimatedArea; // Area for this specific service
  final BookingStatus status;
  final String? remarks;
  
  // Operations & Execution
  final List<OperationsRemark> operationsRemarks;
  final String? assignedPilotId;
  final String? assignedDroneId;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    this.docId,
    required this.bookingId,
    required this.farmerUid,
    this.farmerName,
    this.farmerPhone,
    this.preferredLanguage,
    required this.farmId,
    required this.farmName,
    this.village,
    this.district,
    this.state,
    required this.cropType,
    this.farmArea,
    this.latitude,
    this.longitude,
    required this.serviceType,
    required this.bookingDate,
    required this.preferredTime,
    required this.estimatedArea,
    this.status = BookingStatus.pending,
    this.remarks,
    this.operationsRemarks = const [],
    this.assignedPilotId,
    this.assignedDroneId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'farmerUid': farmerUid,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'preferredLanguage': preferredLanguage,
      'farmId': farmId,
      'farmName': farmName,
      'village': village,
      'district': district,
      'state': state,
      'cropType': cropType,
      'farmArea': farmArea,
      'latitude': latitude,
      'longitude': longitude,
      'serviceType': serviceType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'preferredTime': preferredTime,
      'estimatedArea': estimatedArea,
      'status': status.toFirestore(),
      'remarks': remarks,
      'operationsRemarks': operationsRemarks.map((e) => e.toMap()).toList(),
      'assignedPilotId': assignedPilotId,
      'assignedDroneId': assignedDroneId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    // Debug print to help identify missing fields in Firestore during development
    if (map['farmerName'] == null) debugPrint('Booking $docId: farmerName is null');
    if (map['latitude'] == null) debugPrint('Booking $docId: latitude is null');

    return BookingModel(
      docId: docId,
      bookingId: map['bookingId'] ?? '',
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? map['farmer_name'], // Try alternate naming
      farmerPhone: map['farmerPhone'] ?? map['phone'],
      preferredLanguage: map['preferredLanguage'] ?? map['language'],
      farmId: map['farmId'] ?? '',
      farmName: map['farmName'] ?? '',
      village: map['village'],
      district: map['district'],
      state: map['state'],
      cropType: map['cropType'] ?? '',
      farmArea: (map['farmArea'] as num?)?.toDouble() ?? (map['area'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? (map['lat'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble() ?? (map['lng'] as num?)?.toDouble(),
      serviceType: map['serviceType'] ?? '',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      preferredTime: map['preferredTime'] ?? '',
      estimatedArea: (map['estimatedArea'] as num).toDouble(),
      status: BookingStatus.fromString(map['status']),
      remarks: map['remarks'],
      operationsRemarks: (map['operationsRemarks'] as List? ?? [])
          .map((e) => OperationsRemark.fromMap(e as Map<String, dynamic>))
          .toList(),
      assignedPilotId: map['assignedPilotId'],
      assignedDroneId: map['assignedDroneId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  BookingModel copyWith({
    String? docId,
    String? bookingId,
    String? farmerUid,
    String? farmerName,
    String? farmerPhone,
    String? preferredLanguage,
    String? farmId,
    String? farmName,
    String? village,
    String? district,
    String? state,
    String? cropType,
    double? farmArea,
    double? latitude,
    double? longitude,
    String? serviceType,
    DateTime? bookingDate,
    String? preferredTime,
    double? estimatedArea,
    BookingStatus? status,
    String? remarks,
    List<OperationsRemark>? operationsRemarks,
    String? assignedPilotId,
    String? assignedDroneId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      docId: docId ?? this.docId,
      bookingId: bookingId ?? this.bookingId,
      farmerUid: farmerUid ?? this.farmerUid,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      cropType: cropType ?? this.cropType,
      farmArea: farmArea ?? this.farmArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceType: serviceType ?? this.serviceType,
      bookingDate: bookingDate ?? this.bookingDate,
      preferredTime: preferredTime ?? this.preferredTime,
      estimatedArea: estimatedArea ?? this.estimatedArea,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      operationsRemarks: operationsRemarks ?? this.operationsRemarks,
      assignedPilotId: assignedPilotId ?? this.assignedPilotId,
      assignedDroneId: assignedDroneId ?? this.assignedDroneId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
