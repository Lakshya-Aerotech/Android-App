import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(metric.icon, size: AppSizes.iconSizeMd, color: metric.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  metric.value,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMutedDark,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
