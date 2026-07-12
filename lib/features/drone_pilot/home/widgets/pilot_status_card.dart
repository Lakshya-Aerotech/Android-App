import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PilotStatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const PilotStatusCard({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = isAvailable ? 'Available for Duty' : 'Off Duty';
    final statusColor = isAvailable
        ? AppColors.accent
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconSizeSm,
            height: AppSizes.iconSizeSm,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  statusLabel,
                  style: AppTextStyles.bodyMedium.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
