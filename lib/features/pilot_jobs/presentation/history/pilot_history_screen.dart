import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../viewmodels/pilot_jobs_viewmodel.dart';
import '../../widgets/pilot_job_card.dart';

class PilotHistoryScreen extends ConsumerStatefulWidget {
  const PilotHistoryScreen({super.key});

  @override
  ConsumerState<PilotHistoryScreen> createState() => _PilotHistoryScreenState();
}

class _PilotHistoryScreenState extends ConsumerState<PilotHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(pilotJobHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: 'Pilot',
              subtitle: 'Job completion history.',
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalMd,

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged:
                          (value) =>
                              setState(() => _searchQuery = value.toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search by Farmer, Farm, ID...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  AppSpacing.verticalLg,

                  switch (historyAsync) {
                    AsyncData(:final value) =>
                      _buildHistoryList(value),
                    AsyncError(:final error) => Center(child: Text('Error: $error')),
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

  Widget _buildHistoryList(List<dynamic> jobs) {
    final filtered =
        jobs.where((j) {
          return j.bookingId.toLowerCase().contains(_searchQuery) ||
              (j.farmerName?.toLowerCase() ?? '').contains(_searchQuery) ||
              j.farmName.toLowerCase().contains(_searchQuery) ||
              j.serviceType.toLowerCase().contains(_searchQuery);
        }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: EmptyState(
          title: 'No completed jobs',
          message: 'Your history will appear here after missions.',
          icon: Icons.history_outlined,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return PilotJobCard(
          job: filtered[index],
          onTap: () => context.push('/pilot/job-details', extra: filtered[index]),
        );
      },
    );
  }
}
