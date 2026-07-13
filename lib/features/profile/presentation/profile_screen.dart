import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../auth/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.name?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ],
            ),
            AppSpacing.verticalLg,
            Text(
              user?.name ?? 'User Name',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? user?.phoneNumber ?? '',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.name.toUpperCase() ?? '',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            AppSpacing.verticalXxl,
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {},
            ),
            if (user?.role == UserRole.farmer) ...[
              _ProfileMenuItem(
                icon: Icons.landscape_outlined,
                title: 'My Farms',
                onTap: () {},
              ),
            ],
            _ProfileMenuItem(
              icon: Icons.assignment_outlined,
              title: user?.role == UserRole.farmer ? 'Booking History' : 'Job History',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            AppSpacing.verticalXl,
            PrimaryButton(
              text: 'Logout',
              onPressed: () {
                ref.read(authViewModelProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
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
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
