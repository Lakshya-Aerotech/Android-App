import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, pilot, operations, admin }
 }

enum ApprovalStatus { pending, approved, rejected }

enum AccountStatus { active, inactive, suspended }

class UserModel {
  final String? docId; // Firestore Document ID
  final String? uid; // Firebase Auth UID
  final String? phoneNumber;
  final String? email;
  final UserRole role;
  final bool profileCompleted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name;
  final String? village;
  final String? district;
  final String? state;
  final String? preferredLanguage;

  // Admin Module Specific Fields
  final String? createdBy;
  final DateTime? lastLogin;
  final String? profileImageUrl;
  final bool mustChangePassword;
  final bool authCreated;
  final List<String> fcmTokens;

  // Pilot Specific Statistics
  final int completedMissions;
  final double totalAcresCovered;
  final int totalFlightMinutes;
  final double totalFlightHours;

  // External Pilot Specific Fields
  final String? address;
  final String? aadhaarNumber;
  final String? dronePilotCertificateUrl;
  final String? dgcaCertificateUrl;
  final String? droneDetails;
  final List<String> operatingDistricts;
  final double? operatingRadius;
  final String? profilePhotographUrl;
  final ApprovalStatus? approvalStatus;
  final AccountStatus? accountStatus;
  final String? rejectionReason;

  UserModel({
    this.docId,
    this.uid,
    this.phoneNumber,
    this.email,
    required this.role,
    this.profileCompleted = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.village,
    this.district,
    this.state,
    this.preferredLanguage,
    this.createdBy,
    this.lastLogin,
    this.profileImageUrl,
    this.mustChangePassword = true,
    this.authCreated = false,
    this.fcmTokens = const [],
    this.completedMissions = 0,
    this.totalAcresCovered = 0.0,
    this.totalFlightMinutes = 0,
    this.totalFlightHours = 0.0,
    this.address,
    this.aadhaarNumber,
    this.dronePilotCertificateUrl,
    this.dgcaCertificateUrl,
    this.droneDetails,
    this.operatingDistricts = const [],
    this.operatingRadius,
    this.profilePhotographUrl,
    this.approvalStatus,
    this.accountStatus,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.name,
      'profileCompleted': profileCompleted,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'name': name,
      'village': village,
      'district': district,
      'state': state,
      'preferredLanguage': preferredLanguage,
      'createdBy': createdBy,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'profileImageUrl': profileImageUrl,
      'mustChangePassword': mustChangePassword,
      'authCreated': authCreated,
      'fcmTokens': fcmTokens,
      'completedMissions': completedMissions,
      'totalAcresCovered': totalAcresCovered,
      'totalFlightMinutes': totalFlightMinutes,
      'totalFlightHours': totalFlightHours,
      'address': address,
      'aadhaarNumber': aadhaarNumber,
      'dronePilotCertificateUrl': dronePilotCertificateUrl,
      'dgcaCertificateUrl': dgcaCertificateUrl,
      'droneDetails': droneDetails,
      'operatingDistricts': operatingDistricts,
      'operatingRadius': operatingRadius,
      'profilePhotographUrl': profilePhotographUrl,
      'approvalStatus': approvalStatus?.name,
      'accountStatus': accountStatus?.name,
      'rejectionReason': rejectionReason,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return UserModel(
      docId: docId,
      uid: map['uid'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      role: UserRole.values.byName(map['role'] ?? 'farmer'),
      profileCompleted: map['profileCompleted'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      name: map['name'],
      village: map['village'],
      district: map['district'],
      state: map['state'],
      preferredLanguage: map['preferredLanguage'],
      createdBy: map['createdBy'],
      lastLogin:
          map['lastLogin'] != null
              ? (map['lastLogin'] as Timestamp).toDate()
              : null,
      profileImageUrl: map['profileImageUrl'],
      mustChangePassword: map['mustChangePassword'] ?? true,
      authCreated: map['authCreated'] ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      completedMissions: map['completedMissions'] ?? 0,
      totalAcresCovered: (map['totalAcresCovered'] as num?)?.toDouble() ?? 0.0,
      totalFlightMinutes: map['totalFlightMinutes'] ?? 0,
      totalFlightHours: (map['totalFlightHours'] as num?)?.toDouble() ?? 0.0,
      address: map['address'],
      aadhaarNumber: map['aadhaarNumber'],
      dronePilotCertificateUrl: map['dronePilotCertificateUrl'],
      dgcaCertificateUrl: map['dgcaCertificateUrl'],
      droneDetails: map['droneDetails'],
      operatingDistricts: List<String>.from(map['operatingDistricts'] ?? []),
      operatingRadius: (map['operatingRadius'] as num?)?.toDouble(),
      profilePhotographUrl: map['profilePhotographUrl'],
      approvalStatus:
          map['approvalStatus'] != null
              ? ApprovalStatus.values.byName(map['approvalStatus'])
              : null,
      accountStatus:
          map['accountStatus'] != null
              ? AccountStatus.values.byName(map['accountStatus'])
              : null,
      rejectionReason: map['rejectionReason'],
    );
  }

  UserModel copyWith({
    String? docId,
    String? uid,
    String? phoneNumber,
    String? email,
    UserRole? role,
    bool? profileCompleted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? village,
    String? district,
    String? state,
    String? preferredLanguage,
    String? createdBy,
    DateTime? lastLogin,
    String? profileImageUrl,
    bool? mustChangePassword,
    bool? authCreated,
    List<String>? fcmTokens,
    int? completedMissions,
    double? totalAcresCovered,
    int? totalFlightMinutes,
    double? totalFlightHours,
    String? address,
    String? aadhaarNumber,
    String? dronePilotCertificateUrl,
    String? dgcaCertificateUrl,
    String? droneDetails,
    List<String>? operatingDistricts,
    double? operatingRadius,
    String? profilePhotographUrl,
    ApprovalStatus? approvalStatus,
    AccountStatus? accountStatus,
    String? rejectionReason,
  }) {
    return UserModel(
      docId: docId ?? this.docId,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdBy: createdBy ?? this.createdBy,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      authCreated: authCreated ?? this.authCreated,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      completedMissions: completedMissions ?? this.completedMissions,
      totalAcresCovered: totalAcresCovered ?? this.totalAcresCovered,
      totalFlightMinutes: totalFlightMinutes ?? this.totalFlightMinutes,
      totalFlightHours: totalFlightHours ?? this.totalFlightHours,
      address: address ?? this.address,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      dronePilotCertificateUrl:
          dronePilotCertificateUrl ?? this.dronePilotCertificateUrl,
      dgcaCertificateUrl: dgcaCertificateUrl ?? this.dgcaCertificateUrl,
      droneDetails: droneDetails ?? this.droneDetails,
      operatingDistricts: operatingDistricts ?? this.operatingDistricts,
      operatingRadius: operatingRadius ?? this.operatingRadius,
      profilePhotographUrl: profilePhotographUrl ?? this.profilePhotographUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

