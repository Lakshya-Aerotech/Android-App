import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/pilot_dashboard_data.dart';

class PilotUpcomingJobCard extends StatelessWidget {
  final PilotUpcomingJob job;

  const PilotUpcomingJobCard({super.key, required this.job});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.assignment_outlined,
            color: AppColors.primary,
            size: AppSizes.iconSizeMd,
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      job.service,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    StatusChip(
                      label: job.status,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                      textColor: AppColors.accent,
                    ),
                  ],
                ),
                AppSpacing.verticalSm,
                Text(
                  job.farmer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  '${job.location} • ${job.time}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
