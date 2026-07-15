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

class StatusHistoryEntry {
  final BookingStatus status;
  final String updatedBy;
  final String updatedByRole;
  final DateTime timestamp;
  final String? remarks;

  StatusHistoryEntry({
    required this.status,
    required this.updatedBy,
    required this.updatedByRole,
    required this.timestamp,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.toFirestore(),
      'updatedBy': updatedBy,
      'updatedByRole': updatedByRole,
      'timestamp': Timestamp.fromDate(timestamp),
      'remarks': remarks,
    };
  }

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: BookingStatus.fromString(map['status']),
      updatedBy: map['updatedBy'] ?? '',
      updatedByRole: map['updatedByRole'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      remarks: map['remarks'],
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
  final String? assignedPilotName;
  final String? assignedDroneId;
  final String? assignedDroneName;

  // Pilot Execution Details
  final String? pilotRejectionReason;
  final String? missionNotes;
  final double? actualAreaCovered;
  final String? flightDuration;
  final String? chemicalUsed;
  final List<String> missionPhotos;

  // Farmer Post-Service
  final double? rating;
  final String? feedback;
  final DateTime? feedbackCreatedAt;
  final String? issueCategory;
  final String? issueDescription;
  final DateTime? issueReportedAt;
  final DateTime? confirmedAt;

  // Status History Audit Trail
  final List<StatusHistoryEntry> statusHistory;

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
    this.assignedPilotName,
    this.assignedDroneId,
    this.assignedDroneName,
    this.pilotRejectionReason,
    this.missionNotes,
    this.actualAreaCovered,
    this.flightDuration,
    this.chemicalUsed,
    this.missionPhotos = const [],
    this.rating,
    this.feedback,
    this.feedbackCreatedAt,
    this.issueCategory,
    this.issueDescription,
    this.issueReportedAt,
    this.confirmedAt,
    this.statusHistory = const [],
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
      'assignedPilotName': assignedPilotName,
      'assignedDroneId': assignedDroneId,
      'assignedDroneName': assignedDroneName,
      'pilotRejectionReason': pilotRejectionReason,
      'missionNotes': missionNotes,
      'actualAreaCovered': actualAreaCovered,
      'flightDuration': flightDuration,
      'chemicalUsed': chemicalUsed,
      'missionPhotos': missionPhotos,
      'rating': rating,
      'feedback': feedback,
      'feedbackCreatedAt': feedbackCreatedAt != null ? Timestamp.fromDate(feedbackCreatedAt!) : null,
      'issueCategory': issueCategory,
      'issueDescription': issueDescription,
      'issueReportedAt': issueReportedAt != null ? Timestamp.fromDate(issueReportedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      docId: docId,
      bookingId: map['bookingId'] ?? '',
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? map['farmer_name'],
      farmerPhone: map['farmerPhone'] ?? map['phone'],
      preferredLanguage: map['preferredLanguage'] ?? map['language'],
      farmId: map['farmId'] ?? '',
      farmName: map['farmName'] ?? '',
      village: map['village'],
      district: map['district'],
      state: map['state'],
      cropType: map['cropType'] ?? '',
      farmArea:
          (map['farmArea'] as num?)?.toDouble() ??
          (map['area'] as num?)?.toDouble(),
      latitude:
          (map['latitude'] as num?)?.toDouble() ??
          (map['lat'] as num?)?.toDouble(),
      longitude:
          (map['longitude'] as num?)?.toDouble() ??
          (map['lng'] as num?)?.toDouble(),
      serviceType: map['serviceType'] ?? '',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      preferredTime: map['preferredTime'] ?? '',
      estimatedArea: (map['estimatedArea'] as num).toDouble(),
      status: BookingStatus.fromString(map['status']),
      remarks: map['remarks'],
      operationsRemarks:
          (map['operationsRemarks'] as List? ?? [])
              .map((e) => OperationsRemark.fromMap(e as Map<String, dynamic>))
              .toList(),
      assignedPilotId: map['assignedPilotId'],
      assignedPilotName: map['assignedPilotName'],
      assignedDroneId: map['assignedDroneId'],
      assignedDroneName: map['assignedDroneName'],
      pilotRejectionReason: map['pilotRejectionReason'],
      missionNotes: map['missionNotes'],
      actualAreaCovered: (map['actualAreaCovered'] as num?)?.toDouble(),
      flightDuration: map['flightDuration'],
      chemicalUsed: map['chemicalUsed'],
      missionPhotos: List<String>.from(map['missionPhotos'] ?? []),
      rating: (map['rating'] as num?)?.toDouble(),
      feedback: map['feedback'],
      feedbackCreatedAt: (map['feedbackCreatedAt'] as Timestamp?)?.toDate(),
      issueCategory: map['issueCategory'],
      issueDescription: map['issueDescription'],
      issueReportedAt: (map['issueReportedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
      statusHistory: (map['statusHistory'] as List? ?? [])
          .map((e) => StatusHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
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
    String? assignedPilotName,
    String? assignedDroneId,
    String? assignedDroneName,
    String? pilotRejectionReason,
    String? missionNotes,
    double? actualAreaCovered,
    String? flightDuration,
    String? chemicalUsed,
    List<String>? missionPhotos,
    double? rating,
    String? feedback,
    DateTime? feedbackCreatedAt,
    String? issueCategory,
    String? issueDescription,
    DateTime? issueReportedAt,
    DateTime? confirmedAt,
    List<StatusHistoryEntry>? statusHistory,
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
      assignedPilotName: assignedPilotName ?? this.assignedPilotName,
      assignedDroneId: assignedDroneId ?? this.assignedDroneId,
      assignedDroneName: assignedDroneName ?? this.assignedDroneName,
      pilotRejectionReason: pilotRejectionReason ?? this.pilotRejectionReason,
      missionNotes: missionNotes ?? this.missionNotes,
      actualAreaCovered: actualAreaCovered ?? this.actualAreaCovered,
      flightDuration: flightDuration ?? this.flightDuration,
      chemicalUsed: chemicalUsed ?? this.chemicalUsed,
      missionPhotos: missionPhotos ?? this.missionPhotos,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      feedbackCreatedAt: feedbackCreatedAt ?? this.feedbackCreatedAt,
      issueCategory: issueCategory ?? this.issueCategory,
      issueDescription: issueDescription ?? this.issueDescription,
      issueReportedAt: issueReportedAt ?? this.issueReportedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
