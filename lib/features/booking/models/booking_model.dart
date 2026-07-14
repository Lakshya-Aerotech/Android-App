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
  final String farmerUid;
  final String? farmerName;
  final String farmId;
  final String farmName;
  final String? village;
  final String? district;
  final String cropType;
  final String serviceType;
  final DateTime bookingDate;
  final String preferredTime;
  final double estimatedArea;
  final BookingStatus status;
  final String? remarks;
  final List<OperationsRemark> operationsRemarks;
  final String? assignedPilotId;
  final String? assignedDroneId;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    this.docId,
    required this.bookingId,
    required this.farmerUid,
    this.farmerName,
    required this.farmId,
    required this.farmName,
    this.village,
    this.district,
    required this.cropType,
    required this.serviceType,
    required this.bookingDate,
    required this.preferredTime,
    required this.estimatedArea,
    this.status = BookingStatus.pending,
    this.remarks,
    this.operationsRemarks = const [],
    this.assignedPilotId,
    this.assignedDroneId,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'farmerUid': farmerUid,
      'farmerName': farmerName,
      'farmId': farmId,
      'farmName': farmName,
      'village': village,
      'district': district,
      'cropType': cropType,
      'serviceType': serviceType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'preferredTime': preferredTime,
      'estimatedArea': estimatedArea,
      'status': status.name,
      'remarks': remarks,
      'operationsRemarks': operationsRemarks.map((e) => e.toMap()).toList(),
      'assignedPilotId': assignedPilotId,
      'assignedDroneId': assignedDroneId,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      docId: docId,
      bookingId: map['bookingId'] ?? '',
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'],
      farmId: map['farmId'] ?? '',
      farmName: map['farmName'] ?? '',
      village: map['village'],
      district: map['district'],
      cropType: map['cropType'] ?? '',
      serviceType: map['serviceType'] ?? '',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      preferredTime: map['preferredTime'] ?? '',
      estimatedArea: (map['estimatedArea'] as num).toDouble(),
      status: _statusFromString(map['status'] ?? 'pending'),
      remarks: map['remarks'],
      operationsRemarks: (map['operationsRemarks'] as List? ?? [])
          .map((e) => OperationsRemark.fromMap(e as Map<String, dynamic>))
          .toList(),
      assignedPilotId: map['assignedPilotId'],
      assignedDroneId: map['assignedDroneId'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  static BookingStatus _statusFromString(String status) {
    try {
      return BookingStatus.values.byName(status);
    } catch (_) {
      return BookingStatus.pending;
    }
  }

  BookingModel copyWith({
    String? docId,
    String? bookingId,
    String? farmerUid,
    String? farmerName,
    String? farmId,
    String? farmName,
    String? village,
    String? district,
    String? cropType,
    String? serviceType,
    DateTime? bookingDate,
    String? preferredTime,
    double? estimatedArea,
    BookingStatus? status,
    String? remarks,
    List<OperationsRemark>? operationsRemarks,
    String? assignedPilotId,
    String? assignedDroneId,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      docId: docId ?? this.docId,
      bookingId: bookingId ?? this.bookingId,
      farmerUid: farmerUid ?? this.farmerUid,
      farmerName: farmerName ?? this.farmerName,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      village: village ?? this.village,
      district: district ?? this.district,
      cropType: cropType ?? this.cropType,
      serviceType: serviceType ?? this.serviceType,
      bookingDate: bookingDate ?? this.bookingDate,
      preferredTime: preferredTime ?? this.preferredTime,
      estimatedArea: estimatedArea ?? this.estimatedArea,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      operationsRemarks: operationsRemarks ?? this.operationsRemarks,
      assignedPilotId: assignedPilotId ?? this.assignedPilotId,
      assignedDroneId: assignedDroneId ?? this.assignedDroneId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
