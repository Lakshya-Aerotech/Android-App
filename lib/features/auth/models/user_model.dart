import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, pilot, operations, admin, retailer }

enum ApprovalStatus { pending, approved, rejected, suspended }

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
  final ApprovalStatus? approvalStatus;

  // Admin Module Specific Fields
  final String? createdBy;
  final String? createdByRetailerId;
  final String? createdByRole;
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
    this.approvalStatus,
    this.createdBy,
    this.createdByRetailerId,
    this.createdByRole,
    this.lastLogin,
    this.profileImageUrl,
    this.mustChangePassword = true,
    this.authCreated = false,
    this.fcmTokens = const [],
    this.completedMissions = 0,
    this.totalAcresCovered = 0.0,
    this.totalFlightMinutes = 0,
    this.totalFlightHours = 0.0,
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
      'approvalStatus': approvalStatus?.name,
      'createdBy': createdBy,
      'createdByRetailerId': createdByRetailerId,
      'createdByRole': createdByRole,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'profileImageUrl': profileImageUrl,
      'mustChangePassword': mustChangePassword,
      'authCreated': authCreated,
      'fcmTokens': fcmTokens,
      'completedMissions': completedMissions,
      'totalAcresCovered': totalAcresCovered,
      'totalFlightMinutes': totalFlightMinutes,
      'totalFlightHours': totalFlightHours,
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
      approvalStatus: map['approvalStatus'] != null
          ? ApprovalStatus.values.byName(
              (map['approvalStatus'] as String).toLowerCase(),
            )
          : null,
      createdBy: map['createdBy'],
      createdByRetailerId: map['createdByRetailerId'] ?? map['createdBy'],
      createdByRole: map['createdByRole'],
      lastLogin: map['lastLogin'] != null
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
    ApprovalStatus? approvalStatus,
    String? createdBy,
    String? createdByRetailerId,
    String? createdByRole,
    DateTime? lastLogin,
    String? profileImageUrl,
    bool? mustChangePassword,
    bool? authCreated,
    List<String>? fcmTokens,
    int? completedMissions,
    double? totalAcresCovered,
    int? totalFlightMinutes,
    double? totalFlightHours,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdBy: createdBy ?? this.createdBy,
      createdByRetailerId: createdByRetailerId ?? this.createdByRetailerId,
      createdByRole: createdByRole ?? this.createdByRole,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      authCreated: authCreated ?? this.authCreated,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      completedMissions: completedMissions ?? this.completedMissions,
      totalAcresCovered: totalAcresCovered ?? this.totalAcresCovered,
      totalFlightMinutes: totalFlightMinutes ?? this.totalFlightMinutes,
      totalFlightHours: totalFlightHours ?? this.totalFlightHours,
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
