import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../admin/models/coupon_model.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class RetailerCouponsScreen extends ConsumerWidget {
  const RetailerCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsStreamProvider);
    final user = ref.watch(userModelProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Coupons'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('User not logged in'))
          : couponsAsync.when(
              data: (coupons) {
                final retailerCoupons = coupons.where((coupon) {
                  final couponRegion = coupon.applicableRegion.trim().toLowerCase();
                  final userState = (user.state ?? '').trim().toLowerCase();
                  final regionMatch = couponRegion.isEmpty ||
                      couponRegion == 'all' ||
                      couponRegion == 'global' ||
                      couponRegion == 'any' ||
                      couponRegion == userState;

                  // Trim all IDs in the list for robust comparison
                  final retailerMatch = coupon.assignedRetailerIds.isEmpty ||
                      coupon.assignedRetailerIds.any((id) => id.trim() == user.uid?.trim()) ||
                      coupon.assignedRetailerIds.any((id) => id.trim() == user.docId?.trim());

                  return regionMatch && retailerMatch;
                }).toList();

                if (retailerCoupons.isEmpty) {
                  return const EmptyState(
                    title: 'No coupons available',
                    message: 'Check back later for special offers and discounts.',
                    icon: Icons.local_offer_outlined,
                  );
                }

                // Partition coupons into eligible (active & valid) and ineligible (expired/inactive/exhausted)
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final eligibleCoupons = <CouponModel>[];
                final ineligibleCoupons = <CouponModel>[];

                for (final coupon in retailerCoupons) {
                  final start = DateTime(
                    coupon.validFrom.year,
                    coupon.validFrom.month,
                    coupon.validFrom.day,
                  );
                  final end = DateTime(
                    coupon.validUntil.year,
                    coupon.validUntil.month,
                    coupon.validUntil.day,
                  );

                  final isExpired = today.isAfter(end);
                  final isNotYetValid = today.isBefore(start);
                  final hasUsageLeft = coupon.remainingUsage > 0;
                  final isEligible = coupon.isActive &&
                      !isExpired &&
                      !isNotYetValid &&
                      hasUsageLeft;

                  if (isEligible) {
                    eligibleCoupons.add(coupon);
                  } else {
                    ineligibleCoupons.add(coupon);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    if (eligibleCoupons.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          'Available Offers',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      ...eligibleCoupons.map((coupon) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RetailerCouponCard(
                              coupon: coupon,
                              isEligible: true,
                            ),
                          )),
                    ],
                    if (ineligibleCoupons.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 4),
                        child: Text(
                          'Expired or Inactive',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...ineligibleCoupons.map((coupon) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RetailerCouponCard(
                              coupon: coupon,
                              isEligible: false,
                            ),
                          )),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
    );
  }
}

class _RetailerCouponCard extends StatelessWidget {
  final CouponModel coupon;
  final bool isEligible;

  const _RetailerCouponCard({
    required this.coupon,
    required this.isEligible,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final discount = coupon.discountType == CouponDiscountType.percentage
        ? '${coupon.discountValue.toStringAsFixed(0)}%'
        : 'Rs. ${coupon.discountValue.toStringAsFixed(0)}';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      coupon.validUntil.year,
      coupon.validUntil.month,
      coupon.validUntil.day,
    );

    // Determine specific badge reason if ineligible
    String statusText = 'Active';
    Color badgeColor = AppColors.success;

    if (!coupon.isActive) {
      statusText = 'Inactive';
      badgeColor = AppColors.textTertiary;
    } else if (today.isAfter(end)) {
      statusText = 'Expired';
      badgeColor = AppColors.error;
    } else if (coupon.remainingUsage <= 0) {
      statusText = 'Exhausted';
      badgeColor = Colors.orange;
    } else if (today.isBefore(DateTime(coupon.validFrom.year, coupon.validFrom.month, coupon.validFrom.day))) {
      statusText = 'Upcoming';
      badgeColor = Colors.blue;
    }

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEligible
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.5),
          width: isEligible ? 1.5 : 1.0,
        ),
        boxShadow: isEligible
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: isEligible ? AppColors.primary : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    coupon.couponCode,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEligible ? AppColors.textDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discount,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEligible ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining Uses',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${coupon.remainingUsage} / ${coupon.maximumUsage}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEligible ? AppColors.textDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eligible Service',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.eligibleService,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isEligible ? AppColors.textDark : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Valid Until',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(coupon.validUntil),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isEligible ? AppColors.textDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (!isEligible) {
      return Opacity(
        opacity: 0.6,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
