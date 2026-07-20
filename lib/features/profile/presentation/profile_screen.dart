import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../auth/models/user_model.dart';
import '../../farm/viewmodels/farm_viewmodel.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../pilot_jobs/viewmodels/pilot_jobs_viewmodel.dart';
import '../../../shared/enums/booking_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_viewmodel.dart';
import '../../../core/widgets/logout_confirmation.dart';
import '../../../core/widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Profile')),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutConfirmation(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalLg,
                  Text(
                    user.name ?? context.tr('User Name'),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email ?? user.phoneNumber ?? '',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.name.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.verticalXxl,
            _buildRoleSpecificSection(context, ref, user),

            AppSpacing.verticalXxl,
            Text(
              context.tr('Account Information'),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoTile(
              label: context.tr('Phone'),
              value: user.phoneNumber ?? context.tr('N/A'),
            ),
            _InfoTile(
              label: context.tr('Email'),
              value: user.email ?? context.tr('N/A'),
            ),
            if (user.village != null)
              _InfoTile(label: context.tr('Village'), value: user.village!),
            if (user.district != null)
              _InfoTile(label: context.tr('District'), value: user.district!),
            _InfoTile(
              label: context.tr('Member Since'),
              value: DateFormat('dd MMM yyyy').format(user.createdAt),
            ),

            AppSpacing.verticalXxl,
            Text(
              context.tr('Settings'),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: context.tr('Edit Profile'),
              onTap: () => context.push('/edit-profile'),
            ),
            _LanguageMenuItem(),
            if (user.email != null)
              _ProfileMenuItem(
                icon: Icons.lock_outline,
                title: context.tr('Change Password'),
                onTap: () {
                  ref
                      .read(authViewModelProvider.notifier)
                      .sendPasswordReset(user.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('Password reset link sent to your email.'),
                      ),
                    ),
                  );
                },
              ),
            _ProfileMenuItem(
              icon: Icons.info_outline,
              title: context.tr('App Information'),
              onTap: () {},
            ),

            AppSpacing.verticalXl,
            PrimaryButton(
              text: context.tr('Logout'),
              onPressed: () => showLogoutConfirmation(context, ref),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSection(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    switch (user.role) {
      case UserRole.farmer:
        return _FarmerStatsSection();
      case UserRole.pilot:
        return _PilotStatsSection(user: user);
operations:
        return _OperationsStatsSection();
      case UserRole.admin:
        return _AdminStatsSection(user: user);
    }
  }
}

class _FarmerStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmsStreamProvider);
    final bookings = ref.watch(farmerBookingsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Farm Activity'),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.tr('Total Farms'),
                value: farms.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: context.tr('Total Acres'),
                value: farms.when(
                  data: (l) =>
                      l.fold(0.0, (s, f) => s + f.area).toStringAsFixed(1),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.tr('Bookings'),
                value: bookings.when(
                  data: (l) => l.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: context.tr('Completed'),
                value: bookings.when(
                  data: (l) => l
                      .where(
                        (b) =>
                            b.status == BookingStatus.completed ||
                            b.status == BookingStatus.farmerConfirmed ||
                            b.status == BookingStatus.closed,
                      )
                      .length
                      .toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PilotStatsSection extends ConsumerWidget {
  final UserModel user;
  const _PilotStatsSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avgRating = ref.watch(pilotAverageRatingProvider);
    final activeJobs = ref.watch(inProgressJobsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Execution Stats'),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.tr('Missions'),
                value: user.completedMissions.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: context.tr('Total Acres'),
                value: user.totalAcresCovered.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.tr('Flight Hours'),
                value: user.totalFlightHours.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: context.tr('Avg Rating'),
                value: avgRating.when(
                  data: (d) => d.toStringAsFixed(1),
                  loading: () => '...',
                  error: (_, __) => 'N/A',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('Assignment'),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        activeJobs.when(
          data: (jobs) {
            final droneName = jobs.isNotEmpty
                ? jobs.first.assignedDroneName
                : 'No active drone';
            return _InfoTile(
              label: context.tr('Current Drone'),
              value: droneName ?? context.tr('N/A'),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => _InfoTile(
            label: context.tr('Current Drone'),
            value: 'Error loading',
          ),
        ),
      ],
    );
  }
}

class _OperationsStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Operations'),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: context.tr('Bookings Handled'),
                value: '124', // Placeholder
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: context.tr('Assigned Region'),
                value: user?.district ?? 'All',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminStatsSection extends StatelessWidget {
  final UserModel user;
  const _AdminStatsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Admin Details'),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(
          label: context.tr('Employee ID'),
          value: user.docId?.substring(0, 8).toUpperCase() ?? context.tr('N/A'),
        ),
        _InfoTile(label: context.tr('Admin Level'), value: 'Super Admin'),
        _InfoTile(
          label: context.tr('Created Date'),
          value: DateFormat('dd MMM yyyy').format(user.createdAt),
        ),
      ],
    );
  }
}

class _LanguageMenuItem extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocale =
        ref.watch(localeViewModelProvider) ?? Localizations.localeOf(context);
    final selectedLanguage = selectedLocale.languageCode == 'te'
        ? context.tr('Telugu')
        : context.tr('English');

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.language, color: AppColors.primary, size: 20),
      ),
      title: Text(context.tr('Language'), style: AppTextStyles.bodyLarge),
      subtitle: Text(selectedLanguage, style: AppTextStyles.bodySmall),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLocale.languageCode == 'te' ? 'te' : 'en',
          items: [
            DropdownMenuItem(value: 'en', child: Text(context.tr('English'))),
            DropdownMenuItem(value: 'te', child: Text(context.tr('Telugu'))),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(localeViewModelProvider.notifier).setLocale(Locale(value));
          },
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

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
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
