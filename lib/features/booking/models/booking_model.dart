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
  final String? farmerId;
  final String? createdByRole;
  final String? createdByRetailerId;

  // Farm Snapshot
  final String farmId;
  final String farmName;
  final String? village;
  final String? district;
  final String? state;
  final String cropType;
  final double? farmArea;
  final double? latitude;
  final double? longitude;

  // Service Details
  final String serviceType;
  final DateTime bookingDate;
  final String preferredTime;
  final double estimatedArea;
  final BookingStatus status;
  final String? remarks;

  // Coupon & Payment Details
  final String? couponId;
  final String? couponCode;
  final String? couponDiscountType;
  final double? couponDiscountValue;
  final String? retailerName;
  final double? originalAmount;
  final double? discountAmount;
  final double? payableAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? paymentRequestedAt;
  final bool cashCollected;
  final String? cashCollectedBy;
  final DateTime? cashCollectedAt;
  final bool cashDeposited;
  final String? cashDepositedBy;
  final DateTime? cashDepositedAt;
  final bool paymentVerifiedByAdmin;
  final DateTime? paymentVerifiedAt;
  final String? verifiedByAdminId;
  final String? adminRemarks;
  final bool couponVerified;
  final String? couponVerificationStatus;
  final String? couponVerifiedBy;
  final DateTime? couponVerifiedAt;

  // Operations & Execution
  final List<OperationsRemark> operationsRemarks;
  final String? assignedPilotId;
  final String? assignedPilotName;
  final String? copilotId;
  final String? copilotName;
  final DateTime? assignedCopilotAt;

  // Pilot Execution Details
  final String? missionNotes;
  final double? actualAreaCovered;
  final DateTime? missionStartedAt;
  final DateTime? missionCompletedAt;
  final int? flightDurationMinutes;
  final double? flightDurationHours;
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

  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  BookingModel({
    this.docId,
    required this.bookingId,
    required this.farmerUid,
    this.farmerName,
    this.farmerPhone,
    this.preferredLanguage,
    this.farmerId,
    this.createdByRole,
    this.createdByRetailerId,
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
    this.couponId,
    this.couponCode,
    this.couponDiscountType,
    this.couponDiscountValue,
    this.retailerName,
    this.originalAmount,
    this.discountAmount,
    this.payableAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentRequestedAt,
    this.cashCollected = false,
    this.cashCollectedBy,
    this.cashCollectedAt,
    this.cashDeposited = false,
    this.cashDepositedBy,
    this.cashDepositedAt,
    this.paymentVerifiedByAdmin = false,
    this.paymentVerifiedAt,
    this.verifiedByAdminId,
    this.adminRemarks,
    this.couponVerified = false,
    this.couponVerificationStatus,
    this.couponVerifiedBy,
    this.couponVerifiedAt,
    this.operationsRemarks = const [],
    this.assignedPilotId,
    this.assignedPilotName,
    this.copilotId,
    this.copilotName,
    this.assignedCopilotAt,
    this.missionNotes,
    this.actualAreaCovered,
    this.missionStartedAt,
    this.missionCompletedAt,
    this.flightDurationMinutes,
    this.flightDurationHours,
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
      'farmerId': farmerId,
      'createdByRole': createdByRole,
      'createdByRetailerId': createdByRetailerId,
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
      'couponId': couponId,
      'couponCode': couponCode,
      'couponDiscountType': couponDiscountType,
      'couponDiscountValue': couponDiscountValue,
      'retailerName': retailerName,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'payableAmount': payableAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentRequestedAt': paymentRequestedAt != null ? Timestamp.fromDate(paymentRequestedAt!) : null,
      'cashCollected': cashCollected,
      'cashCollectedBy': cashCollectedBy,
      'cashCollectedAt': cashCollectedAt != null ? Timestamp.fromDate(cashCollectedAt!) : null,
      'cashDeposited': cashDeposited,
      'cashDepositedBy': cashDepositedBy,
      'cashDepositedAt': cashDepositedAt != null ? Timestamp.fromDate(cashDepositedAt!) : null,
      'paymentVerifiedByAdmin': paymentVerifiedByAdmin,
      'paymentVerifiedAt': paymentVerifiedAt != null ? Timestamp.fromDate(paymentVerifiedAt!) : null,
      'verifiedByAdminId': verifiedByAdminId,
      'adminRemarks': adminRemarks,
      'couponVerified': couponVerified,
      'couponVerificationStatus': couponVerificationStatus,
      'couponVerifiedBy': couponVerifiedBy,
      'couponVerifiedAt': couponVerifiedAt != null ? Timestamp.fromDate(couponVerifiedAt!) : null,
      'operationsRemarks': operationsRemarks.map((e) => e.toMap()).toList(),
      'assignedPilotId': assignedPilotId,
      'assignedPilotName': assignedPilotName,
      if (copilotId != null) 'copilotId': copilotId,
      if (copilotName != null) 'copilotName': copilotName,
      if (assignedCopilotAt != null)
        'assignedCopilotAt': Timestamp.fromDate(assignedCopilotAt!),
      'missionNotes': missionNotes,
      'actualAreaCovered': actualAreaCovered,
      'missionStartedAt': missionStartedAt != null ? Timestamp.fromDate(missionStartedAt!) : null,
      'missionCompletedAt': missionCompletedAt != null ? Timestamp.fromDate(missionCompletedAt!) : null,
      'flightDurationMinutes': flightDurationMinutes,
      'flightDurationHours': flightDurationHours,
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
      farmerId: map['farmerId'],
      createdByRole: map['createdByRole'],
      createdByRetailerId: map['createdByRetailerId'],
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
      couponId: map['couponId'],
      couponCode: map['couponCode'],
      couponDiscountType: map['couponDiscountType'],
      couponDiscountValue: (map['couponDiscountValue'] as num?)?.toDouble(),
      retailerName: map['retailerName'],
      originalAmount: (map['originalAmount'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? (map['couponDiscountAmount'] as num?)?.toDouble(),
      payableAmount: (map['payableAmount'] as num?)?.toDouble() ?? (map['finalAmount'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'],
      paymentRequestedAt: (map['paymentRequestedAt'] as Timestamp?)?.toDate(),
      cashCollected: map['cashCollected'] ?? false,
      cashCollectedBy: map['cashCollectedBy'],
      cashCollectedAt: (map['cashCollectedAt'] as Timestamp?)?.toDate(),
      cashDeposited: map['cashDeposited'] ?? false,
      cashDepositedBy: map['cashDepositedBy'],
      cashDepositedAt: (map['cashDepositedAt'] as Timestamp?)?.toDate(),
      paymentVerifiedByAdmin: map['paymentVerifiedByAdmin'] ?? false,
      paymentVerifiedAt: (map['paymentVerifiedAt'] as Timestamp?)?.toDate(),
      verifiedByAdminId: map['verifiedByAdminId'],
      adminRemarks: map['adminRemarks'],
      couponVerified: map['couponVerified'] ?? false,
      couponVerificationStatus: map['couponVerificationStatus'],
      couponVerifiedBy: map['couponVerifiedBy'],
      couponVerifiedAt: (map['couponVerifiedAt'] as Timestamp?)?.toDate(),
      operationsRemarks: (map['operationsRemarks'] as List? ?? [])
          .map((e) => OperationsRemark.fromMap(e as Map<String, dynamic>))
          .toList(),
      assignedPilotId: map['assignedPilotId'],
      assignedPilotName: map['assignedPilotName'],
      copilotId: map['copilotId'],
      copilotName: map['copilotName'],
      assignedCopilotAt: (map['assignedCopilotAt'] as Timestamp?)?.toDate(),
      missionNotes: map['missionNotes'],
      actualAreaCovered: (map['actualAreaCovered'] as num?)?.toDouble(),
      missionStartedAt: (map['missionStartedAt'] as Timestamp?)?.toDate(),
      missionCompletedAt: (map['missionCompletedAt'] as Timestamp?)?.toDate(),
      flightDurationMinutes: map['flightDurationMinutes'] as int?,
      flightDurationHours: (map['flightDurationHours'] as num?)?.toDouble(),
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
    String? farmerId,
    String? createdByRole,
    String? createdByRetailerId,
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
    String? couponId,
    String? couponCode,
    String? couponDiscountType,
    double? couponDiscountValue,
    String? retailerName,
    double? originalAmount,
    double? discountAmount,
    double? payableAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? paymentRequestedAt,
    bool? cashCollected,
    String? cashCollectedBy,
    DateTime? cashCollectedAt,
    bool? cashDeposited,
    String? cashDepositedBy,
    DateTime? cashDepositedAt,
    bool? paymentVerifiedByAdmin,
    DateTime? paymentVerifiedAt,
    String? verifiedByAdminId,
    String? adminRemarks,
    bool? couponVerified,
    String? couponVerificationStatus,
    String? couponVerifiedBy,
    DateTime? couponVerifiedAt,
    List<OperationsRemark>? operationsRemarks,
    String? assignedPilotId,
    String? assignedPilotName,
    String? copilotId,
    String? copilotName,
    DateTime? assignedCopilotAt,
    String? missionNotes,
    double? actualAreaCovered,
    DateTime? missionStartedAt,
    DateTime? missionCompletedAt,
    int? flightDurationMinutes,
    double? flightDurationHours,
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
      farmerId: farmerId ?? this.farmerId,
      createdByRole: createdByRole ?? this.createdByRole,
      createdByRetailerId: createdByRetailerId ?? this.createdByRetailerId,
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
      couponId: couponId ?? this.couponId,
      couponCode: couponCode ?? this.couponCode,
      couponDiscountType: couponDiscountType ?? this.couponDiscountType,
      couponDiscountValue: couponDiscountValue ?? this.couponDiscountValue,
      retailerName: retailerName ?? this.retailerName,
      originalAmount: originalAmount ?? this.originalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      payableAmount: payableAmount ?? this.payableAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentRequestedAt: paymentRequestedAt ?? this.paymentRequestedAt,
      cashCollected: cashCollected ?? this.cashCollected,
      cashCollectedBy: cashCollectedBy ?? this.cashCollectedBy,
      cashCollectedAt: cashCollectedAt ?? this.cashCollectedAt,
      cashDeposited: cashDeposited ?? this.cashDeposited,
      cashDepositedBy: cashDepositedBy ?? this.cashDepositedBy,
      cashDepositedAt: cashDepositedAt ?? this.cashDepositedAt,
      paymentVerifiedByAdmin: paymentVerifiedByAdmin ?? this.paymentVerifiedByAdmin,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      verifiedByAdminId: verifiedByAdminId ?? this.verifiedByAdminId,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      couponVerified: couponVerified ?? this.couponVerified,
      couponVerificationStatus: couponVerificationStatus ?? this.couponVerificationStatus,
      couponVerifiedBy: couponVerifiedBy ?? this.couponVerifiedBy,
      couponVerifiedAt: couponVerifiedAt ?? this.couponVerifiedAt,
      operationsRemarks: operationsRemarks ?? this.operationsRemarks,
      assignedPilotId: assignedPilotId ?? this.assignedPilotId,
      assignedPilotName: assignedPilotName ?? this.assignedPilotName,
      copilotId: copilotId ?? this.copilotId,
      copilotName: copilotName ?? this.copilotName,
      assignedCopilotAt: assignedCopilotAt ?? this.assignedCopilotAt,
      missionNotes: missionNotes ?? this.missionNotes,
      actualAreaCovered: actualAreaCovered ?? this.actualAreaCovered,
      missionStartedAt: missionStartedAt ?? this.missionStartedAt,
      missionCompletedAt: missionCompletedAt ?? this.missionCompletedAt,
      flightDurationMinutes: flightDurationMinutes ?? this.flightDurationMinutes,
      flightDurationHours: flightDurationHours ?? this.flightDurationHours,
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
