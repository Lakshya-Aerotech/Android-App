import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../drone_pilot_home_data.dart';

class PilotProgressCard extends StatelessWidget {
  final List<PilotProgressStage> stages;
  final String activeValue;

  const PilotProgressCard({
    super.key,
    required this.stages,
    required this.activeValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.soft,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: stages.map((stage) {
          final isActive = stage.value == activeValue;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.lightBackground,
              borderRadius: AppRadius.radiusXl,
              border: Border.all(
                color: isActive ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              stage.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive
                    ? AppColors.textInverted
                    : AppColors.textMutedDark,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
