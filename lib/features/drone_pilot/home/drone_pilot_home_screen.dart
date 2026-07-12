import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import 'drone_pilot_home_data.dart';
import 'widgets/pilot_assignment_card.dart';
import 'widgets/pilot_drone_card.dart';
import 'widgets/pilot_home_header.dart';
import 'widgets/pilot_overview_card.dart';
import 'widgets/pilot_progress_card.dart';
import 'widgets/pilot_status_card.dart';
import 'widgets/pilot_upcoming_job_card.dart';

class DronePilotHomeScreen extends StatefulWidget {
  const DronePilotHomeScreen({super.key});

  @override
  State<DronePilotHomeScreen> createState() => _DronePilotHomeScreenState();
}

class _DronePilotHomeScreenState extends State<DronePilotHomeScreen> {
  bool _isAvailable = true;

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PilotHomeHeader(),
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
                      isAvailable: _isAvailable,
                      onChanged: (value) =>
                          setState(() => _isAvailable = value),
                    ),
                    AppSpacing.verticalXl,
                    _SectionTitle(title: "Today's Overview"),
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
  childAspectRatio: useSingleColumn ? 3.2 : 0.85,
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
                    _SectionTitle(title: 'Current Assignment'),
                    AppSpacing.verticalMd,
                    PilotAssignmentCard(
                      assignment: currentPilotAssignment,
                      onNavigate: () => _showComingSoon('Navigation'),
                      onViewDetails: () => _showComingSoon('Job details'),
                    ),
                    AppSpacing.verticalXl,
                    _SectionTitle(title: 'Job Progress'),
                    AppSpacing.verticalMd,
                    PilotProgressCard(
                      stages: pilotProgressStages,
                      activeValue: currentPilotAssignment.statusValue,
                    ),
                    AppSpacing.verticalXl,
                    _SectionTitle(title: 'Assigned Drone'),
                    AppSpacing.verticalMd,
                    const PilotDroneCard(),
                    AppSpacing.verticalXl,
                    _SectionTitle(title: 'Upcoming Jobs'),
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
        ),
      ),
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
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) {
                return;
              }
              const labels = ['Home', 'Jobs', 'Notifications', 'Profile'];
              _showComingSoon(labels[index]);
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
