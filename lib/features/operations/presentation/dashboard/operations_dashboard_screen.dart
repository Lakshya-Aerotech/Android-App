import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lakshya_aerotech/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/constants/app_sizes.dart';
import 'package:lakshya_aerotech/core/constants/app_spacing.dart';
import 'package:lakshya_aerotech/shared/components/dashboard_header.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';
import 'package:lakshya_aerotech/features/operations/presentation/widgets/operations_statistic_card.dart';
import 'package:lakshya_aerotech/features/operations/presentation/widgets/operations_quick_action_card.dart';
import 'package:lakshya_aerotech/features/operations/widgets/ops_hydrated_booking_card.dart';

class OperationsDashboardScreen extends ConsumerWidget {
  const OperationsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final statsAsync = ref.watch(dashboardStatsStreamProvider);
    final recentBookingsAsync = ref.watch(recentBookingsStreamProvider);
    
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

                  // Recent Bookings
                  _buildSectionTitle('Recent Bookings'),
                  const SizedBox(height: 16),
                  recentBookingsAsync.when(
                    data: (bookings) {
                      if (bookings.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No bookings found.'),
                        );
                      }
                      return Column(
                        children: bookings.map((b) => OpsHydratedBookingCard(
                          booking: b,
                          onTap: () => context.push('/ops-booking-details', extra: b),
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),

                  // Recent Activity (derived from recent bookings for now)
                  _buildSectionTitle('Recent Activity'),
                  const SizedBox(height: 16),
                  recentBookingsAsync.when(
                    data: (bookings) {
                      if (bookings.isEmpty) return const Text('No recent activity.');
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: bookings.take(5).map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: b.status.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(b.status.icon, size: 18, color: b.status.color),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking ${b.bookingId} - ${b.status.displayName}',
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                      ),
                                      if (b.farmerName != null)
                                        Text(
                                          'Farmer: ${b.farmerName}',
                                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                                        ),
                                      Text(
                                        DateFormat('dd MMM, hh:mm a').format(b.updatedAt),
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
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
