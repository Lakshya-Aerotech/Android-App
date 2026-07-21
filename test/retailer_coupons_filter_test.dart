import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_aerotech/features/admin/models/coupon_model.dart';
import 'package:lakshya_aerotech/features/auth/models/user_model.dart';

void main() {
  group('Retailer Coupon Filtering Logic', () {
    final now = DateTime.now();
    final user = UserModel(
      uid: 'retailer-1',
      docId: 'retailer-1',
      role: UserRole.retailer,
      state: 'Telangana',
      createdAt: now,
      updatedAt: now,
    );

    bool filterCoupon(CouponModel coupon, UserModel retailer) {
      final couponRegion = coupon.applicableRegion.trim().toLowerCase();
      final userState = (retailer.state ?? '').trim().toLowerCase();

      final regionMatch = couponRegion.isEmpty ||
          couponRegion == 'all' ||
          couponRegion == 'global' ||
          couponRegion == 'any' ||
          couponRegion == userState;

      final retailerMatch = coupon.assignedRetailerIds.isEmpty ||
          coupon.assignedRetailerIds.contains(retailer.uid) ||
          coupon.assignedRetailerIds.contains(retailer.docId);

      return regionMatch && retailerMatch;
    }

    test('should match global coupon (region = all)', () {
      final coupon = CouponModel(
        couponCode: 'GLOBAL10',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'All',
        assignedRetailerIds: [],
        assignedRetailerNames: [],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isTrue);
    });

    test('should match global coupon (region = global)', () {
      final coupon = CouponModel(
        couponCode: 'GLOBAL20',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'global',
        assignedRetailerIds: [],
        assignedRetailerNames: [],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isTrue);
    });

    test('should match region-specific coupon', () {
      final coupon = CouponModel(
        couponCode: 'TS50',
        discountType: CouponDiscountType.percentage,
        discountValue: 50,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'Telangana',
        assignedRetailerIds: [],
        assignedRetailerNames: [],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isTrue);
    });

    test('should not match different region coupon', () {
      final coupon = CouponModel(
        couponCode: 'AP50',
        discountType: CouponDiscountType.percentage,
        discountValue: 50,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'Andhra Pradesh',
        assignedRetailerIds: [],
        assignedRetailerNames: [],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isFalse);
    });

    test('should match coupon assigned to this retailer', () {
      final coupon = CouponModel(
        couponCode: 'SPECIAL',
        discountType: CouponDiscountType.percentage,
        discountValue: 15,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'Telangana',
        assignedRetailerIds: ['retailer-1'],
        assignedRetailerNames: ['My Shop'],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isTrue);
    });

    test('should not match coupon assigned to another retailer', () {
      final coupon = CouponModel(
        couponCode: 'OTHER',
        discountType: CouponDiscountType.percentage,
        discountValue: 15,
        validFrom: now,
        validUntil: now.add(const Duration(days: 10)),
        maximumUsage: 100,
        remainingUsage: 100,
        eligibleService: 'Drone Spraying',
        applicableRegion: 'Telangana',
        assignedRetailerIds: ['retailer-2'],
        assignedRetailerNames: ['Other Shop'],
        isActive: true,
      );

      expect(filterCoupon(coupon, user), isFalse);
    });
  });
}
