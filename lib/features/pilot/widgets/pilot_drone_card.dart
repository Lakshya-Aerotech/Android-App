import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PilotDroneCard extends StatelessWidget {
  const PilotDroneCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusLg,
            ),
            child: const Icon(
              Icons.flight_takeoff_outlined,
              color: AppColors.accent,
              size: AppSizes.iconSizeLg,
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drone: LA-DR-007',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                AppSpacing.verticalXs,
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _DroneInfo(
                      icon: Icons.circle,
                      iconColor: AppColors.accent,
                      label: 'Ready',
                    ),
                    _DroneInfo(
                      icon: Icons.battery_6_bar_outlined,
                      iconColor: AppColors.accent,
                      label: '86%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DroneInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _DroneInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSizeSm, color: iconColor),
        AppSpacing.horizontalXs,
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMutedDark,
          ),
        ),
      ],
    );
  }
}
