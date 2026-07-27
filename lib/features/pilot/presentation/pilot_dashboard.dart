import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../booking/models/booking_model.dart';
import '../widgets/pilot_home_header.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../pilot_jobs/viewmodels/pilot_jobs_viewmodel.dart';
import '../../pilot_jobs/widgets/pilot_job_card.dart';
import '../../pilot_jobs/presentation/assignments/pilot_assignments_screen.dart';
import '../../pilot_jobs/presentation/history/pilot_history_screen.dart';

class PilotDashboard extends StatefulWidget {
  const PilotDashboard({super.key});

  @override
  State<PilotDashboard> createState() => _PilotDashboardState();
}

class _PilotDashboardState extends State<PilotDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _PilotHomeContent(),
      const PilotAssignmentsScreen(),
      const PilotHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.primary,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textTertiary,
              selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodySmall,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: context.tr('Home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_outlined),
                activeIcon: const Icon(Icons.assignment),
                label: context.tr('Jobs'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_outlined),
                activeIcon: const Icon(Icons.history),
                label: context.tr('History'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: context.tr('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PilotHomeContent extends ConsumerWidget {
  const _PilotHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final statsAsync = ref.watch(pilotDashboardStatsProvider);
    final activeJobsAsync = ref.watch(inProgressJobsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PilotHomeHeader(pilotName: user?.name ?? 'Pilot'),
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
                _SectionTitle(title: context.tr('Execution Overview')),
                AppSpacing.verticalMd,
                switch (statsAsync) {
                  AsyncData(:final value) => Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.tr('Current Earnings'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(
                                    '₹${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/pilot/wallet'),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(context.tr('View Wallet')),
                            ),
                          ],
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 16) / 2;
                      final minHeight = itemWidth < 160 ? 126.0 : 138.0;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: itemWidth / minHeight,
                        children: [
                          _StatCard(
                            title: context.tr('Today'),
                            value: value['todayAssignments'].toString(),
                            color: Colors.blue,
                            icon: Icons.calendar_today,
                          ),
                          _StatCard(
                            title: context.tr('Pending'),
                            value: value['pendingJobs'].toString(),
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                          _StatCard(
                            title: context.tr('Completed'),
                            value: value['completedJobs'].toString(),
                            color: Colors.green,
                            icon: Icons.task_alt,
                          ),
                          _StatCard(
                            title: context.tr('Acres'),
                            value: (value['totalAcresCovered'] as num)
                                .toStringAsFixed(1),
                            color: Colors.purple,
                            icon: Icons.crop_free,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
                  AsyncError(:final error) => Text('Error: $error'),
                  _ => const Center(child: CircularProgressIndicator()),
                },

                AppSpacing.verticalXl,
                _SectionTitle(title: context.tr('Active Mission')),
                AppSpacing.verticalMd,
                switch (activeJobsAsync) {
                  AsyncData(:final value) =>
                    value.isEmpty
                        ? Text(context.tr('No active mission.'))
                        : Column(
                            children: value
                                .map(
                                  (job) => PilotJobCard(
                                    job: job,
                                    onTap: () => context.push(
                                      '/pilot/job-details',
                                      extra: job,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  AsyncError(:final error) => Text('Error: $error'),
                  _ => const LinearProgressIndicator(),
                },

                AppSpacing.verticalXl,
                _SectionTitle(title: context.tr('Cash Collection')),
                AppSpacing.verticalMd,
                _buildCashCollectionSection(context, ref),

                AppSpacing.verticalXl,
                _SectionTitle(title: context.tr('Overall Pilot Stats')),
                AppSpacing.verticalMd,
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: context.tr('Total Flight Hours'),
                        value: (user?.totalFlightHours ?? 0.0).toStringAsFixed(
                          1,
                        ),
                        icon: Icons.timer_outlined,
                      ),
                      const VerticalDivider(),
                      _StatItem(
                        label: context.tr('Total Missions'),
                        value: (user?.completedMissions ?? 0).toString(),
                        icon: Icons.history,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCollectionSection(BuildContext context, WidgetRef ref) {
    final cashJobsAsync = ref.watch(pilotCashCollectionProvider);

    return switch (cashJobsAsync) {
      AsyncData(:final value) =>
        value.isEmpty
            ? Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Text(context.tr('No cash pending deposit.')),
            )
            : Column(
              children: value
                  .map(
                    (job) => _CashCollectionCard(job: job),
                  )
                  .toList(),
            ),
      AsyncError(:final error) => Text('Error: $error'),
      _ => const LinearProgressIndicator(),
    };
  }
}

class _CashCollectionCard extends ConsumerWidget {
  final BookingModel job;
  const _CashCollectionCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.bookingId, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '₹${job.payableAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${context.tr('Farmer: ')}${job.farmerName ?? 'N/A'}', style: AppTextStyles.bodySmall),
          if (job.cashCollectedAt != null)
            Text('${context.tr('Collected')}: ${DateFormat('dd MMM, hh:mm a').format(job.cashCollectedAt!)}', style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmDeposit(context, ref),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(context.tr('Mark as Deposited')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeposit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Mark as Deposited',
        content: 'Confirm that you have deposited ₹${job.payableAmount?.toStringAsFixed(2)} to the office.',
        confirmLabel: 'Confirm',
        onConfirm: () {
          ref.read(pilotJobsViewModelProvider.notifier).markCashDeposited(job.docId!);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: title,
      titleStyle: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
