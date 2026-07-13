import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/booking_status.dart';

class BookingModel {
  final String? docId;
  final String bookingId;
  final String farmerUid;
  final String farmId;
  final String farmName;
  final String cropType;
  final String serviceType;
  final DateTime bookingDate;
  final String preferredTime;
  final double estimatedArea;
  final BookingStatus status;
  final String? remarks;
  final String? assignedPilotId;
  final String? assignedDroneId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    this.docId,
    required this.bookingId,
    required this.farmerUid,
    required this.farmId,
    required this.farmName,
    required this.cropType,
    required this.serviceType,
    required this.bookingDate,
    required this.preferredTime,
    required this.estimatedArea,
    this.status = BookingStatus.pending,
    this.remarks,
    this.assignedPilotId,
    this.assignedDroneId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'farmerUid': farmerUid,
      'farmId': farmId,
      'farmName': farmName,
      'cropType': cropType,
      'serviceType': serviceType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'preferredTime': preferredTime,
      'estimatedArea': estimatedArea,
      'status': status.name,
      'remarks': remarks,
      'assignedPilotId': assignedPilotId,
      'assignedDroneId': assignedDroneId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      docId: docId,
      bookingId: map['bookingId'] ?? '',
      farmerUid: map['farmerUid'] ?? '',
      farmId: map['farmId'] ?? '',
      farmName: map['farmName'] ?? '',
      cropType: map['cropType'] ?? '',
      serviceType: map['serviceType'] ?? '',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      preferredTime: map['preferredTime'] ?? '',
      estimatedArea: (map['estimatedArea'] as num).toDouble(),
      status: BookingStatus.values.byName(map['status'] ?? 'pending'),
      remarks: map['remarks'],
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
    String? farmId,
    String? farmName,
    String? cropType,
    String? serviceType,
    DateTime? bookingDate,
    String? preferredTime,
    double? estimatedArea,
    BookingStatus? status,
    String? remarks,
    String? assignedPilotId,
    String? assignedDroneId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      docId: docId ?? this.docId,
      bookingId: bookingId ?? this.bookingId,
      farmerUid: farmerUid ?? this.farmerUid,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      cropType: cropType ?? this.cropType,
      serviceType: serviceType ?? this.serviceType,
      bookingDate: bookingDate ?? this.bookingDate,
      preferredTime: preferredTime ?? this.preferredTime,
      estimatedArea: estimatedArea ?? this.estimatedArea,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      assignedPilotId: assignedPilotId ?? this.assignedPilotId,
      assignedDroneId: assignedDroneId ?? this.assignedDroneId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
