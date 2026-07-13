import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/pilot_dashboard_data.dart';
import '../widgets/pilot_assignment_card.dart';
import '../widgets/pilot_drone_card.dart';
import '../widgets/pilot_home_header.dart';
import '../widgets/pilot_overview_card.dart';
import '../widgets/pilot_progress_card.dart';
import '../widgets/pilot_status_card.dart';
import '../widgets/pilot_upcoming_job_card.dart';
import '../../profile/presentation/profile_screen.dart';

class PilotDashboard extends StatefulWidget {
  const PilotDashboard({super.key});

  @override
  State<PilotDashboard> createState() => _PilotDashboardState();
}

class _PilotDashboardState extends State<PilotDashboard> {
  int _currentIndex = 0;
  bool _isAvailable = true;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _PilotHomeContent(
        isAvailable: _isAvailable,
        onAvailabilityChanged: (v) => setState(() => _isAvailable = v),
      ),
      const Center(child: Text('Jobs coming soon')),
      const Center(child: Text('Notifications coming soon')),
      const ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _screens[0] = _PilotHomeContent(
      isAvailable: _isAvailable,
      onAvailabilityChanged: (v) => setState(() => _isAvailable = v),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: _screens[_currentIndex],
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
                icon: Icon(Icons.notifications_none),
                activeIcon: Icon(Icons.notifications),
                label: 'Notifications',
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useSingleColumn = constraints.maxWidth < 360;
                    return GridView.builder(
                      itemCount: pilotOverviewMetrics.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: useSingleColumn ? 1 : 3,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: useSingleColumn ? 3.2 : 0.55,
                      ),
                      itemBuilder: (context, index) {
                        return PilotOverviewCard(
                          metric: pilotOverviewMetrics[index],
                        );
                      },
                    );
                  },
                ),
                AppSpacing.verticalXl,
                const _SectionTitle(title: 'Current Assignment'),
                AppSpacing.verticalMd,
                PilotAssignmentCard(
                  assignment: currentPilotAssignment,
                  onNavigate: () => _showComingSoon(context, 'Navigation'),
                  onViewDetails: () => _showComingSoon(context, 'Job details'),
                ),
                AppSpacing.verticalXl,
                const _SectionTitle(title: 'Job Progress'),
                AppSpacing.verticalMd,
                PilotProgressCard(
                  stages: pilotProgressStages,
                  activeValue: currentPilotAssignment.statusValue,
                ),
                AppSpacing.verticalXl,
                const _SectionTitle(title: 'Assigned Drone'),
                AppSpacing.verticalMd,
                const PilotDroneCard(),
                AppSpacing.verticalXl,
                const _SectionTitle(title: 'Upcoming Jobs'),
                AppSpacing.verticalMd,
                for (final job in pilotUpcomingJobs) ...[
                  PilotUpcomingJobCard(job: job),
                  AppSpacing.verticalMd,
                ],
              ],
            ),
          ),
        ],
      ),
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
