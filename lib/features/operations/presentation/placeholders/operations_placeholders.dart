import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakshya_aerotech/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:lakshya_aerotech/core/localization/app_localizations.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/logout_confirmation.dart';

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
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.primary,
              ),
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

class OpsAssignmentsPlaceholder extends StatelessWidget {
  const OpsAssignmentsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Pilot & Drone Assignment');
}

class OpsTrackJobsPlaceholder extends StatelessWidget {
  const OpsTrackJobsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Job Tracking');
}

class OperationsProfilePlaceholder extends ConsumerWidget {
  const OperationsProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Operations Profile'))),
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
            Text(
              user?.name ?? context.tr('Operations Member'),
              style: AppTextStyles.titleLarge,
            ),
            Text(
              user?.email ?? 'ops@lakshya.com',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => showLogoutConfirmation(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('Logout')),
            ),
          ],
        ),
      ),
    );
  }
}
