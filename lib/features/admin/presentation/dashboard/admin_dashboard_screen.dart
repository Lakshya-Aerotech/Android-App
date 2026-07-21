import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../../../shared/models/activity_model.dart';
import '../widgets/admin_statistic_card.dart';
import '../widgets/quick_action_card.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final statsAsync = ref.watch(adminStatisticsStreamProvider);
    final activitiesAsync = ref.watch(recentActivitiesStreamProvider);
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatisticsStreamProvider);
          ref.invalidate(recentActivitiesStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                userName: user?.name ?? context.tr('Admin'),
                subtitle: today,
                onNotificationPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSpacing.lg,
                  AppSizes.screenPadding,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context.tr('Overview')),
                    const SizedBox(height: 16),
                    statsAsync.when(
                      data: (stats) => LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          final double itemWidth = (width - 16) / 2;
                          final double textScale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1.0);
                          final double minItemHeight = 135.0 * textScale;
                          final double ratio = itemWidth / minItemHeight;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stats.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: ratio,
                                ),
                            itemBuilder: (context, index) {
                              final stat = stats[index];
                              return AdminStatisticCard(
                                icon: stat.icon,
                                iconColor: stat.iconColor,
                                title: stat.title,
                                value: stat.value,
                                onTap: stat.onTap,
                              );
                            },
                          );
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context.tr('Quick Actions')),
                    const SizedBox(height: 16),
                    QuickActionCard(
                      icon: Icons.person_add_outlined,
                      title: context.tr('Add Employee'),
                      subtitle: 'Register new Pilot or Operations staff',
                      iconColor: AppColors.success,
                      onTap: () => context.push('/admin/add-employee'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.people_outline,
                      title: context.tr('Manage Employees'),
                      subtitle: 'View and manage all staff members',
                      onTap: () => context.push('/admin/employees'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.verified_user_outlined,
                      title: 'External Pilot Approvals',
                      subtitle:
                          'Approve or reject external pilot registrations',
                      iconColor: Colors.orange,
                      onTap: () => context.push('/admin/external-pilots'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.storefront_outlined,
                      title: 'Retailer Management',
                      subtitle: 'Approve and manage retailer accounts',
                      iconColor: AppColors.warning,
                      onTap: () => context.push('/admin/retailers'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.local_offer_outlined,
                      title: context.tr('Coupon Management'),
                      subtitle: 'Create and manage retailer coupons',
                      iconColor: AppColors.success,
                      onTap: () => context.push('/admin/coupons'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.grid_view_outlined,
                      title: context.tr('Manage Drones'),
                      subtitle: 'Register and track drone fleet',
                      onTap: () => context.push('/admin/drones'),
                    ),
                    const SizedBox(height: 12),
                    QuickActionCard(
                      icon: Icons.analytics_outlined,
                      title: context.tr('Analytics & Reports'),
                      subtitle: 'View business insights and download reports',
                      iconColor: AppColors.info,
                      onTap: () => context.push('/admin/analytics'),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(context.tr('Recent Activity')),
                        TextButton(
                          onPressed: () =>
                              context.push('/admin/recent-activity'),
                          child: Text(context.tr('View All')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    activitiesAsync.when(
                      data: (activities) {
                        if (activities.isEmpty) {
                          return _buildNoActivity();
                        }
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: activities
                                .map(
                                  (activity) =>
                                      _ActivityItem(activity: activity),
                                )
                                .toList(),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityModel activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (activity.userName != null)
                      Text(
                        activity.userName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      _formatTimestamp(activity.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
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

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(dt);
  }
}
