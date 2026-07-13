import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, pilot, operations, admin }

class UserModel {
  final String? docId; // Firestore Document ID
  final String? uid;   // Firebase Auth UID
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
      lastLogin: map['lastLogin'] != null ? (map['lastLogin'] as Timestamp).toDate() : null,
      profileImageUrl: map['profileImageUrl'],
      mustChangePassword: map['mustChangePassword'] ?? true,
      authCreated: map['authCreated'] ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
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
    );
  }
}
