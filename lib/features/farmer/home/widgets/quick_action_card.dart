import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? assetPath;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: AppRadius.radiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: AppRadius.radiusLg,
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (assetPath != null)
                  Image.asset(
                    assetPath!,
                    width: AppSizes.iconSizeLg,
                    height: AppSizes.iconSizeLg,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          icon,
                          size: AppSizes.iconSizeLg,
                          color: iconColor,
                        ),
                  )
                else
                  Icon(icon, size: AppSizes.iconSizeLg, color: iconColor),
                AppSpacing.verticalMd,
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
