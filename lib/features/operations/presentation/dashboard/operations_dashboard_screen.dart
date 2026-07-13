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
import '../../viewmodels/operations_viewmodel.dart';
import '../widgets/operations_statistic_card.dart';
import '../widgets/operations_quick_action_card.dart';
import '../widgets/active_service_card.dart';
import '../widgets/pending_assignment_card.dart';

class OperationsDashboardScreen extends ConsumerWidget {
  const OperationsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final statsAsync = ref.watch(operationsStatisticsProvider);
    final activeServicesAsync = ref.watch(activeServicesProvider);
    final pendingAssignmentsAsync = ref.watch(pendingAssignmentsProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);
    
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: user?.name ?? 'Operations',
              subtitle: today,
              onNotificationPressed: () {},
              onMenuPressed: () {},
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
                  _buildSectionTitle('Operational Overview'),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    data: (stats) => LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double itemWidth = (width - 16) / 2;
                        final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
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
                            return OperationsStatisticCard(
                              icon: stat.icon,
                              iconColor: stat.iconColor,
                              title: stat.title,
                              value: stat.value,
                            );
                          },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading stats: $e'),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 16),
                  OperationsQuickActionCard(
                    icon: Icons.rate_review_outlined,
                    title: 'Review Bookings',
                    subtitle: 'Verify and approve new requests',
                    iconColor: Colors.blue,
                    onTap: () => context.push('/operations/bookings'),
                  ),
                  const SizedBox(height: 12),
                  OperationsQuickActionCard(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Assign Pilot',
                    subtitle: 'Match pilots with approved bookings',
                    iconColor: Colors.purple,
                    onTap: () => context.push('/operations/assignments'),
                  ),
                  const SizedBox(height: 12),
                  OperationsQuickActionCard(
                    icon: Icons.track_changes_outlined,
                    title: 'Track Jobs',
                    subtitle: 'Monitor real-time flight progress',
                    iconColor: AppColors.accent,
                    onTap: () => context.push('/operations/track-jobs'),
                  ),
                  const SizedBox(height: 32),

                  // Active Services
                  _buildSectionTitle('Active Services'),
                  const SizedBox(height: 16),
                  activeServicesAsync.when(
                    data: (services) => Column(
                      children: services.map((s) => ActiveServiceCard(
                        service: s,
                        onActionPressed: () {},
                      )).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading services: $e'),
                  ),
                  const SizedBox(height: 32),

                  // Pending Assignments
                  _buildSectionTitle('Pending Assignments'),
                  const SizedBox(height: 16),
                  pendingAssignmentsAsync.when(
                    data: (assignments) => Column(
                      children: assignments.map((a) => PendingAssignmentCard(
                        assignment: a,
                        onAssignPressed: () {},
                      )).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading assignments: $e'),
                  ),
                  const SizedBox(height: 32),

                  // Recent Activity
                  _buildSectionTitle('Recent Activity'),
                  const SizedBox(height: 16),
                  activitiesAsync.when(
                    data: (activities) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: activities.map((activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: activity.iconColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(activity.icon, size: 18, color: activity.iconColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity.title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                    Text(activity.time, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading activities: $e'),
                  ),
                  const SizedBox(height: 40),
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
