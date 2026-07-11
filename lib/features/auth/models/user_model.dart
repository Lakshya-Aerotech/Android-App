import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, pilot, operations, admin }

class UserModel {
  final String uid;
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

  UserModel({
    required this.uid,
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
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
    );
  }
}
