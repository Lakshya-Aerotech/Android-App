import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/logout_confirmation.dart';

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

class PilotsPlaceholder extends StatelessWidget {
  const PilotsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Pilot Management');
}

class OperationsPlaceholder extends StatelessWidget {
  const OperationsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Operations Management');
}

class BookingsPlaceholder extends StatelessWidget {
  const BookingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Booking Management');
}

class DronesPlaceholder extends StatelessWidget {
  const DronesPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Drone Management');
}

class ReportsPlaceholder extends StatelessWidget {
  const ReportsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Reports & Analytics');
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Admin Settings');
}

class AdminProfilePlaceholder extends ConsumerWidget {
  const AdminProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Admin Profile'))),
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
              user?.name ?? context.tr('Admin'),
              style: AppTextStyles.titleLarge,
            ),
            Text(
              user?.email ?? 'admin@lakshya.com',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => showLogoutConfirmation(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textInverted,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                textStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(context.tr('Logout')),
            ),
          ],
        ),
      ),
    );
  }
}
