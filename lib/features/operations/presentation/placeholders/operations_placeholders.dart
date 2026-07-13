import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ModulePlaceholder extends StatelessWidget {
  final String title;
  const ModulePlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'This module is under development.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class OpsBookingsPlaceholder extends StatelessWidget {
  const OpsBookingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ModulePlaceholder(title: 'Booking Management');
}

class OpsAssignmentsPlaceholder extends StatelessWidget {
  const OpsAssignmentsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ModulePlaceholder(title: 'Pilot & Drone Assignment');
}

class OpsTrackJobsPlaceholder extends StatelessWidget {
  const OpsTrackJobsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const ModulePlaceholder(title: 'Job Tracking');
}

class OperationsProfilePlaceholder extends ConsumerWidget {
  const OperationsProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Operations Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(user?.name ?? 'Operations Member', style: AppTextStyles.titleLarge),
            Text(user?.email ?? 'ops@lakshya.com', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

