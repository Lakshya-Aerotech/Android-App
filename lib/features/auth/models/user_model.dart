import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, pilot, operations, admin, externalPilot, retailer }

extension UserRoleExtension on UserRole {
  String get value => toString().split('.').last;
}

enum ApprovalStatus { pending, approved, rejected, suspended }

extension ApprovalStatusExtension on ApprovalStatus {
  String get value => toString().split('.').last;
}

enum AccountStatus { active, inactive, suspended }

extension AccountStatusExtension on AccountStatus {
  String get value => toString().split('.').last;
}

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
  final String? createdByRetailerId;
  final String? createdByRole;
  final DateTime? lastLogin;
  final String? profileImageUrl;
  final bool mustChangePassword;
  final bool authCreated;
  final List<String> fcmTokens;

  // Earnings & Wallet Fields
  final double walletBalance;
  final int completedJobs;
  final double totalAcres;
  final double totalEarned;
  final DateTime? lastSalaryPaidAt;
  final double? lastSalaryAmount;

  // Pilot Specific Statistics (Legacy/Redundant if using Wallet fields above)
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

  // Retailer Specific Fields
  final String? shopName;
  final String? ownerName;
  final String? gstNumber;
  final String? aadhaarPan;
  final String? shopAddress;
  final String? mandal;
  final double? latitude;
  final double? longitude;

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
    this.createdByRetailerId,
    this.createdByRole,
    this.lastLogin,
    this.profileImageUrl,
    this.mustChangePassword = true,
    this.authCreated = false,
    this.fcmTokens = const [],
    this.walletBalance = 0.0,
    this.completedJobs = 0,
    this.totalAcres = 0.0,
    this.totalEarned = 0.0,
    this.lastSalaryPaidAt,
    this.lastSalaryAmount,
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
    this.shopName,
    this.ownerName,
    this.gstNumber,
    this.aadhaarPan,
    this.shopAddress,
    this.mandal,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.value,
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
      'createdByRetailerId': createdByRetailerId,
      'createdByRole': createdByRole,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'profileImageUrl': profileImageUrl,
      'mustChangePassword': mustChangePassword,
      'authCreated': authCreated,
      'fcmTokens': fcmTokens,
      'walletBalance': walletBalance,
      'completedJobs': completedJobs,
      'totalAcres': totalAcres,
      'totalEarned': totalEarned,
      'lastSalaryPaidAt': lastSalaryPaidAt != null ? Timestamp.fromDate(lastSalaryPaidAt!) : null,
      'lastSalaryAmount': lastSalaryAmount,
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
      'approvalStatus': approvalStatus?.value,
      'accountStatus': accountStatus?.value,
      'rejectionReason': rejectionReason,
      'shopName': shopName,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'aadhaarPan': aadhaarPan,
      'shopAddress': shopAddress,
      'mandal': mandal,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    UserRole parsedRole = UserRole.farmer;
    final roleStr = map['role'] ?? 'farmer';
    for (var r in UserRole.values) {
      if (r.value == roleStr) {
        parsedRole = r;
        break;
      }
    }

    return UserModel(
      docId: docId,
      uid: map['uid'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      role: parsedRole,
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
      createdByRetailerId: map['createdByRetailerId'] ?? map['createdBy'],
      createdByRole: map['createdByRole'],
      lastLogin:
          map['lastLogin'] != null
              ? (map['lastLogin'] as Timestamp).toDate()
              : null,
      profileImageUrl: map['profileImageUrl'],
      mustChangePassword: map['mustChangePassword'] ?? true,
      authCreated: map['authCreated'] ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      completedJobs: map['completedJobs'] ?? 0,
      totalAcres: (map['totalAcres'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (map['totalEarned'] as num?)?.toDouble() ?? 0.0,
      lastSalaryPaidAt: map['lastSalaryPaidAt'] != null ? (map['lastSalaryPaidAt'] as Timestamp).toDate() : null,
      lastSalaryAmount: (map['lastSalaryAmount'] as num?)?.toDouble(),
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
              ? ApprovalStatus.values.firstWhere((s) => s.value == map['approvalStatus'], orElse: () => ApprovalStatus.pending)
              : null,
      accountStatus:
          map['accountStatus'] != null
              ? AccountStatus.values.firstWhere((s) => s.value == map['accountStatus'], orElse: () => AccountStatus.active)
              : null,
      rejectionReason: map['rejectionReason'],
      shopName: map['shopName'],
      ownerName: map['ownerName'],
      gstNumber: map['gstNumber'],
      aadhaarPan: map['aadhaarPan'],
      shopAddress: map['shopAddress'],
      mandal: map['mandal'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
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
    String? createdByRetailerId,
    String? createdByRole,
    DateTime? lastLogin,
    String? profileImageUrl,
    bool? mustChangePassword,
    bool? authCreated,
    List<String>? fcmTokens,
    double? walletBalance,
    int? completedJobs,
    double? totalAcres,
    double? totalEarned,
    DateTime? lastSalaryPaidAt,
    double? lastSalaryAmount,
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
    String? shopName,
    String? ownerName,
    String? gstNumber,
    String? aadhaarPan,
    String? shopAddress,
    String? mandal,
    double? latitude,
    double? longitude,
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
      createdByRetailerId: createdByRetailerId ?? this.createdByRetailerId,
      createdByRole: createdByRole ?? this.createdByRole,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      authCreated: authCreated ?? this.authCreated,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      walletBalance: walletBalance ?? this.walletBalance,
      completedJobs: completedJobs ?? this.completedJobs,
      totalAcres: totalAcres ?? this.totalAcres,
      totalEarned: totalEarned ?? this.totalEarned,
      lastSalaryPaidAt: lastSalaryPaidAt ?? this.lastSalaryPaidAt,
      lastSalaryAmount: lastSalaryAmount ?? this.lastSalaryAmount,
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
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      gstNumber: gstNumber ?? this.gstNumber,
      aadhaarPan: aadhaarPan ?? this.aadhaarPan,
      shopAddress: shopAddress ?? this.shopAddress,
      mandal: mandal ?? this.mandal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
