import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponDiscountType { percentage, fixed }

extension CouponDiscountTypeExtension on CouponDiscountType {
  String get value => toString().split('.').last;
}

class CouponModel {
  final String? docId;
  final String couponCode;
  final CouponDiscountType discountType;
  final double discountValue;
  final DateTime validFrom;
  final DateTime validUntil;
  final int maximumUsage;
  final int remainingUsage;
  final String eligibleService;
  final String applicableRegion;
  final List<String> assignedRetailerIds;
  final List<String> assignedRetailerNames;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CouponModel({
    this.docId,
    required this.couponCode,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validUntil,
    required this.maximumUsage,
    required this.remainingUsage,
    required this.eligibleService,
    required this.applicableRegion,
    required this.assignedRetailerIds,
    required this.assignedRetailerNames,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  String get normalizedCode => couponCode.trim().toUpperCase();

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'couponCode': couponCode.trim().toUpperCase(),
      'couponCodeNormalized': normalizedCode,
      'discountType': discountType.value,
      'discountValue': discountValue,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'maximumUsage': maximumUsage,
      'remainingUsage': remainingUsage,
      'eligibleService': eligibleService.trim(),
      'applicableRegion': applicableRegion.trim(),
      'assignedRetailerIds': assignedRetailerIds,
      'assignedRetailerNames': assignedRetailerNames,
      'isActive': isActive,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CouponModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CouponModel(
      docId: docId,
      couponCode: map['couponCode'] ?? '',
      discountType: CouponDiscountType.values.firstWhere(
        (type) => type.value == map['discountType'],
        orElse: () => CouponDiscountType.percentage,
      ),
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      validFrom: _readDate(map['validFrom']),
      validUntil: _readDate(map['validUntil']),
      maximumUsage: (map['maximumUsage'] as num?)?.toInt() ?? 0,
      remainingUsage: (map['remainingUsage'] as num?)?.toInt() ?? 0,
      eligibleService: map['eligibleService'] ?? '',
      applicableRegion: map['applicableRegion'] ?? '',
      assignedRetailerIds: List<String>.from(map['assignedRetailerIds'] ?? []),
      assignedRetailerNames: List<String>.from(
        map['assignedRetailerNames'] ?? [],
      ),
      isActive: map['isActive'] ?? true,
      createdAt: _readNullableDate(map['createdAt']),
      updatedAt: _readNullableDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    return _readNullableDate(value) ?? DateTime.now();
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
