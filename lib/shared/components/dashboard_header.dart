import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/notifications/notification_viewmodel.dart';

class DashboardHeader extends ConsumerWidget {
  final String userName;
  final String? subtitle;
  final Widget? bottomChild;
  final VoidCallback? onNotificationPressed;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.subtitle,
    this.bottomChild,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotificationPressed ?? () => context.push('/notifications'),
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                      tooltip: context.tr('Notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Text(
              '${context.tr('Hello')}, $userName',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                context.tr(subtitle!),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            AppSpacing.verticalXs,
            Text(
              context.tr(_greetingFor(DateTime.now())),
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (bottomChild != null) ...[AppSpacing.verticalLg, bottomChild!],
          ],
        ),
      ),
    );
  }
}
