import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../../booking/models/booking_model.dart';
import '../../viewmodels/pilot_jobs_viewmodel.dart';
import '../../widgets/pilot_job_card.dart';

class PilotAssignmentsScreen extends ConsumerStatefulWidget {
  const PilotAssignmentsScreen({super.key});

  @override
  ConsumerState<PilotAssignmentsScreen> createState() =>
      _PilotAssignmentsScreenState();
}

class _OpsAssignmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OpsAssignmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PilotAssignmentsScreenState
    extends ConsumerState<PilotAssignmentsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final assignedJobsAsync = ref.watch(assignedJobsProvider);
    final inProgressJobsAsync = ref.watch(inProgressJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: context.tr('Pilot'),
              subtitle: 'Manage your job assignments.',
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('My Jobs'),
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalMd,

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _OpsAssignmentTab(
                          label: context.tr('Assigned'),
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        _OpsAssignmentTab(
                          label: context.tr('In Progress'),
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.verticalLg,

                  _buildList(assignedJobsAsync, inProgressJobsAsync),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<BookingModel>> assigned,
    AsyncValue<List<BookingModel>> inProgress,
  ) {
    final asyncValue = _selectedTabIndex == 0 ? assigned : inProgress;

    return switch (asyncValue) {
      AsyncData(:final value) =>
        value.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  title: context.tr('No jobs found'),
                  message: context.tr('Check back later for new assignments.'),
                  icon: Icons.assignment_outlined,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return PilotJobCard(
                    job: value[index],
                    onTap: () =>
                        context.push('/pilot/job-details', extra: value[index]),
                  );
                },
              ),
      AsyncError(:final error) => Center(
        child: Text('Error loading jobs: $error'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
