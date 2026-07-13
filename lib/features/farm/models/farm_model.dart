import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String? docId;
  final String farmerUid;
  final String farmName;
  final String cropType;
  final double area;
  final String unit;
  final String village;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmModel({
    this.docId,
    required this.farmerUid,
    required this.farmName,
    required this.cropType,
    required this.area,
    required this.unit,
    required this.village,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerUid': farmerUid,
      'farmName': farmName,
      'cropType': cropType,
      'area': area,
      'unit': unit,
      'village': village,
      'district': district,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map, String docId) {
    return FarmModel(
      docId: docId,
      farmerUid: map['farmerUid'] ?? '',
      farmName: map['farmName'] ?? '',
      cropType: map['cropType'] ?? '',
      area: (map['area'] as num).toDouble(),
      unit: map['unit'] ?? 'Acres',
      village: map['village'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  FarmModel copyWith({
    String? docId,
    String? farmerUid,
    String? farmName,
    String? cropType,
    double? area,
    String? unit,
    String? village,
    String? district,
    String? state,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      docId: docId ?? this.docId,
      farmerUid: farmerUid ?? this.farmerUid,
      farmName: farmName ?? this.farmName,
      cropType: cropType ?? this.cropType,
      area: area ?? this.area,
      unit: unit ?? this.unit,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
