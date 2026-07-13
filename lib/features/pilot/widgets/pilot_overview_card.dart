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
  final double? height;

  const PilotOverviewCard({super.key, required this.metric, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, size: AppSizes.iconSizeMd, color: metric.color),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            metric.label,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedDark,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
