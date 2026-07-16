import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../widgets/admin_statistic_card.dart';
import '../widgets/quick_action_card.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final stats = ref.watch(adminStatisticsProvider);
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: user?.name ?? 'Admin',
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
                  _buildSectionTitle('Overview'),
                  const SizedBox(height: 16),
                  LayoutBuilder(
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                  const SizedBox(height: 32),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 16),
                  QuickActionCard(
                    icon: Icons.person_add_outlined,
                    title: 'Add Employee',
                    subtitle: 'Register new Pilot or Operations staff',
                    iconColor: AppColors.success,
                    onTap: () => context.push('/admin/add-employee'),
                  ),
                  const SizedBox(height: 12),
                  QuickActionCard(
                    icon: Icons.people_outline,
                    title: 'Manage Employees',
                    subtitle: 'View and manage all staff members',
                    onTap: () => context.push('/admin/employees'),
                  ),
                  const SizedBox(height: 12),
                  QuickActionCard(
                    icon: Icons.grid_view_outlined,
                    title: 'Manage Drones',
                    subtitle: 'Register and track drone fleet',
                    onTap: () => context.push('/admin/drones'),
                  ),
                  const SizedBox(height: 12),
                  QuickActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics & Reports',
                    subtitle: 'View business insights and download reports',
                    iconColor: AppColors.info,
                    onTap: () => context.push('/admin/analytics'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Recent Activity'),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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
