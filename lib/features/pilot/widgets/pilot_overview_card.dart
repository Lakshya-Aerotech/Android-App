import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/pilot_dashboard_data.dart';

class PilotOverviewCard extends StatelessWidget {
  final PilotOverviewMetric metric;

  const PilotOverviewCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(metric.icon, size: AppSizes.iconSizeMd, color: metric.color),
          AppSpacing.verticalSm,
          Text(
            metric.value,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textDark,
            ),
          ),
          AppSpacing.verticalSm,
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                metric.label,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMutedDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
