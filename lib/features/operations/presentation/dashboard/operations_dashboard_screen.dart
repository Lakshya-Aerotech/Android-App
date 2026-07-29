import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lakshya_aerotech/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/constants/app_sizes.dart';
import 'package:lakshya_aerotech/core/constants/app_spacing.dart';
import 'package:lakshya_aerotech/core/localization/app_localizations.dart';
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

    final today = DateFormat('EEEE, d MMMM', Localizations.localeOf(context).languageCode).format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(userName: user?.name ?? 'Operations', subtitle: today),
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
                  _buildSectionTitle(context.tr('Operational Overview')),
                  const SizedBox(height: 16),
                  switch (statsAsync) {
                    AsyncData(:final value) => LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double itemWidth = (width - 16) / 2;
                        final double textScale =
                            MediaQuery.textScalerOf(context).scale(1.0);
                        final double minItemHeight = 125.0 * textScale;
                        final double ratio = itemWidth / minItemHeight;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: value.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: ratio,
                          ),
                          itemBuilder: (context, index) {
                            final stat = value[index];
                            return OperationsStatisticCard(
                              icon: stat.icon,
                              iconColor: stat.iconColor,
                              title: context.tr(stat.title),
                              value: stat.value,
                            );
                          },
                        );
                      },
                    ),
                    AsyncError(:final error) => Text('Error loading stats: $error'),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                  const SizedBox(height: 32),

                  // Quick Actions
                  _buildSectionTitle(context.tr('Quick Actions')),
                  const SizedBox(height: 16),
                  OperationsQuickActionCard(
                    icon: Icons.rate_review_outlined,
                    title: context.tr('Review Bookings'),
                    subtitle: context.tr('Verify and approve new requests'),
                    iconColor: Colors.blue,
                    onTap: () => context.push('/operations/bookings'),
                  ),
                  const SizedBox(height: 12),
                  OperationsQuickActionCard(
                    icon: Icons.assignment_ind_outlined,
                    title: context.tr('Assign Pilot'),
                    subtitle: context.tr('Match pilots with approved bookings'),
                    iconColor: Colors.purple,
                    onTap: () => context.push('/operations/assignments'),
                  ),
                  const SizedBox(height: 12),
                  OperationsQuickActionCard(
                    icon: Icons.send,
                    title: context.tr('Send Notifications'),
                    subtitle: context.tr('Broadcast messages or alert users'),
                    iconColor: Colors.orange,
                    onTap: () => context.push('/operations/notifications'),
                  ),
                  const SizedBox(height: 32),

                  // Recent Bookings
                  _buildSectionTitle(context.tr('Recent Bookings')),
                  const SizedBox(height: 16),
                  switch (recentBookingsAsync) {
                    AsyncData(:final value) =>
                      value.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(context.tr('No bookings found.')),
                          )
                          : Column(
                            children:
                                value
                                    .map(
                                      (b) => OpsHydratedBookingCard(
                                        booking: b,
                                        onTap:
                                            () => context.push(
                                              '/ops-booking-details',
                                              extra: b,
                                            ),
                                      ),
                                    )
                                    .toList(),
                          ),
                    AsyncError(:final error) => Text('Error: $error'),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
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
