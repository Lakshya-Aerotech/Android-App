import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String? subtitle;
  final Widget? bottomChild;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.subtitle,
    this.bottomChild,
    this.onMenuPressed,
    this.onNotificationPressed,
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
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          topPadding + AppSpacing.md,
          AppSizes.screenPadding,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onMenuPressed ?? () {},
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menu',
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotificationPressed ?? () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
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
              'Hello, $userName',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            AppSpacing.verticalXs,
            Text(
              _greetingFor(DateTime.now()),
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (bottomChild != null) ...[
              AppSpacing.verticalLg,
              bottomChild!,
            ],
          ],
        ),
      ),
    );
  }
}
