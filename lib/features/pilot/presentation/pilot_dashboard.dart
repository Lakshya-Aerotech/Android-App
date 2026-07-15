import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../widgets/pilot_home_header.dart';
import '../widgets/pilot_status_card.dart';
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
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _PilotHomeContent(
        isAvailable: _isAvailable,
        onAvailabilityChanged: (v) => setState(() => _isAvailable = v),
      ),
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PilotHomeContent extends ConsumerWidget {
  final bool isAvailable;
  final ValueChanged<bool> onAvailabilityChanged;

  const _PilotHomeContent({
    required this.isAvailable,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final statsAsync = ref.watch(pilotDashboardStatsProvider);
    final activeJobsAsync = ref.watch(inProgressJobsProvider);
    final assignedJobsAsync = ref.watch(assignedJobsProvider);

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
                PilotStatusCard(
                  isAvailable: isAvailable,
                  onChanged: onAvailabilityChanged,
                ),
                AppSpacing.verticalXl,
                const _SectionTitle(title: "Today's Overview"),
                AppSpacing.verticalMd,
                switch (statsAsync) {
                  AsyncData(:final value) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: 'Assigned',
                        value: '${value['assigned'] ?? 0}',
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Accepted',
                        value: '${value['accepted'] ?? 0}',
                        color: Colors.purple,
                      ),
                      _StatCard(
                        title: 'In Progress',
                        value: '${value['inProgress'] ?? 0}',
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Completed',
                        value: '${value['completedToday'] ?? 0}',
                        color: Colors.green,
                      ),
                    ],
                  ),
                  AsyncError(:final error) => Text('Error: $error'),
                  _ => const Center(child: CircularProgressIndicator()),
                },

                AppSpacing.verticalXl,
                const _SectionTitle(title: 'Active Mission'),
                AppSpacing.verticalMd,
                switch (activeJobsAsync) {
                  AsyncData(:final value) => value.isEmpty
                      ? const Text('No active mission.')
                      : Column(
                        children: value.map((job) => PilotJobCard(
                          job: job,
                          onTap: () => context.push('/pilot/job-details', extra: job),
                        )).toList(),
                      ),
                  AsyncError(:final error) => Text('Error: $error'),
                  _ => const LinearProgressIndicator(),
                },

                AppSpacing.verticalXl,
                const _SectionTitle(title: 'New Assignments'),
                AppSpacing.verticalMd,
                switch (assignedJobsAsync) {
                  AsyncData(:final value) => value.isEmpty
                      ? const Text('No new assignments.')
                      : Column(
                        children:
                            value
                                .take(3)
                                .map(
                                  (job) => PilotJobCard(
                                    job: job,
                                    onTap:
                                        () => context.push(
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
                const _SectionTitle(title: 'Flight Stats'),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Today Hours',
                        value: '0.0',
                        icon: Icons.timer_outlined,
                      ),
                      VerticalDivider(),
                      _StatItem(
                        label: 'Total Hours',
                        value: '12.4',
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
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
