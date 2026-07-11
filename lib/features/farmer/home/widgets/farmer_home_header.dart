import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'farmer_promo_banner.dart';

class FarmerHomeHeader extends StatelessWidget {
  final String farmerName;
  final VoidCallback onBookNow;

  const FarmerHomeHeader({
    super.key,
    required this.farmerName,
    required this.onBookNow,
  });

  String _greetingFor(DateTime now) {
    if (now.hour < 12) {
      return 'Good Morning!';
    }
    if (now.hour < 17) {
      return 'Good Afternoon!';
    }
    return 'Good Evening!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSpacing.md,
          AppSizes.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu, color: AppColors.icon),
                  tooltip: 'Menu',
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: AppColors.icon,
                      ),
                      tooltip: 'Notifications',
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Text(
              'Hello, $farmerName',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.verticalXs,
            Text(
              _greetingFor(DateTime.now()),
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalLg,
            FarmerPromoBanner(onBookNow: onBookNow),
          ],
        ),
      ),
    );
  }
}
