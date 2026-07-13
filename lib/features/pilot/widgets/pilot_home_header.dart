import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PilotHomeHeader extends StatelessWidget {
  const PilotHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSpacing.lg,
        AppSizes.screenPadding,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.iconSizeLg,
            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
            child: Text(
              'DP',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  'Drone Pilot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textPrimaryDark,
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}
